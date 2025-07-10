// lib/services/notification_manager.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account.dart';
//import '../models/debt.dart';
import '../models/movement.dart';
//import '../models/budget.dart';
import 'push_notification_service.dart';
import 'notification_service.dart';
import 'credit_card_notifications.dart';

class NotificationManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  // Initialize notification system for user
  static Future<void> initializeForUser(String userId) async {
    // print('[NOTIFICATION_MANAGER] Inicializando notificaciones para usuario: $userId');
    
    // Subscribe to user-specific notifications
    await PushNotificationService.subscribeToTopic('user_$userId');
    await PushNotificationService.subscribeToTopic('financial_updates');
    
    // Generate initial notifications
    await _generateInitialNotifications(userId);
    
    // print('[NOTIFICATION_MANAGER] Notificaciones inicializadas para usuario: $userId');
  }

  // Generate initial notifications for the user
  static Future<void> _generateInitialNotifications(String userId) async {
    try {
      // Generate credit card notifications
      final accounts = await _getAccountsForUser(userId);
      await generateCreditCardCutoffNotifications(accounts);
      await generateCreditCardPaymentDueNotifications(accounts);
      
      // Generate debt payment notifications
      await _generateDebtNotifications(userId);
      
      // Generate recurring payment notifications
      await _notificationService.generateRecurringPaymentNotifications();
      
      // print('[NOTIFICATION_MANAGER] Notificaciones iniciales generadas');
    } catch (e) {
      // print('[NOTIFICATION_MANAGER] Error generando notificaciones iniciales: $e');
    }
  }

  // Get accounts for user
  static Future<List<Account>> _getAccountsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .get();
      
      return snapshot.docs
          .map((doc) => Account.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print('[NOTIFICATION_MANAGER] Error obteniendo cuentas: $e');
      return [];
    }
  }

  // Generate debt notifications
  static Future<void> _generateDebtNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('debts')
          .where('status', isEqualTo: 'active')
          .get();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (final doc in snapshot.docs) {
        final debtData = doc.data();
        final paymentDay = debtData['paymentDay'] as int?;
        
        if (paymentDay != null) {
          DateTime nextPaymentDate = DateTime(today.year, today.month, paymentDay);
          if (nextPaymentDate.isBefore(today)) {
            nextPaymentDate = DateTime(today.year, today.month + 1, paymentDay);
          }
          
          // Create notification and send push notification
          await _notificationService.createDebtPaymentUpcomingNotification(
            debtName: debtData['description'] ?? 'Deuda',
            dueDate: nextPaymentDate,
            debtId: doc.id,
          );
          
          // Send push notification
          await PushNotificationService.sendPaymentReminder(
            userId: userId,
            paymentName: debtData['description'] ?? 'Deuda',
            dueDate: nextPaymentDate,
          );
        }
      }
    } catch (e) {
      // print('[NOTIFICATION_MANAGER] Error generando notificaciones de deuda: $e');
    }
  }

  // Handle movement creation notifications
  static Future<void> handleMovementCreated(Movement movement) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Check if this movement affects any budgets
      await _checkBudgetImpact(movement);
      
      // Send summary notification if it's a large transaction
      if (movement.amount > 1000) {
        await PushNotificationService.sendNotificationToUser(
          userId: user.uid,
          title: 'Transacción Importante',
          body: 'Se registró un ${movement.type} de \$${movement.amount.toStringAsFixed(2)}',
          data: {
            'type': 'large_transaction',
            'movementId': movement.id ?? '',
            'amount': movement.amount.toString(),
          },
        );
      }
    } catch (e) {
      // print('[NOTIFICATION_MANAGER] Error manejando movimiento creado: $e');
    }
  }

  // Check budget impact
  static Future<void> _checkBudgetImpact(Movement movement) async {
    if (movement.type != 'expense') return;
    
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Get current month's budget for the category
      final now = DateTime.now();
      final budgetQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where('categoryId', isEqualTo: movement.categoryId)
          .where('month', isEqualTo: now.month)
          .where('year', isEqualTo: now.year)
          .limit(1)
          .get();
      
      if (budgetQuery.docs.isEmpty) return;
      
      final budgetDoc = budgetQuery.docs.first;
      final budgetData = budgetDoc.data();
      final budgetAmount = (budgetData['amount'] as num?)?.toDouble() ?? 0.0;
      final spentAmount = (budgetData['spent'] as num?)?.toDouble() ?? 0.0;
      
      final newSpentAmount = spentAmount + movement.amount;
      final percentage = (newSpentAmount / budgetAmount) * 100;
      
      // Send alert if budget is exceeded
      if (percentage > 100) {
        await _notificationService.createBudgetExceededNotification(
          budgetName: budgetData['categoryName'] ?? 'Presupuesto',
          percentage: percentage,
          budgetId: budgetDoc.id,
        );
        
        await PushNotificationService.sendBudgetAlert(
          userId: user.uid,
          budgetName: budgetData['categoryName'] ?? 'Presupuesto',
          percentage: percentage,
        );
      } else if (percentage > 80) {
        // Send warning at 80%
        await PushNotificationService.sendNotificationToUser(
          userId: user.uid,
          title: 'Advertencia de Presupuesto',
          body: 'Has usado el ${percentage.toStringAsFixed(0)}% del presupuesto "${budgetData['categoryName']}"',
          data: {
            'type': 'budget_warning',
            'budgetId': budgetDoc.id,
            'percentage': percentage.toString(),
          },
        );
      }
    } catch (e) {
      // print('[NOTIFICATION_MANAGER] Error verificando impacto en presupuesto: $e');
    }
  }

  // Handle credit card payment due
  static Future<void> handleCreditCardPaymentDue(Account creditCard) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await PushNotificationService.sendNotificationToUser(
        userId: user.uid,
        title: 'Pago de Tarjeta de Crédito',
        body: 'Hoy es la fecha límite de pago para ${creditCard.name}',
        data: {
          'type': 'credit_card_payment_due',
          'cardId': creditCard.id ?? '',
          'cardName': creditCard.name,
        },
      );
    } catch (e) {
      // print('[NOTIFICATION_MANAGER] Error enviando notificación de pago: $e');
    }
  }

  // Handle credit card cutoff
  static Future<void> handleCreditCardCutoff(Account creditCard) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await PushNotificationService.sendNotificationToUser(
        userId: user.uid,
        title: 'Corte de Tarjeta de Crédito',
        body: 'Hoy es la fecha de corte para ${creditCard.name}',
        data: {
          'type': 'credit_card_cutoff',
          'cardId': creditCard.id ?? '',
          'cardName': creditCard.name,
        },
      );
    } catch (e) {
      // print('[NOTIFICATION_MANAGER] Error enviando notificación de corte: $e');
    }
  }

  // Schedule daily check for notifications
  static Future<void> scheduleDailyNotificationCheck() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // print('[NOTIFICATION_MANAGER] Ejecutando verificación diaria de notificaciones');
    
    try {
      // Check for today's due payments
      await _checkTodaysDuePayments(user.uid);
      
      // Check for low balance alerts
      await _checkLowBalanceAlerts(user.uid);
      
      // Check for investment milestones
      await _checkInvestmentMilestones(user.uid);
      
    } catch (e) {
      print('[NOTIFICATION_MANAGER] Error en verificación diaria: $e');
    }
  }

  // Check today's due payments
  static Future<void> _checkTodaysDuePayments(String userId) async {
    final today = DateTime.now().day;
    
    // Check credit cards
    final accounts = await _getAccountsForUser(userId);
    for (final account in accounts) {
      if (account.isCreditCard) {
        if (account.paymentDueDay == today) {
          await handleCreditCardPaymentDue(account);
        }
        if (account.cutOffDay == today) {
          await handleCreditCardCutoff(account);
        }
      }
    }
  }

  // Check low balance alerts
  static Future<void> _checkLowBalanceAlerts(String userId) async {
    try {
      final accounts = await _getAccountsForUser(userId);
      
      for (final account in accounts) {
        if (!account.isCreditCard && account.currentBalance < 1000) {
          await PushNotificationService.sendNotificationToUser(
            userId: userId,
            title: 'Saldo Bajo',
            body: 'Tu cuenta ${account.name} tiene un saldo bajo: \$${account.currentBalance.toStringAsFixed(2)}',
            data: {
              'type': 'low_balance',
              'accountId': account.id ?? '',
              'accountName': account.name,
              'balance': account.currentBalance.toString(),
            },
          );
        }
      }
    } catch (e) {
      print('[NOTIFICATION_MANAGER] Error verificando saldos bajos: $e');
    }
  }

  // Check investment milestones
  static Future<void> _checkInvestmentMilestones(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('investments')
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final currentValue = (data['currentValue'] as num?)?.toDouble() ?? 0.0;
        final initialValue = (data['initialValue'] as num?)?.toDouble() ?? 0.0;
        
        if (initialValue > 0) {
          final gainPercentage = ((currentValue - initialValue) / initialValue) * 100;
          
          // Notify on significant gains/losses
          if (gainPercentage >= 10 || gainPercentage <= -10) {
            await PushNotificationService.sendNotificationToUser(
              userId: userId,
              title: 'Actualización de Inversión',
              body: 'Tu inversión ${data['name']} ${gainPercentage > 0 ? 'ha ganado' : 'ha perdido'} ${gainPercentage.abs().toStringAsFixed(1)}%',
              data: {
                'type': 'investment_milestone',
                'investmentId': doc.id,
                'investmentName': data['name'] ?? '',
                'percentage': gainPercentage.toString(),
              },
            );
          }
        }
      }
    } catch (e) {
      print('[NOTIFICATION_MANAGER] Error verificando inversiones: $e');
    }
  }

  // Clean up notifications for user
  static Future<void> cleanupForUser(String userId) async {
    try {
      // Unsubscribe from topics
      await PushNotificationService.unsubscribeFromTopic('user_$userId');
      
      // Clean up FCM tokens
      await PushNotificationService.cleanupOldTokens(userId);
      
      // print('[NOTIFICATION_MANAGER] Limpieza completada para usuario: $userId');
    } catch (e) {
      print('[NOTIFICATION_MANAGER] Error en limpieza: $e');
    }
  }

  // Send custom notification
  static Future<void> sendCustomNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    try {
      await PushNotificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: message,
        data: {
          'type': type,
          ...?additionalData,
        },
      );
    } catch (e) {
      print('[NOTIFICATION_MANAGER] Error enviando notificación personalizada: $e');
    }
  }
}
