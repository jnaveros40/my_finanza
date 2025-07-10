// lib/models/movement.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Movement {
  final String? id; // ID del documento en Firestore
  final String userId; // ID del usuario propietario
  final String accountId; // ID de la cuenta afectada por el movimiento (origen o destino)
  final String? destinationAccountId; // Cuenta de destino para transferencias y pagos

  final String categoryId; // ID de la categoría (para gastos e ingresos)
  final String? paymentMethodId; // <-- Hacer este campo nullable

  final double amount;
  final String description;
  final String? notes;
  final DateTime dateTime;

  // Tipo de Movimiento
  final String type;
  // 'income' para ingresos, 'expense' para gastos, 'transfer' para transferencias entre cuentas
  final String currency;

  // Constructor de Movement
  Movement({
    this.id,
    required this.userId,
    required this.accountId,
    this.destinationAccountId,
    required this.categoryId,
    this.paymentMethodId, // <-- Ya no es requerido en el constructor
    required this.amount,
    required this.description,
    this.notes,
    required this.dateTime,
    required this.type,
    required this.currency,
  });

  // Constructor factory para crear una instancia de Movement desde un documento de Firestore
  factory Movement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Movement(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      accountId: data['accountId'] as String? ?? '',
      destinationAccountId: data['destinationAccountId'] as String?,
      categoryId: data['categoryId'] as String? ?? '',
      paymentMethodId: data['paymentMethodId'] as String?, // <-- Leer como String?
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      notes: data['notes'] as String?,
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String? ?? 'expense',
      currency: data['currency'] as String? ?? 'USD',
    );
  }

  // Método para convertir una instancia de Movement a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountId': accountId,
      'destinationAccountId': destinationAccountId,
      'categoryId': categoryId,
      'paymentMethodId': paymentMethodId, // <-- Guardar el campo (será null si no se asigna)
      'amount': amount,
      'description': description,
      'notes': notes,
      'dateTime': Timestamp.fromDate(dateTime),
      'type': type,
      'currency': currency,
      

    };
  }

  // Método copyWith para facilitar la creación de nuevas instancias modificadas
  Movement copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    String? paymentMethodId, // <-- Hacer nullable en copyWith
    double? amount,
    String? description,
    String? notes,
    DateTime? dateTime,
    String? type,
    String? currency,
  }) {
    return Movement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId, // <-- Asignar
      amount: amount ?? this.amount,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      currency: currency ?? this.currency,
    );
  }
}
