// No se requieren imports directos de los servicios especializados para el borrado masivo

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service/base_firestore_service.dart';

/// Servicio para borrar todos los datos del usuario autenticado
class UserDataWipeService {
  /// Borra todas las cuentas, movimientos, presupuestos, deudas y categorías del usuario autenticado
  static Future<void> wipeAllUserData() async {
    final batch = FirebaseFirestore.instance.batch();
    // final userId = FirebaseFirestore.instance.app.options.projectId; // Solo para debug

    // Borrar cuentas
    final accountsSnap = await BaseFirestoreService.userCollection('accounts').get();
    for (final doc in accountsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Borrar movimientos
    final movementsSnap = await BaseFirestoreService.userCollection('expenses').get();
    for (final doc in movementsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Borrar presupuestos
    final budgetsSnap = await BaseFirestoreService.userCollection('budgets').get();
    for (final doc in budgetsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Borrar deudas
    final debtsSnap = await BaseFirestoreService.userCollection('debts').get();
    for (final doc in debtsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Borrar categorías
    final categoriesSnap = await BaseFirestoreService.userCollection('categories').get();
    for (final doc in categoriesSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
