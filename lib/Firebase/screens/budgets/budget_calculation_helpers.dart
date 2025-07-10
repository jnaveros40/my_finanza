// lib/screens/budgets/budget_calculation_helpers.dart

import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../models/movement.dart';
import '../../models/category.dart';
import 'package:collection/collection.dart';

/// Mixin que contiene todos los métodos helper para cálculos en BudgetsScreen
mixin BudgetCalculationHelpers {
  
  // Helper para formatear moneda
  String formatCurrency(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
        locale: 'es_CO',
        symbol: getCurrencySymbol(currencyCode),
        decimalDigits: 2
    );
    return formatter.format(amount);
  }

  // Helper para obtener el símbolo de moneda
  String getCurrencySymbol(String currencyCode) {
      switch (currencyCode.toUpperCase()) {
          case 'COP': return '\$';
          case 'USD': return '\$';
          case 'EUR': return '€';
          case 'GBP': return '£';
          case 'JPY': return '¥';
          default: return currencyCode;
      }
  }

  // Helper para obtener el nombre de una categoría dado su ID
  String getCategoryName(String categoryId, List<Category> allCategories) {
    final category = allCategories.firstWhereOrNull((cat) => cat.id == categoryId);
    return category?.name ?? 'Categoría Desconocida';
  }

  // Función para calcular el total gastado para una categoría específica dentro de un presupuesto
  double calculateTotalSpentForCategory(Budget budget, List<Movement> movements, String categoryId) {
      final relevantMovements = movements.where((movement) {
          final movementMonthYear = DateFormat('yyyy-MM').format(movement.dateTime);
          return movement.type == 'expense' &&
                 movementMonthYear == budget.monthYear &&
                 movement.categoryId == categoryId;
      }).toList();

      return relevantMovements.fold(0.0, (sum, movement) => sum + movement.amount);
  }
  // Función para calcular el total gastado para una CATEGORÍA DE PRESUPUESTO (needs, wants, savings)
  double calculateTotalSpentForBudgetCategory(
    Budget budget, 
    List<Movement> movements, 
    String budgetCategoryKey,
    List<Category> allCategories
  ) {
       //print('\n--- calculateTotalSpentForBudgetCategory ---');
       //print('Budget: ${budget.monthYear}, Category: $budgetCategoryKey');
       
       final categoryIdsInBudgetCategory = allCategories
           .where((cat) => cat.type == 'expense' && cat.budgetCategory == budgetCategoryKey)
           .map((cat) => cat.id)
           .whereNotNull()
           .toList();

       //print('Categories found for $budgetCategoryKey: ${categoryIdsInBudgetCategory.length}');
       final categoriesForType = allCategories.where((cat) => cat.type == 'expense' && cat.budgetCategory == budgetCategoryKey).toList();
       for (var cat in categoriesForType) {
         //print('  - ${cat.name} (${cat.id}) budgetCategory: "${cat.budgetCategory}"');
       }

       if (categoryIdsInBudgetCategory.isEmpty) {
           //print('No categories found for $budgetCategoryKey, returning 0.0');
           return 0.0;
       }

       final relevantMovements = movements.where((movement) {
           final movementMonthYear = DateFormat('yyyy-MM').format(movement.dateTime);
           return movement.type == 'expense' &&
                  movementMonthYear == budget.monthYear &&
                  categoryIdsInBudgetCategory.contains(movement.categoryId);
       }).toList();

       //print('Relevant movements for $budgetCategoryKey: ${relevantMovements.length}');
       for (var movement in relevantMovements) {
         final cat = allCategories.firstWhereOrNull((c) => c.id == movement.categoryId);
         //print('  - ${movement.amount} | ${cat?.name ?? "Unknown"} | ${movement.dateTime}');
       }

       final total = relevantMovements.fold(0.0, (sum, movement) => sum + movement.amount);
       //print('Total for $budgetCategoryKey: $total');
       //print('--- END calculateTotalSpentForBudgetCategory ---\n');

       return total;
  }

  // Helper para calcular gastos por categoría específica
  Map<String, double> calculateCategorySpending(
    Budget budget,
    List<Movement> movements,
    String budgetCategoryKey,
    List<Category> allCategories
  ) {
    final categoryIdsInBudgetCategory = allCategories
        .where((cat) => cat.type == 'expense' && cat.budgetCategory == budgetCategoryKey)
        .map((cat) => cat.id)
        .whereNotNull()
        .toList();

    final Map<String, double> categorySpending = {};

    for (String categoryId in categoryIdsInBudgetCategory) {
      final totalSpent = calculateTotalSpentForCategory(budget, movements, categoryId);
      if (totalSpent > 0) {
        categorySpending[categoryId] = totalSpent;
      }
    }

    return categorySpending;
  }
  // Helper para validar si un presupuesto está completo
  bool isBudgetComplete(Budget budget) {
    return budget.totalBudgeted > 0;
  }

  // Helper para calcular el total del presupuesto
  double calculateTotalBudget(Budget budget) {
    return budget.totalBudgeted;
  }

  // Helper para calcular los montos específicos de cada categoría de presupuesto
  Map<String, double> calculateBudgetAmounts(Budget budget) {
    return {
      'needs': budget.totalBudgeted * (budget.needsPercentage / 100),
      'wants': budget.totalBudgeted * (budget.wantsPercentage / 100),
      'savings': budget.totalBudgeted * (budget.savingsPercentage / 100),
    };
  }

  // Helper para calcular porcentajes del presupuesto
  Map<String, double> calculateBudgetPercentages(Budget budget) {
    return {
      'needs': budget.needsPercentage,
      'wants': budget.wantsPercentage,
      'savings': budget.savingsPercentage,
    };
  }  // Helper para calcular montos restantes
  Map<String, double> calculateRemainingAmounts(
    Budget budget,
    List<Movement> movements,
    List<Category> allCategories,
    [Map<String, double>? providedBudgetAmounts]
  ) {
    final spentNeeds = calculateTotalSpentForBudgetCategory(budget, movements, 'needs', allCategories);
    final spentWants = calculateTotalSpentForBudgetCategory(budget, movements, 'wants', allCategories);
    final spentSavings = calculateTotalSpentForBudgetCategory(budget, movements, 'savings', allCategories);

    final budgetAmounts = providedBudgetAmounts ?? calculateBudgetAmounts(budget);

    return {
      'needs': budgetAmounts['needs']! - spentNeeds,
      'wants': budgetAmounts['wants']! - spentWants,
      'savings': budgetAmounts['savings']! - spentSavings,
    };
  }

  // Helper para formatear fecha de mes/año
  String formatMonthYear(String monthYear) {
    try {
      final date = DateFormat('yyyy-MM').parse(monthYear);
      return DateFormat('MMMM yyyy', 'es_ES').format(date);
    } catch (e) {
      return monthYear;
    }
  }

  // Helper para calcular montos gastados por categoría de presupuesto
  Map<String, double> calculateSpentAmounts(
    Budget budget,
    List<Movement> movements,
    List<Category> allCategories
  ) {
    return {
      'needs': calculateTotalSpentForBudgetCategory(budget, movements, 'needs', allCategories),
      'wants': calculateTotalSpentForBudgetCategory(budget, movements, 'wants', allCategories),
      'savings': calculateTotalSpentForBudgetCategory(budget, movements, 'savings', allCategories),
    };
  }

  // Helper para debuggear cálculos de gastos por tipo de presupuesto
  Map<String, double> calculateExpenseByBudgetTypeDebug(
    Budget budget,
    List<Movement> movements,
    List<Category> allCategories
  ) {
    //print('\n=== DEBUG: Budget Calculation Helpers ===');
    //print('Budget: ${budget.monthYear}');
    //print('Total movements: ${movements.length}');
    //print('Total categories: ${allCategories.length}');
    
    final needs = calculateTotalSpentForBudgetCategory(budget, movements, 'needs', allCategories);
    final wants = calculateTotalSpentForBudgetCategory(budget, movements, 'wants', allCategories);
    final savings = calculateTotalSpentForBudgetCategory(budget, movements, 'savings', allCategories);
    
    //print('\nCategories by budget type:');
    
    // Debug categories
    final needsCategories = allCategories.where((cat) => cat.type == 'expense' && cat.budgetCategory == 'needs').toList();
    final wantsCategories = allCategories.where((cat) => cat.type == 'expense' && cat.budgetCategory == 'wants').toList();
    final savingsCategories = allCategories.where((cat) => cat.type == 'expense' && cat.budgetCategory == 'savings').toList();
    
    //print('NEEDS Categories (${needsCategories.length}):');
    for (var cat in needsCategories) {
      //print('  - ${cat.name} (${cat.id}) - budgetCategory: "${cat.budgetCategory}"');
    }
    
    //print('WANTS Categories (${wantsCategories.length}):');
    for (var cat in wantsCategories) {
      //print('  - ${cat.name} (${cat.id}) - budgetCategory: "${cat.budgetCategory}"');
    }
    
    //print('SAVINGS Categories (${savingsCategories.length}):');
    for (var cat in savingsCategories) {
      //print('  - ${cat.name} (${cat.id}) - budgetCategory: "${cat.budgetCategory}"');
    }
    
    // Debug movements
    final relevantMovements = movements.where((movement) {
      final movementMonthYear = DateFormat('yyyy-MM').format(movement.dateTime);
      return movement.type == 'expense' && movementMonthYear == budget.monthYear;
    }).toList();
    
    //print('\nRelevant movements for ${budget.monthYear}: ${relevantMovements.length}');
    for (var movement in relevantMovements) {
      final category = allCategories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
      //print('  - ${movement.amount} | Category: ${category?.name ?? "UNKNOWN"} | budgetCategory: "${category?.budgetCategory ?? "NULL"}"');
    }
    
    //print('\nCalculated totals:');
    //print('  - Needs: $needs');
    //print('  - Wants: $wants');
    //print('  - Savings: $savings');
    //print('=== END Budget Calculation Debug ===\n');
    
    return {
      'Necesidades': needs,
      'Deseos': wants,
      'Ahorros': savings,
    };
  }
}
