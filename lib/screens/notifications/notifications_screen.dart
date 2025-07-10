// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/notification.dart';
import 'package:mis_finanza/services/notification_service.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';
import 'package:mis_finanza/services/credit_card_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_finanza/services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _generateCreditCardNotificationsOnOpen();
    _generateDebtPaymentUpcomingNotificationsOnOpen();
    _generateRecurringPaymentNotificationsOnOpen();
  }

  void _generateCreditCardNotificationsOnOpen() async {
    final firestoreService = FirestoreService();
    firestoreService.getAccounts().first.then((accounts) {
      generateCreditCardCutoffNotifications(accounts);
      generateCreditCardPaymentDueNotifications(accounts);
    });
  }

  void _generateDebtPaymentUpcomingNotificationsOnOpen() async {
    //final firestoreService = FirestoreService();
    DebtService.getDebts().first.then((debts) async {
      final notificationService = NotificationService();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final debt in debts) {
        if (debt.paymentDay != null && debt.status == 'active') {
          // Calcular la próxima fecha de pago
          DateTime nextPaymentDate = DateTime(today.year, today.month, debt.paymentDay!);
          if (nextPaymentDate.isBefore(today)) {
            // Si ya pasó este mes, usar el mes siguiente
            nextPaymentDate = DateTime(today.year, today.month + 1, debt.paymentDay!);
          }
          // Evitar crear notificaciones para fechas pasadas
          if (nextPaymentDate.isBefore(today)) {
            continue;
          }
          // Buscar si ya existe una notificación para este usuario, deuda y fecha
          final query = await FirebaseFirestore.instance.collection('notifications')
            .where('userId', isEqualTo: debt.userId)
            .where('type', isEqualTo: 'debt_payment_upcoming')
            .where('metadata.debtId', isEqualTo: debt.id)
            .where('date', isEqualTo: Timestamp.fromDate(nextPaymentDate))
            .limit(1)
            .get();
          if (query.docs.isNotEmpty) {
            continue;
          }
          // Crear la notificación
          await notificationService.createDebtPaymentUpcomingNotification(
            debtName: debt.description,
            dueDate: nextPaymentDate,
            debtId: debt.id ?? '',
          );
        }
      }
    });
  }

  void _generateRecurringPaymentNotificationsOnOpen() async {
    await _notificationService.generateRecurringPaymentNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper para formatear fecha relativa
  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 0) {
      return 'En ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inDays < 0) {
      final daysPast = -difference.inDays;
      return 'Hace $daysPast día${daysPast > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inHours < 0) {
      final hoursPast = -difference.inHours;
      return 'Hace $hoursPast hora${hoursPast > 1 ? 's' : ''}';
    } else {
      return 'Hoy';
    }
  }

  // Helper para obtener el ícono según el tipo de notificación
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'debt_payment':
        return Icons.credit_card;
      case 'budget_exceeded':
        return Icons.warning;
      case 'investment_dividend':
        return Icons.trending_up;
      case 'investment_maturity':
        return Icons.event;
      case 'budget_review':
        return Icons.assessment;
      case 'payment_reminder':
        return Icons.schedule;
      case 'credit_card_cutoff':
        return Icons.vertical_align_top; // Ícono para corte
      case 'credit_card_payment_due':
        return Icons.attach_money; // Ícono para pago
      case 'recurring_payment_upcoming':
        return Icons.repeat; // Ícono para pago recurrente próximo
      default:
        return Icons.notifications;
    }
  }

  // Helper para obtener el color según el tipo de notificación (adaptativo para alto contraste)
  Color _getNotificationColor(String type, BuildContext context) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isHighContrast) {
      // En alto contraste, usar colores más contrastantes
      return isDarkMode ? Colors.white : Colors.black;
    }
    
    // Colores normales adaptados al tema
    switch (type) {
      case 'debt_payment':
        return isDarkMode ? Colors.red.shade300 : Colors.red.shade600;
      case 'budget_exceeded':
        return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade600;
      case 'investment_dividend':
        return isDarkMode ? Colors.green.shade300 : Colors.green.shade600;
      case 'investment_maturity':
        return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade600;
      case 'budget_review':
        return isDarkMode ? Colors.purple.shade300 : Colors.purple.shade600;
      case 'payment_reminder':
        return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600;
      case 'credit_card_cutoff':
        return isDarkMode ? Colors.blueAccent.shade200 : Colors.blueAccent.shade700;
      case 'credit_card_payment_due':
        return isDarkMode ? Colors.green.shade300 : Colors.green.shade600;
      case 'recurring_payment_upcoming':
        return isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  // Helper para obtener color de texto adaptativo
  Color _getAdaptiveTextColor(BuildContext context, {bool isSecondary = false}) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isHighContrast) {
      return isDarkMode ? Colors.white : Colors.black;
    }
    
    if (isSecondary) {
      return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
    
    return Theme.of(context).textTheme.bodyMedium?.color ?? 
           (isDarkMode ? Colors.white : Colors.black);
  }

  // Helper para obtener color de badge adaptativo
  Color _getBadgeTextColor(BuildContext context, Color backgroundColor) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isHighContrast) {
      // En alto contraste, usar el color opuesto al fondo
      return isDarkMode ? Colors.black : Colors.white;
    }
    
    return Colors.white; // Color por defecto
  }

  // Helper para obtener color de texto del AppBar adaptativo
  Color _getAppBarTextColor(BuildContext context) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isHighContrast) {
      // En alto contraste con modo claro, el AppBar es oscuro, así que el texto debe ser blanco
      // En alto contraste con modo oscuro, el AppBar es claro, así que el texto debe ser negro
      return isDarkMode ? Colors.black : Colors.white;
    }
    
    // En modo normal, usar el color del tema
    return Theme.of(context).appBarTheme.foregroundColor ?? 
           (isDarkMode ? Colors.white : Colors.black);
  }

  // Widget para construir una notificación individual
  Widget _buildNotificationItem({
    required AppNotification notification,
    VoidCallback? onTap,
  }) {
    final icon = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationColor(notification.type, context);
    String? badge;
    Color? badgeColor;
    if (notification.type == 'credit_card_cutoff') {
      badge = 'CORTE';
      badgeColor = _getNotificationColor(notification.type, context);
    } else if (notification.type == 'credit_card_payment_due') {
      badge = 'PAGO';
      badgeColor = _getNotificationColor(notification.type, context);
    }
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Theme.of(context).cardColor,
      child: ListTile(
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            if (badge != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: _getBadgeTextColor(context, badgeColor!),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: _getAdaptiveTextColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getAdaptiveTextColor(context),
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatRelativeDate(notification.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getAdaptiveTextColor(context, isSecondary: true),
              ),
            ),
          ],
        ),
        trailing: notification.isRead 
          ? null 
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        onTap: onTap,
      ),
    );
  }

  // Widget para notificaciones pasadas
  Widget _buildPastNotifications() {
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: _getAdaptiveTextColor(context, isSecondary: true),
            ),
            SizedBox(height: 16),
            Text(
              'Usuario no autenticado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getAdaptiveTextColor(context, isSecondary: true),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getPastNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 64,
                  color: _getNotificationColor('debt_payment', context),
                ),
                SizedBox(height: 16),
                Text(
                  'Error al cargar notificaciones',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getNotificationColor('debt_payment', context),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getAdaptiveTextColor(context, isSecondary: true),
                  ),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: _getAdaptiveTextColor(context, isSecondary: true),
                ),
                SizedBox(height: 16),
                Text(
                  'No hay notificaciones pasadas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getAdaptiveTextColor(context, isSecondary: true),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationItem(
              notification: notification,
              onTap: () async {
                if (!notification.isRead) {
                  try {
                    await _notificationService.markAsRead(notification.id!);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al marcar como leída: $e'),
                        backgroundColor: _getNotificationColor('debt_payment', context),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  // Widget para notificaciones futuras
  Widget _buildFutureNotifications() {
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: _getAdaptiveTextColor(context, isSecondary: true),
            ),
            SizedBox(height: 16),
            Text(
              'Usuario no autenticado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getAdaptiveTextColor(context, isSecondary: true),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getFutureNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 64,
                  color: _getNotificationColor('debt_payment', context),
                ),
                SizedBox(height: 16),
                Text(
                  'Error al cargar notificaciones',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getNotificationColor('debt_payment', context),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getAdaptiveTextColor(context, isSecondary: true),
                  ),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  size: 64,
                  color: _getAdaptiveTextColor(context, isSecondary: true),
                ),
                SizedBox(height: 16),
                Text(
                  'No hay notificaciones programadas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getAdaptiveTextColor(context, isSecondary: true),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationItem(
              notification: notification,
              onTap: () {
                // Las notificaciones futuras no se marcan como leídas automáticamente
                // pero podríamos navegar a algún detalle si es necesario
                //print('Notificación futura tocada: ${notification.title}');
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _getAppBarTextColor(context),
          ),
        ),
        iconTheme: IconThemeData(
          color: _getAppBarTextColor(context),
        ),
        actions: [
          // Botón para marcar todas como leídas
          TextButton.icon(
            onPressed: () async {
              try {
                await _notificationService.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Todas las notificaciones marcadas como leídas'),
                    backgroundColor: _getNotificationColor('investment_dividend', context),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al marcar notificaciones: $e'),
                    backgroundColor: _getNotificationColor('debt_payment', context),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.done_all,
              color: _getAppBarTextColor(context),
            ),
            label: Text(
              'Marcar todas',
              style: TextStyle(
                color: _getAppBarTextColor(context),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // TabBar para separar pasadas y futuras
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Icon(Icons.history),
                text: 'Pasadas',
              ),
              Tab(
                icon: Icon(Icons.schedule),
                text: 'Futuras',
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: _getAdaptiveTextColor(context, isSecondary: true),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          
          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPastNotifications(),
                _buildFutureNotifications(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
