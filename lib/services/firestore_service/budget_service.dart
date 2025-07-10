import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget.dart';
import 'base_firestore_service.dart';

class BudgetService extends BaseFirestoreService {
  // Guardar o actualizar un presupuesto
  static Future<void> saveBudget(Budget budget) async {
    BaseFirestoreService.validateAuthentication();
    return BaseFirestoreService.userCollection('budgets')
        .doc(budget.id)
        .set(budget.toFirestore(), BaseFirestoreService.mergeOptions);
  }

  // Obtener todos los presupuestos como stream
  static Stream<List<Budget>> getBudgets() {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value([]);
    }
    return BaseFirestoreService.userCollection('budgets')
        .orderBy('monthYear', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList());
  }

  // Obtener un presupuesto por mes/año (ej: '2024-06')
  static Future<Budget?> getBudgetByMonthYear(String monthYear) async {
    if (BaseFirestoreService.currentUserId == null) {
      return null;
    }
    try {
      QuerySnapshot snapshot = await BaseFirestoreService.userCollection('budgets')
          .where('monthYear', isEqualTo: monthYear)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      } else {
        return Budget.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      return null;
    }
  }

  // Eliminar un presupuesto por ID
  static Future<void> deleteBudget(String budgetId) async {
    BaseFirestoreService.validateAuthentication();
    return BaseFirestoreService.userCollection('budgets').doc(budgetId).delete();
  }
}
