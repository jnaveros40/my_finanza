import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/debt.dart';
import 'base_firestore_service.dart';

/// Servicio especializado para operaciones de deudas
class DebtService extends BaseFirestoreService {
  /// Obtener todas las deudas del usuario actual
  static Stream<List<Debt>> getDebts() {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value([]);
    }
    final query = BaseFirestoreService.userCollection('debts')
        .orderBy('dueDate', descending: false);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Debt.fromFirestore(doc)).toList());
  }

  /// Guardar (crear o actualizar) una deuda
  static Future<void> saveDebt(Debt debt) async {
    BaseFirestoreService.validateAuthentication();
    final ref = BaseFirestoreService.userCollection('debts').doc(debt.id);
    await ref.set(debt.toFirestore(), BaseFirestoreService.mergeOptions);
  }

  /// Eliminar una deuda por ID
  static Future<void> deleteDebt(String debtId) async {
    BaseFirestoreService.validateAuthentication();
    final ref = BaseFirestoreService.userCollection('debts').doc(debtId);
    await ref.delete();
  }

  /// Obtener una deuda por ID
  static Future<Debt?> getDebtById(String debtId) async {
    BaseFirestoreService.validateAuthentication();
    final ref = BaseFirestoreService.userCollection('debts').doc(debtId);
    final doc = await ref.get();
    if (!doc.exists) return null;
    return Debt.fromFirestore(doc);
  }
}
