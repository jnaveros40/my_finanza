// Modelo para pagos recurrentes
import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringPayment {
  final String? id;
  final String userId;
  final String description;
  final double amount;
  final String categoryId;
  final String accountId;
  final String frequency; // 'mensual', 'semanal', 'quincenal', 'personalizada'
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime? nextPaymentDate;

  RecurringPayment({
    this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.notes,
    this.nextPaymentDate,
  });

  factory RecurringPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecurringPayment(
      id: doc.id,
      userId: data['userId'],
      description: data['description'],
      amount: (data['amount'] as num).toDouble(),
      categoryId: data['categoryId'],
      accountId: data['accountId'],
      frequency: data['frequency'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      notes: data['notes'],
      nextPaymentDate: data['nextPaymentDate'] != null ? (data['nextPaymentDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'description': description,
    'amount': amount,
    'categoryId': categoryId,
    'accountId': accountId,
    'frequency': frequency,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'notes': notes,
    'nextPaymentDate': nextPaymentDate != null ? Timestamp.fromDate(nextPaymentDate!) : null,
  };
}
