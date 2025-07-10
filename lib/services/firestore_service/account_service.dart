// lib/services/firestore_service/account_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/account.dart';
import 'base_firestore_service.dart';

/// Servicio especializado para operaciones CRUD de cuentas
class AccountService extends BaseFirestoreService {
  
  /// Guardar o actualizar una cuenta
  static Future<void> saveAccount(Account account) async {
    BaseFirestoreService.validateAuthentication();
    return BaseFirestoreService.userCollection('accounts')
        .doc(account.id)
        .set(account.toFirestore(), BaseFirestoreService.mergeOptions);
  }

  /// Obtener todas las cuentas como stream
  static Stream<List<Account>> getAccounts() {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value([]);
    }
    return BaseFirestoreService.userCollection('accounts')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromFirestore(doc))
            .toList());
  }

  /// Obtener una cuenta específica por ID
  static Future<Account?> getAccountById(String accountId) async {
    if (BaseFirestoreService.currentUserId == null) {
      return null;
    }
    try {
      DocumentSnapshot doc = await BaseFirestoreService.getDocumentById('accounts', accountId);
      if (!doc.exists) return null;
      return Account.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Obtener una cuenta como stream por ID
  static Stream<Account?> getAccountStreamById(String accountId) {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value(null);
    }
    return BaseFirestoreService.userCollection('accounts')
        .doc(accountId)
        .snapshots()
        .map((doc) => doc.exists ? Account.fromFirestore(doc) : null);
  }

  /// Eliminar una cuenta
  static Future<void> deleteAccount(String accountId) async {
    BaseFirestoreService.validateAuthentication();
    // TODO: Considerar qué hacer con los movimientos asociados a esta cuenta antes de eliminarla.
    return BaseFirestoreService.userCollection('accounts').doc(accountId).delete();
  }

  /// Verificar si existe al menos una cuenta para el usuario
  static Future<bool> hasAccounts() async {
    if (BaseFirestoreService.currentUserId == null) {
      return false;
    }
    try {
      final snapshot = await BaseFirestoreService.userCollection('accounts').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtener el número total de cuentas
  static Future<int> getAccountsCount() async {
    if (BaseFirestoreService.currentUserId == null) {
      return 0;
    }
    try {
      final snapshot = await BaseFirestoreService.userCollection('accounts').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
  
}
