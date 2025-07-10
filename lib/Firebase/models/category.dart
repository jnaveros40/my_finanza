// lib/models/category.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String? id; // ID del documento en Firestore
  final String userId; // ID del usuario propietario
  final String name;
  final String type; // 'expense' o 'income'

  // --- NUEVO CAMPO: Categoría de Presupuesto 50/30/20 ---
  // Puede ser 'needs', 'wants', 'savings', o null si no aplica (ej. categorías de transferencia)
  final String? budgetCategory;
  // ----------------------------------------------------


  Category({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.budgetCategory, // <-- Añadir al constructor
  });

  // Constructor factory para crear una instancia de Category desde un documento de Firestore
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id, // El ID del documento es importante
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      budgetCategory: data['budgetCategory'] as String?, // <-- Leer el nuevo campo
    );
  }

  // Método para convertir una instancia de Category a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'budgetCategory': budgetCategory, // <-- Guardar el nuevo campo (será null si no se asigna)
      // No incluimos el 'id' aquí porque Firestore lo genera automáticamente al añadir
    };
  }

  // Método copyWith para facilitar la creación de nuevas instancias modificadas
  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? budgetCategory, // <-- Añadir a copyWith
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      budgetCategory: budgetCategory ?? this.budgetCategory, // <-- Asignar en copyWith
    );
  }
}
