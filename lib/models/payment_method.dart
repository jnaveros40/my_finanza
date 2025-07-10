// lib/models/payment_method.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String? id;
  final String userId; // ID del usuario (para métodos personalizados)
  final String name;
  final String type; // Ej: , 'credit_card', 'debit_card'
  final bool isPredefined; // Indica si es un método predefinido del sistema
  final String? details; // Opcional: últimos 4 dígitos, etc.

  PaymentMethod({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.isPredefined = false,
    this.details,
  });

  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    bool? isPredefined,
    String? details,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      isPredefined: isPredefined ?? this.isPredefined,
      details: details ?? this.details,
    );
  }
  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
     Map data = doc.data() as Map? ?? {};
    return PaymentMethod(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? 'Efectivo', // Valor por defecto
      isPredefined: data['isPredefined'] ?? false,
      details: data['details'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'isPredefined': isPredefined,
      'details': details,
    };
  }
}