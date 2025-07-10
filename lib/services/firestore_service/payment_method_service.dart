// lib/services/firestore_service/payment_method_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment_method.dart';
import 'base_firestore_service.dart';

class PaymentMethodService extends BaseFirestoreService {
  // Guardar o actualizar un método de pago
  static Future<void> savePaymentMethod(PaymentMethod method) async {
    BaseFirestoreService.validateAuthentication();
    return BaseFirestoreService.userCollection('payment_methods')
        .doc(method.id)
        .set(method.toFirestore(), BaseFirestoreService.mergeOptions);
  }

  // Obtener todos los métodos de pago del usuario autenticado
  static Stream<List<PaymentMethod>> getPaymentMethods() {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value([]);
    }
    return BaseFirestoreService.userCollection('payment_methods')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList());
  }

  // Obtener un método de pago por su ID
  static Future<PaymentMethod?> getPaymentMethodById(String methodId) async {
    if (BaseFirestoreService.currentUserId == null) {
      return null;
    }
    try {
      DocumentSnapshot doc = await BaseFirestoreService.getDocumentById('payment_methods', methodId);
      if (!doc.exists) return null;
      return PaymentMethod.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Eliminar un método de pago por su ID
  static Future<void> deletePaymentMethod(String methodId) async {
    BaseFirestoreService.validateAuthentication();
    return BaseFirestoreService.userCollection('payment_methods').doc(methodId).delete();
  }
}
