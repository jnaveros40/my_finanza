// lib/services/push_notification_service.dart

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = flutterLocalNotificationsPlugin;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize push notifications
  static Future<void> initialize() async {
    //print('[PUSH_NOTIFICATIONS] Inicializando servicio de notificaciones push...');
    
    // Request permission for notifications
    await _requestNotificationPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Configure Firebase Messaging
    await _configureFCM();
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    //print('[PUSH_NOTIFICATIONS] Servicio de notificaciones push inicializado correctamente');
  }

  // Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      await _firebaseMessaging.requestPermission();
    }
    
    //print('[PUSH_NOTIFICATIONS] Permisos de notificación solicitados');
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    //print('[PUSH_NOTIFICATIONS] Notificaciones locales inicializadas');
  }

  // Configure Firebase Cloud Messaging
  static Future<void> _configureFCM() async {
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    //print('[PUSH_NOTIFICATIONS] FCM Token: $token');
    
    // Save token to Firestore for the current user
    await _saveTokenToFirestore(token);
    
    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      //print('[PUSH_NOTIFICATIONS] Token actualizado: $newToken');
      await _saveTokenToFirestore(newToken);
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
    
    //print('[PUSH_NOTIFICATIONS] Firebase Cloud Messaging configurado');
  }

  // Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      //print('[PUSH_NOTIFICATIONS] Token guardado en Firestore para usuario: ${user.uid}');
    } catch (e) {
      // Si el documento no existe, lo creamos con set(merge: true)
      if (e is FirebaseException && e.code == 'not-found') {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmTokens': [token],
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          //print('[PUSH_NOTIFICATIONS] Token creado en Firestore para usuario: ${user.uid}');
        } catch (e2) {
          //print('[PUSH_NOTIFICATIONS] Error al crear documento de usuario: $e2');
        }
      } else {
        //print('[PUSH_NOTIFICATIONS] Error al guardar token: $e');
      }
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    //print('[PUSH_NOTIFICATIONS] Mensaje recibido en primer plano: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  // Handle notification when app is opened from terminated/background state
  static Future<void> _handleNotificationOpenedApp(RemoteMessage message) async {
    //print('[PUSH_NOTIFICATIONS] App abierta desde notificación: ${message.notification?.title}');
    
    // Handle navigation based on notification data
    await _handleNotificationNavigation(message);
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    //print('[PUSH_NOTIFICATIONS] Handling a background message: ${message.messageId}');
    
    // Show local notification
    await _showLocalNotification(message);
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'financial_notifications',
      'Notificaciones Financieras',
      channelDescription: 'Notificaciones relacionadas con tu gestión financiera',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title ?? 'JN Finzanza',
      message.notification?.body ?? 'Tienes una nueva notificación',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse notificationResponse) async {
    //print('[PUSH_NOTIFICATIONS] Notificación tocada: ${notificationResponse.payload}');
    
    // Handle navigation based on payload
    // This will be implemented based on your navigation structure
  }

  // Handle notification navigation
  static Future<void> _handleNotificationNavigation(RemoteMessage message) async {
    final notificationType = message.data['type'];
    final navigationData = message.data;
    
    //print('[PUSH_NOTIFICATIONS] Navegando por tipo: $notificationType');
    
    // TODO: Implement navigation based on notification type
    // This will depend on your app's navigation structure
  }

  // Send push notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM tokens
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);
      
      if (fcmTokens.isEmpty) {
        //print('[PUSH_NOTIFICATIONS] No hay tokens FCM para el usuario: $userId');
        return;
      }
      
      // Send notification to each token
      for (final token in fcmTokens) {
        await _sendNotificationToToken(
          token: token,
          title: title,
          body: body,
          data: data,
        );
      }
      
      //print('[PUSH_NOTIFICATIONS] Notificación enviada a ${fcmTokens.length} dispositivo(s)');
    } catch (e) {
      //print('[PUSH_NOTIFICATIONS] Error al enviar notificación: $e');
    }
  }

  // Send notification to specific token
  static Future<void> _sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Note: In production, you would typically use Firebase Functions
    // or your backend server to send push notifications using the FCM server API
    // This is just a placeholder for the client-side logic
    
    //print('[PUSH_NOTIFICATIONS] Preparando envío a token: ${token.substring(0, 20)}...');
    
    // TODO: Implement server-side notification sending
    // For now, we'll create a local notification as a demo
    await _createDemoNotification(title, body);
  }

  // Create a demo notification (for testing purposes)
  static Future<void> _createDemoNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'demo_notifications',
      'Demo Notifications',
      channelDescription: 'Notifications for testing purposes',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Send financial reminder notifications
  static Future<void> sendFinancialReminder({
    required String userId,
    required String reminderType,
    required String message,
    Map<String, String>? additionalData,
  }) async {
    final data = {
      'type': 'financial_reminder',
      'reminderType': reminderType,
      'userId': userId,
      ...?additionalData,
    };
    
    await sendNotificationToUser(
      userId: userId,
      title: 'Recordatorio Financiero',
      body: message,
      data: data,
    );
  }

  // Send budget alert
  static Future<void> sendBudgetAlert({
    required String userId,
    required String budgetName,
    required double percentage,
  }) async {
    final data = {
      'type': 'budget_alert',
      'budgetName': budgetName,
      'percentage': percentage.toString(),
    };
    
    await sendNotificationToUser(
      userId: userId,
      title: 'Alerta de Presupuesto',
      body: 'Has excedido el presupuesto "$budgetName" en un ${percentage.toStringAsFixed(0)}%',
      data: data,
    );
  }

  // Send payment reminder
  static Future<void> sendPaymentReminder({
    required String userId,
    required String paymentName,
    required DateTime dueDate,
  }) async {
    final data = {
      'type': 'payment_reminder',
      'paymentName': paymentName,
      'dueDate': dueDate.toIso8601String(),
    };
    
    await sendNotificationToUser(
      userId: userId,
      title: 'Recordatorio de Pago',
      body: 'El pago de "$paymentName" vence pronto',
      data: data,
    );
  }

  // Clean up old tokens for user
  static Future<void> cleanupOldTokens(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'fcmTokens': FieldValue.delete(),
      });
      //print('[PUSH_NOTIFICATIONS] Tokens antiguos eliminados para usuario: $userId');
    } catch (e) {
      //print('[PUSH_NOTIFICATIONS] Error al limpiar tokens: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      //print('[PUSH_NOTIFICATIONS] Error al obtener token actual: $e');
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      //print('[PUSH_NOTIFICATIONS] Suscrito al tópico: $topic');
    } catch (e) {
      //print('[PUSH_NOTIFICATIONS] Error al suscribirse al tópico: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      //print('[PUSH_NOTIFICATIONS] Desuscrito del tópico: $topic');
    } catch (e) {
      //print('[PUSH_NOTIFICATIONS] Error al desuscribirse del tópico: $e');
    }
  }
}
