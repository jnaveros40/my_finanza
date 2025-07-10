// Servicio para CRUD de pagos recurrentes
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recurring_payment.dart';

class RecurringPaymentService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    if (currentUserId == null) throw StateError('Usuario no autenticado');
    return _db.collection('users').doc(currentUserId).collection('recurring_payments');
  }

  Future<void> saveRecurringPayment(RecurringPayment payment) async {
    if (payment.id != null) {
      await _collection.doc(payment.id).set(payment.toFirestore());
    } else {
      await _collection.add(payment.toFirestore());
    }
  }

  Stream<List<RecurringPayment>> getRecurringPayments() {
    if (currentUserId == null) return Stream.value([]);
    return _collection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => RecurringPayment.fromFirestore(doc)).toList()
    );
  }

  Future<void> deleteRecurringPayment(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> updateAllNextPaymentDates() async {
    if (currentUserId == null) return;
    final snapshot = await _collection.get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final startDate = (data['startDate'] as Timestamp).toDate();
      final frequency = data['frequency'] as String;
      DateTime nextPaymentDate;
      switch (frequency) {
        case 'mensual':
          nextPaymentDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
          break;
        case 'semanal':
          nextPaymentDate = startDate.add(Duration(days: 7));
          break;
        case 'quincenal':
          nextPaymentDate = startDate.add(Duration(days: 15));
          break;
        case 'personalizada':
          nextPaymentDate = startDate;
          break;
        default:
          nextPaymentDate = startDate;
      }
      await doc.reference.update({'nextPaymentDate': Timestamp.fromDate(nextPaymentDate)});
    }
  }
}
