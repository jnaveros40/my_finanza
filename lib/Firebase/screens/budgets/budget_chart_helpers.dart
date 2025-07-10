// lib/screens/budgets/budget_chart_helpers.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import '../../models/budget.dart';
import '../../models/movement.dart';
import '../../models/category.dart';
import 'package:intl/intl.dart';

/// Mixin que contiene todos los métodos helper para gráficos en BudgetsScreen
mixin BudgetChartHelpers {
  
  // Colores fijos para las categorías de presupuesto
  static const Map<String, Color> categoryColors = {
    'needs': Colors.orange,
    'wants': Colors.blue,
    'savings': Colors.green,
  };

  // Construir secciones del gráfico de pastel para GASTO
  List<PieChartSectionData> buildSpentBudgetPieChartSections(
    double spentNeeds, 
    double spentWants, 
    double spentSavings
  ) {
    final totalSpent = spentNeeds + spentWants + spentSavings;
    if (totalSpent <= 0) return [];

    final List<PieChartSectionData> sections = [];

    if (spentNeeds.abs() > 0) {
      final percentage = (spentNeeds / totalSpent) * 100;
      sections.add(
        PieChartSectionData(
          color: categoryColors['needs'],
          value: spentNeeds.abs(),
          title: percentage >= 1.0 ? '${percentage.toStringAsFixed(1)}%' : (percentage.abs() > 0 ? '<1%' : ''),
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (spentWants.abs() > 0) {
      final percentage = (spentWants / totalSpent) * 100;
      sections.add(
        PieChartSectionData(
          color: categoryColors['wants'],
          value: spentWants.abs(),
          title: percentage >= 1.0 ? '${percentage.toStringAsFixed(1)}%' : (percentage.abs() > 0 ? '<1%' : ''),
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (spentSavings.abs() > 0) {
      final percentage = (spentSavings / totalSpent) * 100;
      sections.add(
        PieChartSectionData(
          color: categoryColors['savings'],
          value: spentSavings.abs(),
          title: percentage >= 1.0 ? '${percentage.toStringAsFixed(1)}%' : (percentage.abs() > 0 ? '<1%' : ''),
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  // Construir secciones del gráfico de pastel para RESTANTE
  List<PieChartSectionData> buildRemainingBudgetPieChartSections(
    double remainingNeeds, 
    double remainingWants, 
    double remainingSavings
  ) {
    final totalRemaining = remainingNeeds + remainingWants + remainingSavings;
    if (totalRemaining == 0) return [];

    final List<PieChartSectionData> sections = [];

    if (remainingNeeds.abs() > 0) {
      final percentage = (remainingNeeds / totalRemaining) * 100;
      final displayPercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : percentage;

      sections.add(
        PieChartSectionData(
          color: categoryColors['needs'],
          value: remainingNeeds.abs(),
          title: displayPercentage >= 1.0 ? '${displayPercentage.toStringAsFixed(1)}%' : (displayPercentage.abs() > 0 ? '<1%' : ''),
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (remainingWants.abs() > 0) {
      final percentage = (remainingWants / totalRemaining) * 100;
      final displayPercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : percentage;
      
      sections.add(
        PieChartSectionData(
          color: categoryColors['wants'],
          value: remainingWants.abs(),
          title: displayPercentage >= 1.0 ? '${displayPercentage.toStringAsFixed(1)}%' : (displayPercentage.abs() > 0 ? '<1%' : ''),
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (remainingSavings.abs() > 0) {
      final percentage = (remainingSavings / totalRemaining) * 100;
      final displayPercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : percentage;
      
      sections.add(
        PieChartSectionData(
          color: categoryColors['savings'],
          value: remainingSavings.abs(),
          title: displayPercentage >= 1.0 ? '${displayPercentage.toStringAsFixed(1)}%' : (displayPercentage.abs() > 0 ? '<1%' : ''),
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  // Helper para formatear moneda de forma consistente
  String formatCurrency(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '', // Sin símbolo, solo valor
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
  }

  // Construir la leyenda para los gráficos de presupuesto
  Widget buildBudgetChartLegend(
    BuildContext context, 
    Map<String, double> data, 
    String currencyCode,
    Map<String, String> budgetCategoryNames,
    String Function(double, String) _,
  ) {
    final sortedEntries = data.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries.map((entry) {
        final categoryKey = entry.key;
        final amount = entry.value;

        if (amount.abs() <= 0) return const SizedBox.shrink();

        final legendColor = categoryColors[categoryKey] ?? Colors.grey;
        final categoryName = budgetCategoryNames[categoryKey] ?? 'Desconocido';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: legendColor,
                margin: const EdgeInsets.only(right: 8),
              ),
              Expanded(
                child: Text(
                  '$categoryName: ${formatCurrency(amount, currencyCode)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Construir secciones del gráfico de pastel para CATEGORÍAS ESPECÍFICAS
  List<PieChartSectionData> buildSpecificCategoryPieChartSections(
    Map<String, double> categorySpending
  ) {
    final totalSpent = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
    if (totalSpent <= 0) return [];

    final List<PieChartSectionData> sections = [];
    final List<Color> colors = List.generate(
      categorySpending.length, 
      (index) => Colors.primaries[index % Colors.primaries.length]
    );

    final sortedEntries = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final amount = entry.value;
      final percentage = (amount / totalSpent) * 100;

      if (amount > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[i],
            value: amount,
            title: percentage >= 1.0 ? '${percentage.toStringAsFixed(1)}%' : (percentage > 0 ? '<1%' : ''),
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  // Construir la leyenda para el gráfico de CATEGORÍAS ESPECÍFICAS
  Widget buildSpecificCategoryChartLegend(
    BuildContext context,
    Map<String, double> categorySpending,
    String currencyCode,
    String Function(String, List) getCategoryName,
    List categories,
    String Function(double, String) _
  ) {
    final sortedEntries = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> colors = List.generate(
      categorySpending.length, 
      (index) => Colors.primaries[index % Colors.primaries.length]
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries.mapIndexed((index, entry) {
        final categoryId = entry.key;
        final amount = entry.value;

        if (amount.abs() <= 0) return const SizedBox.shrink();

        final legendColor = colors[index];
        final categoryName = getCategoryName(categoryId, categories);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: legendColor,
                margin: const EdgeInsets.only(right: 8),
              ),
              Expanded(
                child: Text(
                  '$categoryName: ${formatCurrency(amount, currencyCode)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Widget para mostrar un gráfico de pastel con título
  Widget buildPieChart({
    required BuildContext context,
    required String title,
    required List<PieChartSectionData> sections,
    required Widget legend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),          if (sections.isNotEmpty) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                // Determinar si estamos en móvil o pantalla grande
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  // En móvil: diseño vertical con gráfico más compacto
                  return Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.3, // Más cuadrado para móvil
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: MediaQuery.of(context).size.width < 400 ? 30 : 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      legend,
                    ],
                  );
                } else {
                  // En pantallas grandes: diseño horizontal
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AspectRatio(
                          aspectRatio: 1.0, // Más cuadrado para el diseño horizontal
                          child: PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: legend,
                      ),
                    ],
                  );
                }
              },
            ),
          ] else ...[
            AspectRatio(
              aspectRatio: 2.0,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: MediaQuery.of(context).size.width < 400 ? 32 : 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin datos para mostrar',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }  /// Builds spending chart widget
  Widget buildSpendingChart(
    BuildContext context,
    Map<String, double> budgetAmounts,
    Map<String, double> spentAmounts,  ) {
    final spentSections = buildSpentBudgetPieChartSections(
      spentAmounts['needs'] ?? 0.0,
      spentAmounts['wants'] ?? 0.0,
      spentAmounts['savings'] ?? 0.0,
    );

    if (spentSections.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Distribución de Gastos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            const Text('No hay gastos registrados'),
          ],
        ),
      );
    }

    return buildPieChart(
      context: context,
      title: 'Distribución de Gastos',
      sections: spentSections,
      legend: buildBudgetChartLegend(
        context,
        spentAmounts,
        'COP',
        {
          'needs': 'Necesidades',
          'wants': 'Deseos',
          'savings': 'Ahorros',
        },
        formatCurrency,
      ),
    );
  }

  /// Builds remaining budget chart widget
  Widget buildRemainingChart(
    BuildContext context,
    Map<String, double> budgetAmounts,
    Map<String, double> spentAmounts,
  ) {
    final remainingAmounts = <String, double>{};
    for (final category in budgetAmounts.keys) {
      final remaining = budgetAmounts[category]! - (spentAmounts[category] ?? 0.0);
      remainingAmounts[category] = remaining > 0 ? remaining : 0.0;
    }    final remainingSections = buildRemainingBudgetPieChartSections(
      remainingAmounts['needs'] ?? 0.0,
      remainingAmounts['wants'] ?? 0.0,
      remainingAmounts['savings'] ?? 0.0,
    );

    if (remainingSections.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Presupuesto Restante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            const Text('No hay presupuesto restante'),
          ],
        ),
      );
    }

    return buildPieChart(
      context: context,
      title: 'Presupuesto Restante',
      sections: remainingSections,
      legend: buildBudgetChartLegend(
        context,
        remainingAmounts,
        'COP',
        {
          'needs': 'Necesidades',
          'wants': 'Deseos',
          'savings': 'Ahorros',
        },
        formatCurrency,
      ),
    );
  }

  /// Builds specific categories chart widget
  Widget buildSpecificCategoriesChart(
    BuildContext context,
    Budget budget,
    List<Movement> movements,
    List<Category> allCategories,
    String budgetCategoryFilter,
  ) {
    if (budgetCategoryFilter == 'all') {
      return const SizedBox.shrink();
    }

    final categoriesInFilter = allCategories
        .where((cat) => cat.type == 'expense' && cat.budgetCategory == budgetCategoryFilter)
        .toList();

    if (categoriesInFilter.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Categorías Específicas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            const Text('No hay categorías en este filtro'),
          ],
        ),
      );
    }    final categoryData = <String, double>{};

    //print('\n=== DEBUG: buildSpecificCategoriesChart ===');
    //print('Budget: ${budget.monthYear}');
    //print('Filter: $budgetCategoryFilter');
    //print('Categories in filter: ${categoriesInFilter.length}');
    //print('Total movements: ${movements.length}');

    // Filter movements by budget month/year
    final filteredMovements = movements.where((m) {
      final movementMonthYear = DateFormat('yyyy-MM').format(m.dateTime);
      return m.type == 'expense' && movementMonthYear == budget.monthYear;
    }).toList();

    //print('Filtered movements for ${budget.monthYear}: ${filteredMovements.length}');

    for (final category in categoriesInFilter) {
      final spent = filteredMovements
          .where((m) => m.categoryId == category.id)
          .fold(0.0, (sum, m) => sum + m.amount);
      
      //print('Category ${category.name}: ${category.id} -> spent: $spent');
      
      if (spent > 0) {
        categoryData[category.id!] = spent;
      }
    }

    //print('Final category data: $categoryData');
    //print('=== END buildSpecificCategoriesChart DEBUG ===\n');

    if (categoryData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Categorías Específicas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            const Text('No hay gastos en estas categorías'),
          ],
        ),
      );
    }    final categorySections = buildSpecificCategoryPieChartSections(
      categoryData,
    );

    return buildPieChart(
      context: context,
      title: 'Categorías Específicas',
      sections: categorySections,
      legend: buildSpecificCategoryChartLegend(
        context,
        categoryData,
        'COP',
        (categoryId, categories) {
          final category = categories.cast<Category>().firstWhereOrNull((c) => c.id == categoryId);
          return category?.name ?? 'Desconocida';
        },
        allCategories,
        formatCurrency,
      ),
    );
  }

  /// Crea una sección para el gráfico de pastel
  PieChartSectionData createPieChartSection({
    required double value,
    required Color color,
    required String title,
    double radius = 100,
  }) {
    final percentage = (value / (value + radius)) * 100;
    final displayPercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : percentage;

    return PieChartSectionData(
      value: value,
      color: color,
      title: displayPercentage >= 1.0 ? '${displayPercentage.toStringAsFixed(1)}%' : (displayPercentage.abs() > 0 ? '<1%' : ''),
      radius: radius,
      titleStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // ...existing code...
}
