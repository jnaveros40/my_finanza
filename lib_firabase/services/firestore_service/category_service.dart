// lib/services/firestore_service/category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category.dart';
import 'base_firestore_service.dart';

class CategoryService extends BaseFirestoreService {
  // Guardar o actualizar una categoría
  static Future<void> saveCategory(Category category) async {
    BaseFirestoreService.validateAuthentication();
    return BaseFirestoreService.userCollection('categories')
        .doc(category.id)
        .set(category.toFirestore(), BaseFirestoreService.mergeOptions);
  }

  // Obtener todas las categorías del usuario autenticado
  static Stream<List<Category>> getCategories() {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value([]);
    }
    return BaseFirestoreService.userCollection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  // Obtener categorías por tipo ('expense' o 'income')
  static Stream<List<Category>> getCategoriesByType(String type) {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value([]);
    }
    return BaseFirestoreService.userCollection('categories')
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  // Obtener una categoría por su ID
  static Future<Category?> getCategoryById(String categoryId) async {
    if (BaseFirestoreService.currentUserId == null) {
      return null;
    }
    try {
      DocumentSnapshot doc = await BaseFirestoreService.getDocumentById('categories', categoryId);
      if (!doc.exists) return null;
      return Category.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Eliminar una categoría por su ID
  static Future<void> deleteCategory(String categoryId) async {
    BaseFirestoreService.validateAuthentication();
    return BaseFirestoreService.userCollection('categories').doc(categoryId).delete();
  }
}
