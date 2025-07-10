// lib/screens/dashboard/widgets/dashboard_recurring_expenses_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';

class DashboardRecurringExpensesWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;
  final List<Category> categories;

  const DashboardRecurringExpensesWidget({
    super.key,
    required this.accounts,
    required this.movements,
    required this.categories,
  });

  @override
  _DashboardRecurringExpensesWidgetState createState() => _DashboardRecurringExpensesWidgetState();
}

class _DashboardRecurringExpensesWidgetState extends State<DashboardRecurringExpensesWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _selectedView = 'all'; // all, subscriptions, bills

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final recurringData = _analyzeRecurringExpenses();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.repeat_rounded,
            color: Colors.purple,
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Gastos Recurrentes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: Colors.purple,
            ),
            SizedBox(width: 4),
            Text(
              '${recurringData.length} patrones detectados',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text(
              _formatCurrency(_getTotalRecurringAmount(recurringData)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildViewSelector(),
                SizedBox(height: 16),
                _buildRecurringSummary(recurringData),
                SizedBox(height: 16),
                _buildRecurringList(recurringData),
                SizedBox(height: 16),
                _buildRecurringInsights(recurringData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildViewButton('all', 'Todos'),
          _buildViewButton('subscriptions', 'Suscripciones'),
          _buildViewButton('bills', 'Servicios'),
        ],
      ),
    );
  }

  Widget _buildViewButton(String view, String label) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = view;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringSummary(List<RecurringExpense> data) {
    final filteredData = _filterDataByView(data);
    final totalAmount = filteredData.fold(0.0, (sum, item) => sum + item.averageAmount);
    final subscriptions = data.where((item) => item.type == RecurringType.subscription).length;
    final bills = data.where((item) => item.type == RecurringType.bill).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Mensual',
                  totalAmount,
                  Icons.account_balance_wallet_rounded,
                  Colors.purple,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Suscripciones',
                  subscriptions.toDouble(),
                  Icons.subscriptions_rounded,
                  Colors.blue,
                  isCount: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          _buildSummaryItem(
            'Servicios',
            bills.toDouble(),
            Icons.receipt_long_rounded,
            Colors.orange,
            isCount: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, IconData icon, Color color, {bool isCount = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          isCount ? value.toInt().toString() : _formatCurrency(value),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecurringList(List<RecurringExpense> data) {
    final filteredData = _filterDataByView(data);

    if (filteredData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 12),
            Text(
              'No se encontraron gastos recurrentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gastos Detectados',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...filteredData.map((expense) => _buildRecurringCard(expense)).toList(),
      ],
    );
  }

  Widget _buildRecurringCard(RecurringExpense expense) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTypeColor(expense.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(expense.type).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(expense.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(expense.type),
                  color: _getTypeColor(expense.type),
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      expense.categoryName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(expense.averageAmount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(expense.type),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${expense.frequency.name}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: 4),
              Text(
                '${expense.occurrences} transacciones detectadas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Spacer(),
              if (expense.nextExpectedDate != null) ...[
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Colors.orange,
                ),
                SizedBox(width: 4),
                Text(
                  'Próximo: ${DateFormat('dd/MM').format(expense.nextExpectedDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringInsights(List<RecurringExpense> data) {
    final insights = _generateRecurringInsights(data);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...insights.map((insight) => Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: insight.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: insight.color.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                insight.icon,
                size: 16,
                color: insight.color,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  List<RecurringExpense> _analyzeRecurringExpenses() {
    final Map<String, List<Movement>> groupedMovements = {};
    
    // Agrupar movimientos por descripción similar y categoría
    for (final movement in widget.movements) {
      if (movement.type == 'expense') {
        final key = '${movement.description.toLowerCase().trim()}_${movement.categoryId}';
        groupedMovements.putIfAbsent(key, () => []).add(movement);
      }
    }
    
    List<RecurringExpense> recurringExpenses = [];
    
    for (final entry in groupedMovements.entries) {
      final movements = entry.value;
      if (movements.length >= 3) { // Al menos 3 ocurrencias para considerar recurrente
        movements.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        
        final intervals = <int>[];
        for (int i = 1; i < movements.length; i++) {
          final days = movements[i].dateTime.difference(movements[i-1].dateTime).inDays;
          intervals.add(days);
        }
        
        final averageInterval = intervals.reduce((a, b) => a + b) / intervals.length;
        final intervalVariance = _calculateVariance(intervals.map((e) => e.toDouble()).toList());
        
        // Considerar recurrente si la varianza es baja (consistencia)
        if (intervalVariance < (averageInterval * 0.3)) {
          final averageAmount = movements.map((m) => m.amount).reduce((a, b) => a + b) / movements.length;
          final category = widget.categories.firstWhere((c) => c.id == movements.first.categoryId, orElse: () => Category(userId: '', name: 'Sin categoría', type: 'expense'));
          
          final frequency = _determineFrequency(averageInterval);
          final type = _determineRecurringType(movements.first.description, category.name);
          
          DateTime? nextExpectedDate;
          if (movements.isNotEmpty) {
            nextExpectedDate = movements.last.dateTime.add(Duration(days: averageInterval.round()));
          }
          
          recurringExpenses.add(RecurringExpense(
            description: movements.first.description,
            categoryName: category.name,
            averageAmount: averageAmount,
            frequency: frequency,
            type: type,
            occurrences: movements.length,
            lastOccurrence: movements.last.dateTime,
            nextExpectedDate: nextExpectedDate,
            movements: movements,
          ));
        }
      }
    }
    
    // Ordenar por monto promedio descendente
    recurringExpenses.sort((a, b) => b.averageAmount.compareTo(a.averageAmount));
    
    return recurringExpenses;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    
    return variance;
  }

  RecurringFrequency _determineFrequency(double averageInterval) {
    if (averageInterval <= 10) return RecurringFrequency.weekly;
    if (averageInterval <= 35) return RecurringFrequency.monthly;
    if (averageInterval <= 100) return RecurringFrequency.quarterly;
    return RecurringFrequency.yearly;
  }

  RecurringType _determineRecurringType(String description, String categoryName) {
    final lowerDescription = description.toLowerCase();
    final lowerCategory = categoryName.toLowerCase();
    
    // Patrones para suscripciones
    final subscriptionPatterns = ['netflix', 'spotify', 'amazon', 'youtube', 'disney', 'apple', 'google', 'microsoft', 'adobe', 'zoom', 'dropbox'];
    if (subscriptionPatterns.any((pattern) => lowerDescription.contains(pattern))) {
      return RecurringType.subscription;
    }
    
    // Patrones para servicios
    final billPatterns = ['agua', 'luz', 'gas', 'internet', 'telefono', 'cable', 'seguro', 'renta', 'alquiler'];
    if (billPatterns.any((pattern) => lowerDescription.contains(pattern) || lowerCategory.contains(pattern))) {
      return RecurringType.bill;
    }
    
    return RecurringType.other;
  }

  List<RecurringExpense> _filterDataByView(List<RecurringExpense> data) {
    switch (_selectedView) {
      case 'subscriptions':
        return data.where((item) => item.type == RecurringType.subscription).toList();
      case 'bills':
        return data.where((item) => item.type == RecurringType.bill).toList();
      default:
        return data;
    }
  }

  double _getTotalRecurringAmount(List<RecurringExpense> data) {
    return data.fold(0.0, (sum, item) => sum + item.averageAmount);
  }
  List<RecurringInsight> _generateRecurringInsights(List<RecurringExpense> data) {
    List<RecurringInsight> insights = [];
    
    final totalRecurring = _getTotalRecurringAmount(data);
    final subscriptions = data.where((item) => item.type == RecurringType.subscription).toList();
    
    // Insight sobre total de gastos recurrentes
    if (totalRecurring > 0) {
      insights.add(RecurringInsight(
        message: 'Gastas ${_formatCurrency(totalRecurring)} mensualmente en gastos recurrentes',
        icon: Icons.info_rounded,
        color: Colors.blue,
      ));
    }
    
    // Insight sobre suscripciones
    if (subscriptions.isNotEmpty) {
      final subscriptionTotal = subscriptions.fold(0.0, (sum, item) => sum + item.averageAmount);
      insights.add(RecurringInsight(
        message: '${subscriptions.length} suscripciones activas: ${_formatCurrency(subscriptionTotal)}/mes',
        icon: Icons.subscriptions_rounded,
        color: Colors.purple,
      ));
    }
    
    // Insight sobre próximos pagos
    final upcomingPayments = data.where((item) => 
        item.nextExpectedDate != null && 
        item.nextExpectedDate!.difference(DateTime.now()).inDays <= 7).toList();
    
    if (upcomingPayments.isNotEmpty) {
      insights.add(RecurringInsight(
        message: '${upcomingPayments.length} pagos recurrentes próximos esta semana',
        icon: Icons.warning_rounded,
        color: Colors.orange,
      ));
    }
    
    return insights;
  }

  Color _getTypeColor(RecurringType type) {
    switch (type) {
      case RecurringType.subscription:
        return Colors.purple;
      case RecurringType.bill:
        return Colors.orange;
      case RecurringType.other:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(RecurringType type) {
    switch (type) {
      case RecurringType.subscription:
        return Icons.subscriptions_rounded;
      case RecurringType.bill:
        return Icons.receipt_long_rounded;
      case RecurringType.other:
        return Icons.repeat_rounded;
    }
  }

  Widget _buildErrorCard(String error) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

// Clases auxiliares
enum RecurringFrequency { weekly, monthly, quarterly, yearly }

enum RecurringType { subscription, bill, other }

class RecurringExpense {
  final String description;
  final String categoryName;
  final double averageAmount;
  final RecurringFrequency frequency;
  final RecurringType type;
  final int occurrences;
  final DateTime lastOccurrence;
  final DateTime? nextExpectedDate;
  final List<Movement> movements;

  RecurringExpense({
    required this.description,
    required this.categoryName,
    required this.averageAmount,
    required this.frequency,
    required this.type,
    required this.occurrences,
    required this.lastOccurrence,
    this.nextExpectedDate,
    required this.movements,
  });
}

class RecurringInsight {
  final String message;
  final IconData icon;
  final Color color;

  RecurringInsight({
    required this.message,
    required this.icon,
    required this.color,
  });
}
