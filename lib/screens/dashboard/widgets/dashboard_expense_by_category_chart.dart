// dashboard_expense_by_category_chart.dart
// Componente modular para mostrar el gráfico de gastos por categoría

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';

class DashboardExpenseByCategoryChart extends StatelessWidget {
  final List<Movement> movements;
  final List<Category> categories;

  const DashboardExpenseByCategoryChart({
    super.key,
    required this.movements,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar solo gastos
    final expenses = movements.where((m) => m.type == 'expense');

    // Agrupar gastos por categoría y sumar los montos
    final expenseByCategory = expenses.groupFoldBy<String, double>(
      (movement) {
        // Asegurarse de que la categoría no sea null antes de acceder a category.name
        final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
        return category?.name ?? 'Sin Categoría'; // Usar nombre de categoría o 'Sin Categoría'
      },
      (previous, movement) => (previous ?? 0.0) + movement.amount, // Acumular monto
    );

    // Calcular el total de gastos para el título
    double totalExpense = expenseByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    // Construir las secciones del gráfico de torta
    final sections = _buildPieChartSections(expenseByCategory, totalExpense, context);    // Si no hay gastos, mostrar un mensaje
    if (totalExpense <= 0) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
          title: Text('Gastos por Categoría', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '0 categorías',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sin gastos en el período',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No hay datos de gastos por categoría en este rango de fechas para el gráfico.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(Icons.pie_chart, color: Colors.red),
        title: Text('Gastos por Categoría', style: Theme.of(context).textTheme.titleLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${expenseByCategory.length} categorías',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Total: ${_formatCurrency(totalExpense, 'COP')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del total con icono
                Row(
                  children: [
                    Icon(Icons.trending_down, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Resumen de Gastos', style: Theme.of(context).textTheme.titleMedium),
                    Spacer(),
                    Tooltip(
                      message: 'Distribución de gastos por categoría en el período seleccionado',
                      child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Total de Gastos:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalExpense, 'COP'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
                  Divider(),
                SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    return AspectRatio(
                      aspectRatio: isMobile ? 1.3 : 1.5,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: isMobile ? 30 : 40,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                // Leyenda del gráfico
                _buildChartLegend(expenseByCategory, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir las secciones del gráfico de torta
  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> dataByCategory,
    double totalAmount,
    BuildContext context
  ) {
    if (totalAmount == 0) {
      return [];
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
      Colors.lime,
      Colors.pink,
      Colors.amber,
    ];

    int colorIndex = 0;

    // Ordenar por monto descendente para asegurar consistencia en los colores de la leyenda
    final sortedEntries = dataByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));    return sortedEntries.map((entry) {
      // No necesitamos usar categoryName en este contexto
      final amount = entry.value;
      // Calcular porcentaje usando totalAmount pasado como parámetro
      final percentage = (amount / totalAmount) * 100;

      final sectionColor = colors[colorIndex % colors.length];
      colorIndex++;

      // Evitar secciones con porcentaje 0
      if (percentage < 1.0 && percentage > 0) { // Mostrar porcentajes muy pequeños como "<1%"
        return PieChartSectionData(
          color: sectionColor,
          value: amount,
          title: '<1%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      } else if (percentage >= 1.0) {
        return PieChartSectionData(
          color: sectionColor,
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      } else {
        return PieChartSectionData(value: 0); // Sección invisible
      }
    }).where((section) => section.value > 0).toList(); // Filtrar secciones con valor > 0
  }

  // Widget para construir la leyenda del gráfico
  Widget _buildChartLegend(
    Map<String, double> dataByCategory,
    BuildContext context
  ) {
    // Ordenar por monto descendente para la leyenda
    final sortedEntries = dataByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
      Colors.lime,
      Colors.pink,
      Colors.amber,
    ];

    int colorIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries.map((entry) {
        final categoryName = entry.key;
        final amount = entry.value;

        final legendColor = colors[colorIndex % colors.length];
        colorIndex++;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: legendColor,
                margin: EdgeInsets.only(right: 8),
              ),
              Expanded(
                child: Text(
                  '$categoryName: ${_formatCurrency(amount, 'COP')}',
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

  // Método para formatear valores monetarios
  String _formatCurrency(double amount, String currencyCode) {
    final formatCurrency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }
}
