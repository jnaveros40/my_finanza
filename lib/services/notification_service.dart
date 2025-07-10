// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el stream de notificaciones del usuario actual
  Stream<List<AppNotification>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // Obtener notificaciones pasadas (fecha anterior a hoy)
  Stream<List<AppNotification>> getPastNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('date', isLessThan: Timestamp.fromDate(today))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // Obtener notificaciones futuras (fecha igual o posterior a hoy)
  Stream<List<AppNotification>> getFutureNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // Crear una nueva notificación
  Future<void> createNotification(AppNotification notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toFirestore());
    } catch (e) {
      ////print('Error al crear notificación: $e');
      throw Exception('Error al crear la notificación: $e');
    }
  }

  // Marcar una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      ////print('Error al marcar notificación como leída: $e');
      throw Exception('Error al marcar la notificación como leída: $e');
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      ////print('Error al marcar todas las notificaciones como leídas: $e');
      throw Exception('Error al marcar todas las notificaciones como leídas: $e');
    }
  }

  // Eliminar una notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      ////print('Error al eliminar notificación: $e');
      throw Exception('Error al eliminar la notificación: $e');
    }
  }

  // Crear notificación de pago de deuda vencido
  Future<void> createDebtPaymentOverdueNotification({
    required String debtName,
    required DateTime dueDate,
    required String debtId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notification = AppNotification(
      userId: user.uid,
      title: 'Pago de deuda vencido',
      description: 'El pago de "$debtName" venció el ${_formatDate(dueDate)}',
      date: dueDate,
      type: 'debt_payment_overdue',
      category: 'past',
      metadata: {
        'debtId': debtId,
        'debtName': debtName,
        'dueDate': dueDate.toIso8601String(),
      },
    );

    await createNotification(notification);
  }

  // Crear notificación de pago de deuda próximo
  Future<void> createDebtPaymentUpcomingNotification({
    required String debtName,
    required DateTime dueDate,
    required String debtId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notification = AppNotification(
      userId: user.uid,
      title: 'Pago de deuda próximo',
      description: 'El pago de "$debtName" vence el ${_formatDate(dueDate)}',
      date: dueDate,
      type: 'debt_payment_upcoming',
      category: 'future',
      metadata: {
        'debtId': debtId,
        'debtName': debtName,
        'dueDate': dueDate.toIso8601String(),
      },
    );

    await createNotification(notification);
  }

  // Crear notificación de presupuesto excedido
  Future<void> createBudgetExceededNotification({
    required String budgetName,
    required double percentage,
    required String budgetId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notification = AppNotification(
      userId: user.uid,
      title: 'Presupuesto excedido',
      description: 'Has excedido el presupuesto de "$budgetName" en un ${percentage.toStringAsFixed(0)}%',
      date: DateTime.now(),
      type: 'budget_exceeded',
      category: 'past',
      metadata: {
        'budgetId': budgetId,
        'budgetName': budgetName,
        'percentage': percentage,
      },
    );

    await createNotification(notification);
  }

  // Crear notificación de dividendo recibido
  Future<void> createDividendReceivedNotification({
    required String investmentName,
    required double amount,
    required String currency,
    required String investmentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notification = AppNotification(
      userId: user.uid,
      title: 'Dividendo recibido',
      description: 'Se recibió dividendo de tu inversión en "$investmentName": $amount $currency',
      date: DateTime.now(),
      type: 'dividend_received',
      category: 'past',
      metadata: {
        'investmentId': investmentId,
        'investmentName': investmentName,
        'amount': amount,
        'currency': currency,
      },
    );

    await createNotification(notification);
  }

  // Crear notificación de pago recurrente próximo
  Future<void> createRecurringPaymentUpcomingNotification({
    required String paymentName,
    required DateTime dueDate,
    required String paymentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      //print('[RECURRING_NOTIF] Usuario no autenticado, no se crea notificación');
      return;
    }
    // Check for duplicate notification
    final query = await _firestore.collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .where('type', isEqualTo: 'recurring_payment_upcoming')
      .where('metadata.recurringPaymentId', isEqualTo: paymentId)
      .where('date', isEqualTo: Timestamp.fromDate(dueDate))
      .limit(1)
      .get();
    if (query.docs.isNotEmpty) {
      //print('[RECURRING_NOTIF] Notificación ya existe para "$paymentName" con fecha $dueDate');
      return;
    }
    //print('[RECURRING_NOTIF] Creando notificación para "$paymentName" con fecha $dueDate');
    final notification = AppNotification(
      userId: user.uid,
      title: 'Pago recurrente próximo',
      description: 'El pago recurrente $paymentName vence el ${_formatDate(dueDate)}',
      date: dueDate,
      type: 'recurring_payment_upcoming',
      category: 'future',
      metadata: {
        'recurringPaymentId': paymentId,
        'recurringPaymentName': paymentName,
        'dueDate': dueDate.toIso8601String(),
      },
    );
    await createNotification(notification);
    //print('[RECURRING_NOTIF] Notificación creada en Firestore para "$paymentName"');
  }

  // Generar notificaciones automáticas para pagos recurrentes próximos
  Future<void> generateRecurringPaymentNotifications() async {
    final user = _auth.currentUser;
    if (user == null) {
      //print('[RECURRING_NOTIF] Usuario no autenticado, no se generan notificaciones');
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    //print('[RECURRING_NOTIF] Buscando pagos recurrentes próximos para el usuario: \\${user.uid}');
    try {
      final recurringPayments = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recurring_payments')
        .where('nextPaymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .get();
      //print('[RECURRING_NOTIF] Encontrados \\${recurringPayments.docs.length} pagos recurrentes próximos');
      for (final doc in recurringPayments.docs) {
        final data = doc.data();
        final nextPaymentDate = (data['nextPaymentDate'] as Timestamp).toDate();
        //print('[RECURRING_NOTIF] Procesando pago recurrente: \\${data['description']} con fecha \\${nextPaymentDate}');
        await createRecurringPaymentUpcomingNotification(
          paymentName: data['description'],
          dueDate: nextPaymentDate,
          paymentId: doc.id,
        );
      }
    } catch (e) {
      //print('[RECURRING_NOTIF][ERROR] Error al buscar o crear notificaciones de pagos recurrentes: \\${e.toString()}');
      //print(st);
    }
  }

  // Helper para formatear fechas
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
