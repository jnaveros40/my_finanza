// lib/models/budget.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String? id; // ID del documento en Firestore (generalmente generado por Firestore)
  final String userId; // ID del usuario propietario
  final String monthYear; // Período del presupuesto en formato YYYY-MM (ej. "2023-10")

  // --- Campos para el Presupuesto Total Manual y Distribución 50/30/20 ---
  final double totalBudgeted; // El monto total presupuestado manualmente

  // NUEVOS CAMPOS: Porcentajes editables para el desglose 50/30/20
  final double needsPercentage; // Porcentaje asignado a Necesidades
  final double wantsPercentage; // Porcentaje asignado a Deseos
  final double savingsPercentage; // Porcentaje asignado a Ahorros

  // --- NUEVO CAMPO: Moneda del presupuesto ---
  final String currency; // Ej: 'USD', 'COP', 'EUR'
  // ------------------------------------------


  // Mapa donde la clave es el ID de la categoría y el valor es el monto presupuestado para esa categoría.
  // Esto permite flexibilidad para presupuestar por cualquier categoría de gasto.
  final Map<String, double> categoryBudgets;

  // Opcional: Podrías añadir campos para ingresos presupuestados por categoría si es necesario.
  // final Map<String, double>? categoryIncomeBudgets;

  Budget({
    this.id,
    required this.userId,
    required this.monthYear,
    required this.totalBudgeted,
    // Asegurarse de que los nuevos campos son requeridos o tienen un valor por defecto
    required this.needsPercentage,
    required this.wantsPercentage,
    required this.savingsPercentage,
    // --- Hacer currency requerido en el constructor ---
    required this.currency,
    // -------------------------------------------------
    required this.categoryBudgets,
    // this.categoryIncomeBudgets, // Opcional
  });

  // Constructor factory para crear una instancia de Budget desde un documento de Firestore
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Leer el mapa de categoryBudgets, manejando posibles valores nulos o tipos incorrectos
    final Map<String, dynamic>? categoryBudgetsData = data['categoryBudgets'] as Map<String, dynamic>?;
    final Map<String, double> categoryBudgets = {};
    if (categoryBudgetsData != null) {
      categoryBudgetsData.forEach((key, value) {
        // Intentar convertir a double, manejar posibles errores o valores nulos
        categoryBudgets[key] = (value as num?)?.toDouble() ?? 0.0;
      });
    }

    // Leer los nuevos campos de porcentaje, proporcionando valores por defecto si no existen
    final double needsPercentage = (data['needsPercentage'] as num?)?.toDouble() ?? 50.0;
    final double wantsPercentage = (data['wantsPercentage'] as num?)?.toDouble() ?? 30.0;
    final double savingsPercentage = (data['savingsPercentage'] as num?)?.toDouble() ?? 20.0;

    // --- Leer el campo currency, proporcionar un valor por defecto si no existe (ej. 'COP') ---
    final String currency = data['currency'] as String? ?? 'COP'; // Puedes ajustar el valor por defecto si es necesario
    // ----------------------------------------------------------------------------------------


    return Budget(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      monthYear: data['monthYear'] as String? ?? '',
      totalBudgeted: (data['totalBudgeted'] as num?)?.toDouble() ?? 0.0,
      needsPercentage: needsPercentage, // Asignar el valor leído
      wantsPercentage: wantsPercentage, // Asignar el valor leído
      savingsPercentage: savingsPercentage, // Asignar el valor leído
      currency: currency, // --- Asignar el valor leído ---
      categoryBudgets: categoryBudgets, // Asignar el mapa leído
      // categoryIncomeBudgets: cleanedCategoryIncomeBudgets, // Opcional
    );
  }

  // Método para convertir una instancia de Budget a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    // Asegurarse de que los valores en categoryBudgets son doubles
    final Map<String, double> cleanedCategoryBudgets = categoryBudgets.map((key, value) => MapEntry(key, value.toDouble()));

    // Asegurarse de que los valores en categoryIncomeBudgets son doubles (opcional)
    // final Map<String, double>? cleanedCategoryIncomeBudgets = categoryIncomeBudgets?.map((key, value) => MapEntry(key, value.toDouble()));


    return {
      'userId': userId,
      'monthYear': monthYear,
      'totalBudgeted': totalBudgeted,
      'needsPercentage': needsPercentage, // Guardar el nuevo campo
      'wantsPercentage': wantsPercentage, // Guardar el nuevo campo
      'savingsPercentage': savingsPercentage, // Guardar el nuevo campo
      'currency': currency, // --- Guardar el campo currency ---
      'categoryBudgets': cleanedCategoryBudgets, // Guardar el mapa con valores double
      // 'categoryIncomeBudgets': cleanedCategoryIncomeBudgets, // Guardar el mapa (opcional)
    };
  }

  // Método copyWith para facilitar la creación de nuevas instancias modificadas
  Budget copyWith({
    String? id,
    String? userId,
    String? monthYear,
    double? totalBudgeted,
    double? needsPercentage, // Añadir a copyWith
    double? wantsPercentage, // Añadir a copyWith
    double? savingsPercentage, // Añadir a copyWith
    String? currency, // --- Añadir currency a copyWith ---
    Map<String, double>? categoryBudgets,
    // Map<String, double>? categoryIncomeBudgets, // Opcional
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthYear: monthYear ?? this.monthYear,
      totalBudgeted: totalBudgeted ?? this.totalBudgeted,
      needsPercentage: needsPercentage ?? this.needsPercentage, // Asignar en copyWith
      wantsPercentage: wantsPercentage ?? this.wantsPercentage, // Asignar en copyWith
      savingsPercentage: savingsPercentage ?? this.savingsPercentage, // Asignar en copyWith
      currency: currency ?? this.currency, // --- Asignar en copyWith ---
      // Crear una copia profunda del mapa para evitar referencias compartidas
      categoryBudgets: categoryBudgets != null ? Map.from(categoryBudgets) : Map.from(this.categoryBudgets),
      // categoryIncomeBudgets: categoryIncomeBudgets != null ? Map.from(categoryIncomeBudgets) : (this.categoryIncomeBudgets != null ? Map.from(this.categoryIncomeBudgets!) : null), // Opcional
    );
  }

  // Opcional: Sobrescribir toString para facilitar la depuración
  @override
  String toString() {
    return 'Budget{id: $id, userId: $userId, monthYear: $monthYear, totalBudgeted: $totalBudgeted, needsPercentage: $needsPercentage, wantsPercentage: $wantsPercentage, savingsPercentage: $savingsPercentage, currency: $currency, categoryBudgets: $categoryBudgets}';
  }
}
