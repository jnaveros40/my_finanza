// lib/services/firestore_service/base_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio base que proporciona funcionalidad común para todos los servicios de Firestore
abstract class BaseFirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper para obtener el ID del usuario actual
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Función genérica para obtener una colección de un usuario
  static CollectionReference<Map<String, dynamic>> userCollection(String collectionName) {
    if (currentUserId == null) {
      throw StateError("Usuario no autenticado.");
    }
    return _db.collection('users').doc(currentUserId).collection(collectionName);
  }

  /// Método público para obtener un documento individual
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentById(
      String collectionName, String documentId) async {
    if (currentUserId == null) {
      throw StateError("Usuario no autenticado.");
    }
    return userCollection(collectionName).doc(documentId).get();
  }

  /// Getter para acceso a la instancia de Firestore
  static FirebaseFirestore get db => _db;

  /// Getter para acceso a la instancia de FirebaseAuth
  static FirebaseAuth get auth => _auth;

  /// Método para validar que el usuario esté autenticado
  static void validateAuthentication() {
    if (currentUserId == null) {
      throw StateError("Usuario no autenticado.");
    }
  }

  /// Método helper para crear opciones de merge para Firestore
  static SetOptions get mergeOptions => SetOptions(merge: true);
}
