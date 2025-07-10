import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:mis_finanza/models/budget.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';

class DashboardBudgetOverview extends StatefulWidget {
  final List<Budget> budgets;
  final List<Movement> movements;
  final List<Category> categories;
  final String? initialBudgetId;
  final Function(String?) onBudgetSelected;
  
  const DashboardBudgetOverview({
    super.key,
    required this.budgets,
    required this.movements,
    required this.categories,
    this.initialBudgetId,
    required this.onBudgetSelected,
  });

  @override
  _DashboardBudgetOverviewState createState() => _DashboardBudgetOverviewState();
}

class _DashboardBudgetOverviewState extends State<DashboardBudgetOverview> {
  String? _selectedBudgetId;
  
  @override
  void initState() {
    super.initState();
    _selectedBudgetId = widget.initialBudgetId;
    
    // Si no hay budget ID seleccionado, intentar seleccionar el del mes actual o el primero de la lista
    if (_selectedBudgetId == null && widget.budgets.isNotEmpty) {
      final now = DateTime.now();
      final currentMonthYear = DateFormat('yyyy-MM').format(now);
      final currentMonthBudget = widget.budgets.firstWhereOrNull((b) => b.monthYear == currentMonthYear);

      if (currentMonthBudget != null) {
        _selectedBudgetId = currentMonthBudget.id;
      } else if (widget.budgets.isNotEmpty) {
        _selectedBudgetId = widget.budgets.first.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el presupuesto seleccionado
    final selectedBudget = widget.budgets.firstWhereOrNull((b) => b.id == _selectedBudgetId);
    
    // Calcular el progreso del presupuesto
    final budgetProgress = calculateBudgetProgress(selectedBudget, widget.movements, widget.categories);      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 4.0,
          color: Theme.of(context).cardColor,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
            title: Text('Presupuestos', style: Theme.of(context).textTheme.titleLarge),            subtitle: selectedBudget != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes: ${selectedBudget.monthYear}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Presupuesto: ${_formatCurrency(budgetProgress['totalBudgeted']!, selectedBudget.currency)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gastado: ${_formatCurrency(budgetProgress['totalSpent']!, selectedBudget.currency)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: budgetProgress['totalSpent']! > budgetProgress['totalBudgeted']! 
                            ? Colors.red 
                            : Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Selecciona un presupuesto para ver detalles',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,                  children: [
                    // Selector de Presupuesto
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Seleccionar Presupuesto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      value: _selectedBudgetId,
                      items: widget.budgets.map((budget) {
                        return DropdownMenuItem<String>(
                          value: budget.id,
                          child: Text(budget.monthYear, style: Theme.of(context).textTheme.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (budgetId) {
                        setState(() {
                          _selectedBudgetId = budgetId;
                          // Notificar al parent que el presupuesto ha cambiado
                          widget.onBudgetSelected(budgetId);
                        });
                      },
                      hint: widget.budgets.isEmpty ? 
                        Text('No hay presupuestos disponibles', style: Theme.of(context).textTheme.bodyMedium) : null,
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),

                    if (selectedBudget != null) ...[
                      // Detalles del presupuesto
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Presupuestado:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _formatCurrency(budgetProgress['totalBudgeted']!, selectedBudget.currency),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gastado:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _formatCurrency(budgetProgress['totalSpent']!, selectedBudget.currency),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: budgetProgress['totalSpent']! > budgetProgress['totalBudgeted']!
                                ? Colors.red
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Gráfico de distribución del gasto por tipo de presupuesto
                      Text(
                        'Distribución del Gasto por Tipo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),

                      Builder(
                        builder: (context) {
                          final expenseByType = calculateExpenseByBudgetType(selectedBudget, widget.movements, widget.categories);
                          final totalExpenseByType = expenseByType.values.fold(0.0, (sum, amount) => sum + amount);

                          return Column(
                            children: [                              if (totalExpenseByType > 0) ...[
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isMobile = constraints.maxWidth < 600;
                                    
                                    return Column(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: isMobile ? 1.3 : 1.5,
                                          child: PieChart(
                                            PieChartData(
                                              sections: buildBudgetPieChartSections(expenseByType),
                                              sectionsSpace: 2,
                                              centerSpaceRadius: isMobile ? 30 : 40,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            buildBudgetTypeLegendItem(context, 'Necesidades', expenseByType['Necesidades'] ?? 0, Colors.blue, selectedBudget.currency),
                                            buildBudgetTypeLegendItem(context, 'Deseos', expenseByType['Deseos'] ?? 0, Colors.orange, selectedBudget.currency),
                                            buildBudgetTypeLegendItem(context, 'Ahorros', expenseByType['Ahorros'] ?? 0, Colors.green, selectedBudget.currency),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ] else
                                AspectRatio(
                                  aspectRatio: 2.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                                            'No hay gastos categorizados por tipo de presupuesto en este período',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (budgetProgress['progressPercentage']! / 100).clamp(0.0, 1.0),
                        backgroundColor: Theme.of(context).dividerColor,
                        color: budgetProgress['progressPercentage']! > 100 ? 
                          Colors.red : Theme.of(context).colorScheme.primary,
                        minHeight: 10,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${budgetProgress['progressPercentage']!.toStringAsFixed(1)}% del presupuesto utilizado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ] else ...[
                      // Mensaje si no hay presupuesto seleccionado
                      Center(
                        child: Text(
                          'Selecciona un presupuesto para ver su progreso.',
                          style: Theme.of(context).textTheme.bodyMedium
                        )
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper para calcular el progreso del presupuesto
  Map<String, double> calculateBudgetProgress(Budget? selectedBudget, List<Movement> movements, List<Category> categories) {
    if (selectedBudget == null) {
      return {
        'totalBudgeted': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'progressPercentage': 0.0,
      };
    }

    double totalSpent = 0.0;

    // Obtener el rango de fechas del presupuesto seleccionado
    final budgetDate = DateFormat('yyyy-MM').parse(selectedBudget.monthYear);
    final startOfBudgetDate = DateTime(budgetDate.year, budgetDate.month, 1);
    final endOfBudgetDate = DateTime(budgetDate.year, budgetDate.month + 1, 0, 23, 59, 59);

    // Filtrar movimientos de gasto relevantes para el presupuesto seleccionado
    final expenseMovementsForBudget = movements.where((m) {
      final category = categories.firstWhereOrNull((cat) => cat.id == m.categoryId);
      // Asegurarse de que el movimiento sea de gasto y dentro del rango de fechas del presupuesto
      return category != null && category.type == 'expense' &&
             m.dateTime.isAfter(startOfBudgetDate.subtract(Duration(days: 1))) &&
             m.dateTime.isBefore(endOfBudgetDate.add(Duration(days: 1)));
    }).toList();

    for (var movement in expenseMovementsForBudget) {
      totalSpent += movement.amount;
    }

    double totalBudgeted = selectedBudget.totalBudgeted;
    double totalRemaining = totalBudgeted - totalSpent;
    double progressPercentage = (totalBudgeted > 0) ? (totalSpent / totalBudgeted) * 100 : 0.0;

    return {
      'totalBudgeted': totalBudgeted,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'progressPercentage': progressPercentage,
    };
  }

  // Helper para calcular gastos por tipo de presupuesto
  Map<String, double> calculateExpenseByBudgetType(Budget? selectedBudget, List<Movement> movements, List<Category> categories) {
    Map<String, double> expenseByType = {
      'Necesidades': 0.0,
      'Deseos': 0.0,
      'Ahorros': 0.0,
    };

    if (selectedBudget == null) {
      return expenseByType;
    }

    // Obtener el rango de fechas del presupuesto seleccionado
    final budgetDate = DateFormat('yyyy-MM').parse(selectedBudget.monthYear);
    final startOfBudgetDate = DateTime(budgetDate.year, budgetDate.month, 1);
    final endOfBudgetDate = DateTime(budgetDate.year, budgetDate.month + 1, 0, 23, 59, 59);

    // Filtrar solo movimientos de gasto dentro del rango de fechas del presupuesto
    final expenseMovements = movements.where((m) =>
      m.type == 'expense' &&
      m.dateTime.isAfter(startOfBudgetDate.subtract(Duration(days: 1))) &&
      m.dateTime.isBefore(endOfBudgetDate.add(Duration(days: 1)))
    );

    for (var movement in expenseMovements) {
      final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
      if (category != null) {
        switch (category.budgetCategory?.toLowerCase()) {
          case 'needs':
          case 'necesidades':
            expenseByType['Necesidades'] = (expenseByType['Necesidades'] ?? 0.0) + movement.amount;
            break;
          case 'wants':
          case 'deseos':
            expenseByType['Deseos'] = (expenseByType['Deseos'] ?? 0.0) + movement.amount;
            break;
          case 'savings':
          case 'ahorros':
            expenseByType['Ahorros'] = (expenseByType['Ahorros'] ?? 0.0) + movement.amount;
            break;
          default:
            break;
        }
      }
    }
    return expenseByType;
  }

  // Helper para construir las secciones del gráfico de presupuesto
  List<PieChartSectionData> buildBudgetPieChartSections(Map<String, double> expenseByType) {
    final totalExpense = expenseByType.values.fold(0.0, (sum, amount) => sum + amount);
    if (totalExpense == 0) return [];

    final Map<String, Color> typeColors = {
      'Necesidades': Colors.blue,
      'Deseos': Colors.orange,
      'Ahorros': Colors.green,
    };

    return expenseByType.entries.map((entry) {
      final type = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalExpense) * 100;

      // Evitar secciones con porcentaje 0 para no saturar el gráfico
      if (percentage < 1.0 && percentage > 0) {
        return PieChartSectionData(
          color: typeColors[type] ?? Colors.grey,
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
          color: typeColors[type] ?? Colors.grey,
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
        return PieChartSectionData(value: 0);
      }
    }).where((section) => section.value > 0).toList();
  }

  // Helper para construir el elemento de leyenda por tipo de presupuesto
  Widget buildBudgetTypeLegendItem(BuildContext context, String type, double amount, Color color, String currencyCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
            margin: EdgeInsets.only(right: 8),
          ),
          Expanded(
            child: Text(
              '$type: ${_formatCurrency(amount, currencyCode)}',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper para formatear montos de moneda
  String _formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      locale: 'es_CO',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  // Helper para obtener el símbolo de moneda
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'COP':
        return '\$';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return currencyCode;
    }
  }
}
