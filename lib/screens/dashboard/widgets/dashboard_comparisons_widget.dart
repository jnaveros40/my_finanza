// lib/screens/dashboard/widgets/dashboard_comparisons_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardComparisonsWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;
  final List<Category> categories;

  const DashboardComparisonsWidget({
    super.key,
    required this.accounts,
    required this.movements,
    required this.categories,
  });

  @override
  _DashboardComparisonsWidgetState createState() => _DashboardComparisonsWidgetState();
}

class _DashboardComparisonsWidgetState extends State<DashboardComparisonsWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  String _selectedComparisonType = 'periods'; // periods, categories, accounts
  String _selectedMetric = 'expenses'; // expenses, income, balance
  String _selectedPeriod = 'monthly'; // monthly, weekly
  int _periodsToCompare = 3;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

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
            Icons.compare_arrows_rounded,
            color: Colors.purple,
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Comparaciones Financieras',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getSubtitleText(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildControls(),
                SizedBox(height: 20),
                _buildComparisonChart(),
                SizedBox(height: 16),
                _buildComparisonSummary(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitleText() {
    switch (_selectedComparisonType) {
      case 'periods':
        return 'Comparando últimos $_periodsToCompare ${_selectedPeriod == "monthly" ? "meses" : "semanas"}';
      case 'categories':
        return 'Comparando por categorías';
      case 'accounts':
        return 'Comparando por cuentas';
      default:
        return 'Análisis comparativo';
    }
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Tipo de comparación
        Row(
          children: [
            Text(
              'Comparar por:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedComparisonType,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'periods', child: Text('Períodos')),
                  DropdownMenuItem(value: 'categories', child: Text('Categorías')),
                  DropdownMenuItem(value: 'accounts', child: Text('Cuentas')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedComparisonType = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Métrica a comparar
        Row(
          children: [
            Text(
              'Métrica:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedMetric,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'expenses', child: Text('Gastos')),
                  DropdownMenuItem(value: 'income', child: Text('Ingresos')),
                  DropdownMenuItem(value: 'balance', child: Text('Balance')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMetric = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (_selectedComparisonType == 'periods') ...[
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Período:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                    DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Cantidad:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _periodsToCompare.toDouble(),
                  min: 2,
                  max: 12,
                  divisions: 10,
                  label: '$_periodsToCompare',
                  onChanged: (value) {
                    setState(() {
                      _periodsToCompare = value.round();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildComparisonChart() {
    final comparisonData = _getComparisonData();
    
    if (comparisonData.isEmpty) {
      return _buildNoDataWidget();
    }

    return Container(
      height: 300,
      child: _selectedComparisonType == 'periods' 
          ? _buildLineChart(comparisonData)
          : _buildBarChart(comparisonData),
    );
  }

  Widget _buildLineChart(List<ComparisonData> data) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.length) {
                  return Text(
                    data[value.toInt()].label,
                    style: TextStyle(fontSize: 10),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => 
              FlSpot(e.key.toDouble(), e.value.value)
            ).toList(),
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<ComparisonData> data) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.length) {
                  return Text(
                    data[value.toInt()].label,
                    style: TextStyle(fontSize: 8),
                    maxLines: 2,
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: data.asMap().entries.map((e) => 
          BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: Colors.purple,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildComparisonSummary() {
    final comparisonData = _getComparisonData();
    
    if (comparisonData.isEmpty) return SizedBox.shrink();

    final maxValue = comparisonData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = comparisonData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final avgValue = comparisonData.map((e) => e.value).reduce((a, b) => a + b) / comparisonData.length;
    
    final maxItem = comparisonData.firstWhere((e) => e.value == maxValue);
    final minItem = comparisonData.firstWhere((e) => e.value == minValue);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen Comparativo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Máximo',
                  '${maxItem.label}',
                  _formatCurrency(maxValue),
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Mínimo',
                  '${minItem.label}',
                  _formatCurrency(minValue),
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildSummaryItem(
            'Promedio',
            '',
            _formatCurrency(avgValue),
            Colors.blue,
            Icons.analytics,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String subtitle, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<ComparisonData> _getComparisonData() {
    switch (_selectedComparisonType) {
      case 'periods':
        return _getPeriodComparisonData();
      case 'categories':
        return _getCategoryComparisonData();
      case 'accounts':
        return _getAccountComparisonData();
      default:
        return [];
    }
  }

  List<ComparisonData> _getPeriodComparisonData() {
    List<ComparisonData> data = [];
    final now = DateTime.now();
    
    for (int i = _periodsToCompare - 1; i >= 0; i--) {
      DateTime periodStart, periodEnd;
      String label;
      
      if (_selectedPeriod == 'monthly') {
        periodStart = DateTime(now.year, now.month - i, 1);
        periodEnd = DateTime(now.year, now.month - i + 1, 0);
        label = DateFormat('MMM').format(periodStart);
      } else {
        periodStart = now.subtract(Duration(days: (i + 1) * 7));
        periodEnd = now.subtract(Duration(days: i * 7));
        label = 'S${i + 1}';
      }
      
      final movements = widget.movements.where((m) =>
        m.dateTime.isAfter(periodStart) && m.dateTime.isBefore(periodEnd)
      ).toList();
      
      double value = 0;
      switch (_selectedMetric) {
        case 'expenses':
          value = movements.where((m) => m.type == 'expense').fold(0.0, (sum, m) => sum + m.amount);
          break;
        case 'income':
          value = movements.where((m) => m.type == 'income').fold(0.0, (sum, m) => sum + m.amount);
          break;
        case 'balance':
          final income = movements.where((m) => m.type == 'income').fold(0.0, (sum, m) => sum + m.amount);
          final expenses = movements.where((m) => m.type == 'expense').fold(0.0, (sum, m) => sum + m.amount);
          value = income - expenses;
          break;
      }
      
      data.add(ComparisonData(label: label, value: value));
    }
    
    return data;
  }

  List<ComparisonData> _getCategoryComparisonData() {
    List<ComparisonData> data = [];
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    
    final currentMonthMovements = widget.movements.where((m) =>
      m.dateTime.isAfter(currentMonth) && m.dateTime.isBefore(nextMonth)
    ).toList();
    
    final categoryGroups = <String, double>{};
    
    for (final movement in currentMonthMovements) {
      if ((_selectedMetric == 'expenses' && movement.type == 'expense') ||
          (_selectedMetric == 'income' && movement.type == 'income')) {
        categoryGroups[movement.categoryId] = 
          (categoryGroups[movement.categoryId] ?? 0) + movement.amount;
      }
    }
    
    if (_selectedMetric == 'balance') {
      final incomeByCategory = <String, double>{};
      final expensesByCategory = <String, double>{};
      
      for (final movement in currentMonthMovements) {
        if (movement.type == 'income') {
          incomeByCategory[movement.categoryId] = 
            (incomeByCategory[movement.categoryId] ?? 0) + movement.amount;
        } else if (movement.type == 'expense') {
          expensesByCategory[movement.categoryId] = 
            (expensesByCategory[movement.categoryId] ?? 0) + movement.amount;
        }
      }
      
      final allCategories = {...incomeByCategory.keys, ...expensesByCategory.keys};
      for (final categoryId in allCategories) {
        final income = incomeByCategory[categoryId] ?? 0;
        final expenses = expensesByCategory[categoryId] ?? 0;
        categoryGroups[categoryId] = income - expenses;
      }
    }
    
    // Ordenar por valor descendente y tomar las top 5
    final sortedEntries = categoryGroups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedEntries.take(5)) {
      final category = widget.categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(userId: '', name: 'Sin categoría', type: 'expense'),
      );
      
      data.add(ComparisonData(
        label: category.name,
        value: entry.value,
      ));
    }
    
    return data;
  }

  List<ComparisonData> _getAccountComparisonData() {
    List<ComparisonData> data = [];
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    
    final currentMonthMovements = widget.movements.where((m) =>
      m.dateTime.isAfter(currentMonth) && m.dateTime.isBefore(nextMonth)
    ).toList();
    
    final accountGroups = <String, double>{};
    
    for (final movement in currentMonthMovements) {
      if ((_selectedMetric == 'expenses' && movement.type == 'expense') ||
          (_selectedMetric == 'income' && movement.type == 'income')) {
        accountGroups[movement.accountId] = 
          (accountGroups[movement.accountId] ?? 0) + movement.amount;
      }
    }
    
    if (_selectedMetric == 'balance') {
      final incomeByAccount = <String, double>{};
      final expensesByAccount = <String, double>{};
      
      for (final movement in currentMonthMovements) {
        if (movement.type == 'income') {
          incomeByAccount[movement.accountId] = 
            (incomeByAccount[movement.accountId] ?? 0) + movement.amount;
        } else if (movement.type == 'expense') {
          expensesByAccount[movement.accountId] = 
            (expensesByAccount[movement.accountId] ?? 0) + movement.amount;
        }
      }
      
      final allAccounts = {...incomeByAccount.keys, ...expensesByAccount.keys};
      for (final accountId in allAccounts) {
        final income = incomeByAccount[accountId] ?? 0;
        final expenses = expensesByAccount[accountId] ?? 0;
        accountGroups[accountId] = income - expenses;
      }
    }
    
    for (final entry in accountGroups.entries) {
      final account = widget.accounts.firstWhere(
        (a) => a.id == entry.key,
        orElse: () => Account(
          userId: '',
          name: 'Sin cuenta',
          type: 'checking',
          currency: 'COP',
          initialBalance: 0,
          currentBalance: 0,
          order: 0,
        ),
      );
      
      data.add(ComparisonData(
        label: account.name,
        value: entry.value,
      ));
    }
    
    return data;
  }

  Widget _buildNoDataWidget() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            SizedBox(height: 12),
            Text(
              'Sin datos para comparar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega movimientos para ver comparaciones',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

// Clase auxiliar para los datos de comparación
class ComparisonData {
  final String label;
  final double value;

  ComparisonData({
    required this.label,
    required this.value,
  });
}
