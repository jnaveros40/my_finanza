// lib/models/notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final DateTime date;
  final String type; // 'debt_payment', 'budget_exceeded', 'investment_dividend', etc.
  final String category; // 'past' or 'future'
  final bool isRead;
  final Map<String, dynamic>? metadata; // Datos adicionales específicos del tipo de notificación

  AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.category,
    this.isRead = false,
    this.metadata,
  });

  // Método para crear una instancia desde un documento de Firestore
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      category: data['category'] ?? 'future',
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Método para convertir la instancia a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type,
      'category': category,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Método para copiar la instancia con algunos campos modificados
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? date,
    String? type,
    String? category,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, userId: $userId, title: $title, description: $description, date: $date, type: $type, category: $category, isRead: $isRead, metadata: $metadata)';
  }
}
