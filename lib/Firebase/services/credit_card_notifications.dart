/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/account.dart';
import '../models/notification.dart';
import '../main.dart';
import 'notification_service.dart';

Future<void> showCreditCardNotification(String cardName, String tipo) async {
  await flutterLocalNotificationsPlugin.show(
    0,
    'Recordatorio de tarjeta de crédito',
    'El día de hoy es el último día de $tipo de tu tarjeta de crédito $cardName',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'main_channel',
        'Notificaciones',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}

void checkCreditCardNotifications(List<Account> accounts) {
  final today = DateTime.now().day;
  for (final card in accounts.where((a) => a.isCreditCard)) {
    if (card.cutOffDay == today) {
      showCreditCardNotification(card.name, 'corte');
    }
    if (card.paymentDueDay == today) {
      showCreditCardNotification(card.name, 'pago');
    }
  }
}

/// Crea notificaciones de corte de tarjeta de crédito en Firestore para los próximos 30 días.
Future<void> generateCreditCardCutoffNotifications(List<Account> accounts) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // print('[CREDIT_CARD_NOTIF] Usuario no autenticado, no se generan notificaciones');
    return;
  }
  final notificationService = NotificationService();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final card in accounts.where((a) => a.isCreditCard && a.cutOffDay != null)) {
    // Calcular la próxima fecha de corte
    DateTime cutoffDate = DateTime(today.year, today.month, card.cutOffDay!);
    if (cutoffDate.isBefore(today)) {
      // Si ya pasó este mes, usar el mes siguiente
      cutoffDate = DateTime(today.year, today.month + 1, card.cutOffDay!);
    }
    // Evitar crear notificaciones para fechas pasadas
    if (cutoffDate.isBefore(today)) {
      // print('[CREDIT_CARD_NOTIF] Fecha de corte pasada para tarjeta ${card.name}, se omite');
      continue;
    }

    // Buscar si ya existe una notificación para este usuario, tarjeta y fecha
    final query = await FirebaseFirestore.instance.collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .where('type', isEqualTo: 'credit_card_cutoff')
      .where('metadata.cardId', isEqualTo: card.id)
      .where('date', isEqualTo: Timestamp.fromDate(cutoffDate))
      .limit(1)
      .get();
    if (query.docs.isNotEmpty) {
      // print('[CREDIT_CARD_NOTIF] Ya existe notificación para ${card.name} en $cutoffDate, no se duplica');
      continue;
    }

    // Crear la notificación
    final notification = AppNotification(
      userId: user.uid,
      title: 'Fecha de corte de tarjeta',
      description: 'El ${cutoffDate.day}/${cutoffDate.month} es la fecha de corte de tu tarjeta de crédito ${card.name}',
      date: cutoffDate,
      type: 'credit_card_cutoff',
      category: 'future',
      metadata: {
        'cardId': card.id,
        'cardName': card.name,
        'cutOffDay': card.cutOffDay,
      },
    );
    // print('[CREDIT_CARD_NOTIF] Creando notificación para ${card.name} en $cutoffDate');
    await notificationService.createNotification(notification);
  }
  // print('[CREDIT_CARD_NOTIF] Proceso de generación de notificaciones de corte finalizado');
}

/// Crea notificaciones de fecha de pago de tarjeta de crédito en Firestore para los próximos 30 días.
Future<void> generateCreditCardPaymentDueNotifications(List<Account> accounts) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // print('[CREDIT_CARD_PAYMENT_NOTIF] Usuario no autenticado, no se generan notificaciones');
    return;
  }
  final notificationService = NotificationService();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final card in accounts.where((a) => a.isCreditCard && a.paymentDueDay != null)) {
    // Calcular la próxima fecha de pago
    DateTime paymentDueDate = DateTime(today.year, today.month, card.paymentDueDay!);
    if (paymentDueDate.isBefore(today)) {
      // Si ya pasó este mes, usar el mes siguiente
      paymentDueDate = DateTime(today.year, today.month + 1, card.paymentDueDay!);
    }
    // Evitar crear notificaciones para fechas pasadas
    if (paymentDueDate.isBefore(today)) {
      // print('[CREDIT_CARD_PAYMENT_NOTIF] Fecha de pago pasada para tarjeta ${card.name}, se omite');
      continue;
    }

    // Buscar si ya existe una notificación para este usuario, tarjeta y fecha
    final query = await FirebaseFirestore.instance.collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .where('type', isEqualTo: 'credit_card_payment_due')
      .where('metadata.cardId', isEqualTo: card.id)
      .where('date', isEqualTo: Timestamp.fromDate(paymentDueDate))
      .limit(1)
      .get();
    if (query.docs.isNotEmpty) {
      // print('[CREDIT_CARD_PAYMENT_NOTIF] Ya existe notificación de pago para ${card.name} en $paymentDueDate, no se duplica');
      continue;
    }

    // Crear la notificación
    final notification = AppNotification(
      userId: user.uid,
      title: 'Fecha de pago de tarjeta',
      description: 'El ${paymentDueDate.day}/${paymentDueDate.month} es la fecha límite de pago de tu tarjeta de crédito ${card.name}',
      date: paymentDueDate,
      type: 'credit_card_payment_due',
      category: 'future',
      metadata: {
        'cardId': card.id,
        'cardName': card.name,
        'paymentDueDay': card.paymentDueDay,
      },
    );
    // print('[CREDIT_CARD_PAYMENT_NOTIF] Creando notificación de pago para ${card.name} en $paymentDueDate');
    await notificationService.createNotification(notification);
  }
  // print('[CREDIT_CARD_PAYMENT_NOTIF] Proceso de generación de notificaciones de pago finalizado');
}
*/