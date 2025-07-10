import 'package:flutter/material.dart';
import 'package:mis_finanza/models/budget.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';

class DashboardBudgetSummaryUnified extends StatelessWidget {
  final List<Budget> budgets;
  final List<Movement> movements;
  final List<Category> categories;
  final String displayCurrency;
  final String? initialBudgetId;
  final Function(String?)? onBudgetSelected;

  const DashboardBudgetSummaryUnified({
    super.key,
    required this.budgets,
    required this.movements,
    required this.categories,
    this.displayCurrency = 'COP',
    this.initialBudgetId,
    this.onBudgetSelected,
  });

  String _formatCurrency(double value, String currency) {
    final format = NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0);
    return '${_getCurrencySymbol(currency)}${format.format(value)}';
  }
  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$24';
      case 'EUR':
        return '€';
      case 'COP':
      default:
        return '\$';
    }
  }

  Color _getIconColor(BuildContext context) {
    // Detectar modo alto contraste
    final isHighContrast = MediaQuery.of(context).highContrast;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isHighContrast) {
      // En modo alto contraste, usar colores que garanticen máximo contraste
      return isDarkMode ? Colors.white : Colors.black;
    } else {
      // En modo normal, usar el color primario del tema
      return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,        child: ExpansionTile(
          leading: Icon(
            Icons.account_balance_wallet, 
            color: _getIconColor(context),
          ),
          title: Text('Presupuestos', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('No hay presupuestos registrados', style: Theme.of(context).textTheme.bodyMedium),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Agrega presupuestos para visualizar el resumen y hacer seguimiento detallado.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Selección de presupuesto: priorizar el del mes actual
    final now = DateTime.now();
    final currentMonthYear = DateFormat('yyyy-MM').format(now);
    Budget? selectedBudget;
    try {
      selectedBudget = budgets.firstWhere((b) => b.monthYear == currentMonthYear);
    } catch (_) {
      if (initialBudgetId != null) {
        try {
          selectedBudget = budgets.firstWhere((b) => b.id == initialBudgetId);
        } catch (_) {
          selectedBudget = budgets.first;
        }
      } else {
        selectedBudget = budgets.first;
      }
    }

    // Calcular gastos realizados en el periodo del presupuesto
    final budgetDate = DateFormat('yyyy-MM').parse(selectedBudget.monthYear);
    final startOfBudgetDate = DateTime(budgetDate.year, budgetDate.month, 1);
    final endOfBudgetDate = DateTime(budgetDate.year, budgetDate.month + 1, 0, 23, 59, 59);
    final expenseMovements = movements.where((m) {
      return m.type == 'expense' &&
        m.dateTime.isAfter(startOfBudgetDate.subtract(const Duration(days: 1))) &&
        m.dateTime.isBefore(endOfBudgetDate.add(const Duration(days: 1)));
    }).toList();
    final totalSpent = expenseMovements.fold(0.0, (sum, m) => sum + m.amount.abs());
    final totalBudgeted = selectedBudget.totalBudgeted;
    final percentUsed = totalBudgeted > 0 ? (totalSpent / totalBudgeted).clamp(0.0, 1.0) : 0.0;

    // Calcular progreso por tipo
    final needsBudget = selectedBudget.totalBudgeted * (selectedBudget.needsPercentage / 100);
    final wantsBudget = selectedBudget.totalBudgeted * (selectedBudget.wantsPercentage / 100);
    final savingsBudget = selectedBudget.totalBudgeted * (selectedBudget.savingsPercentage / 100);

    double needsSpent = 0.0;
    double wantsSpent = 0.0;
    double savingsSpent = 0.0;

    for (final m in expenseMovements) {
      final cat = categories.firstWhere(
        (c) => c.id == m.categoryId,
        orElse: () => Category(id: '', name: '', type: '', userId: ''),
      );
      // Aquí puedes ajustar la lógica según cómo se asignan las categorías a cada tipo
      if (cat.type == 'needs') {
        needsSpent += m.amount.abs();
      } else if (cat.type == 'wants') {
        wantsSpent += m.amount.abs();
      } else if (cat.type == 'savings') {
        savingsSpent += m.amount.abs();
      }
    }

    double needsProgress = needsBudget > 0 ? (needsSpent / needsBudget).clamp(0.0, 1.0) : 0.0;
    double wantsProgress = wantsBudget > 0 ? (wantsSpent / wantsBudget).clamp(0.0, 1.0) : 0.0;
    double savingsProgress = savingsBudget > 0 ? (savingsSpent / savingsBudget).clamp(0.0, 1.0) : 0.0;

    Color progressColor;
    if (percentUsed < 0.7) {
      progressColor = Colors.green;
    } else if (percentUsed < 0.9) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,      child: ExpansionTile(
        leading: Icon(
          Icons.account_balance_wallet, 
          color: _getIconColor(context),
        ),
        title: Text('Resumen de Presupuesto', style: Theme.of(context).textTheme.titleLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presupuesto: ${_formatCurrency(totalBudgeted, selectedBudget.currency)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Gastado: ${_formatCurrency(totalSpent, selectedBudget.currency)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progreso general
                LinearProgressIndicator(
                  value: percentUsed,
                  minHeight: 12,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Disponible', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalBudgeted - totalSpent, selectedBudget.currency),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: progressColor)),
                  ],
                ),
                const SizedBox(height: 24),
                // Progreso por tipo
                Text('Progreso por tipo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildTypeProgress(context, 'Necesidades', needsProgress, needsSpent, needsBudget, selectedBudget.currency, Colors.blue),
                const SizedBox(height: 8),
                _buildTypeProgress(context, 'Deseos', wantsProgress, wantsSpent, wantsBudget, selectedBudget.currency, Colors.orange),
                const SizedBox(height: 8),
                _buildTypeProgress(context, 'Ahorro', savingsProgress, savingsSpent, savingsBudget, selectedBudget.currency, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeProgress(BuildContext context, String label, double progress, double spent, double budget, String currency, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text('${_formatCurrency(spent, currency)} / ${_formatCurrency(budget, currency)}', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
