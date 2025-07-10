// lib/screens/dashboard/widgets/dashboard_cash_flow_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardCashFlowWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;
  final List<Category> categories;

  const DashboardCashFlowWidget({
    super.key,
    required this.accounts,
    required this.movements,
    required this.categories,
  });

  @override
  _DashboardCashFlowWidgetState createState() => _DashboardCashFlowWidgetState();
}

class _DashboardCashFlowWidgetState extends State<DashboardCashFlowWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _selectedPeriod = '6_months'; // 3_months, 6_months, 12_months

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final cashFlowData = _calculateCashFlow();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCashFlowColor(cashFlowData.currentNetFlow).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: _getCashFlowColor(cashFlowData.currentNetFlow),
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Flujo de Efectivo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              cashFlowData.currentNetFlow >= 0 
                  ? Icons.arrow_upward_rounded 
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: _getCashFlowColor(cashFlowData.currentNetFlow),
            ),
            SizedBox(width: 4),
            Text(
              '${cashFlowData.currentNetFlow >= 0 ? '+' : ''}${_formatCurrency(cashFlowData.currentNetFlow)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getCashFlowColor(cashFlowData.currentNetFlow),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'este mes',
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
                _buildPeriodSelector(),
                SizedBox(height: 16),
                _buildCashFlowSummary(cashFlowData),
                SizedBox(height: 16),
                _buildCashFlowChart(cashFlowData),
                SizedBox(height: 16),
                _buildCashFlowInsights(cashFlowData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('3_months', '3M'),
          _buildPeriodButton('6_months', '6M'),
          _buildPeriodButton('12_months', '12M'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowSummary(CashFlowData data) {
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
                  'Ingresos Promedio',
                  data.averageIncome,
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Gastos Promedio',
                  data.averageExpense,
                  Icons.trending_down_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          _buildSummaryItem(
            'Flujo Neto Promedio',
            data.averageNetFlow,
            data.averageNetFlow >= 0 
                ? Icons.savings_rounded 
                : Icons.warning_rounded,
            _getCashFlowColor(data.averageNetFlow),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, IconData icon, Color color) {
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
          _formatCurrency(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCashFlowChart(CashFlowData data) {
    return Container(
      height: 200,
      child: LineChart(        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: data.maxValue > 0 ? data.maxValue / 5 : 1000,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.monthLabels.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        data.monthLabels[value.toInt()],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: data.maxValue > 0 ? data.maxValue / 3 : 1000,
                reservedSize: 60,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    _formatCompactCurrency(value),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          minX: 0,
          maxX: data.monthLabels.length.toDouble() - 1,
          minY: data.minValue,
          maxY: data.maxValue,
          lineBarsData: [
            // Línea de ingresos
            LineChartBarData(
              spots: data.incomeSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
            // Línea de gastos
            LineChartBarData(
              spots: data.expenseSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.1),
              ),
            ),            // Línea de flujo neto
            LineChartBarData(
              spots: data.netFlowSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowInsights(CashFlowData data) {
    final insights = _generateInsights(data);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis de Flujo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...insights.map((insight) => Padding(
          padding: EdgeInsets.only(bottom: 8),
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

  CashFlowData _calculateCashFlow() {
    final now = DateTime.now();
    final months = _getMonthsCount();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    
    List<String> monthLabels = [];
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    List<FlSpot> netFlowSpots = [];
    
    double totalIncome = 0;
    double totalExpense = 0;
    double maxValue = 0;
    double minValue = 0;
    
    for (int i = 0; i < months; i++) {
      final monthStart = DateTime(startDate.year, startDate.month + i, 1);
      final monthEnd = DateTime(startDate.year, startDate.month + i + 1, 0);
      
      final monthMovements = widget.movements.where((m) =>
          m.dateTime.isAfter(monthStart.subtract(Duration(days: 1))) &&
          m.dateTime.isBefore(monthEnd.add(Duration(days: 1)))).toList();
      
      final monthIncome = monthMovements
          .where((m) => m.type == 'income')
          .fold(0.0, (sum, m) => sum + m.amount);
      
      final monthExpense = monthMovements
          .where((m) => m.type == 'expense')
          .fold(0.0, (sum, m) => sum + m.amount);
      
      final netFlow = monthIncome - monthExpense;
      
      totalIncome += monthIncome;
      totalExpense += monthExpense;
      
      maxValue = [maxValue, monthIncome, monthExpense].reduce((a, b) => a > b ? a : b);
      minValue = [minValue, netFlow].reduce((a, b) => a < b ? a : b);
      
      monthLabels.add(DateFormat('MMM', 'es').format(monthStart));
      incomeSpots.add(FlSpot(i.toDouble(), monthIncome));
      expenseSpots.add(FlSpot(i.toDouble(), monthExpense));
      netFlowSpots.add(FlSpot(i.toDouble(), netFlow));
    }
    
    // Calcular flujo de efectivo del mes actual
    final currentMonth = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    
    final currentMonthMovements = widget.movements.where((m) =>
        m.dateTime.isAfter(currentMonth.subtract(Duration(days: 1))) &&
        m.dateTime.isBefore(currentMonthEnd.add(Duration(days: 1)))).toList();
    
    final currentIncome = currentMonthMovements
        .where((m) => m.type == 'income')
        .fold(0.0, (sum, m) => sum + m.amount);
    
    final currentExpense = currentMonthMovements
        .where((m) => m.type == 'expense')
        .fold(0.0, (sum, m) => sum + m.amount);
    
    return CashFlowData(
      monthLabels: monthLabels,
      incomeSpots: incomeSpots,
      expenseSpots: expenseSpots,
      netFlowSpots: netFlowSpots,
      averageIncome: totalIncome / months,
      averageExpense: totalExpense / months,
      averageNetFlow: (totalIncome - totalExpense) / months,
      currentNetFlow: currentIncome - currentExpense,
      maxValue: maxValue * 1.1, // 10% padding
      minValue: minValue < 0 ? minValue * 1.1 : 0,
    );
  }

  int _getMonthsCount() {
    switch (_selectedPeriod) {
      case '3_months':
        return 3;
      case '6_months':
        return 6;
      case '12_months':
        return 12;
      default:
        return 6;
    }
  }

  List<CashFlowInsight> _generateInsights(CashFlowData data) {
    List<CashFlowInsight> insights = [];
    
    // Tendencia del flujo neto
    if (data.netFlowSpots.length >= 2) {
      final firstFlow = data.netFlowSpots.first.y;
      final lastFlow = data.netFlowSpots.last.y;
      
      if (lastFlow > firstFlow) {
        insights.add(CashFlowInsight(
          message: 'Tu flujo de efectivo ha mejorado en los últimos meses',
          icon: Icons.trending_up_rounded,
          color: Colors.green,
        ));
      } else if (lastFlow < firstFlow) {
        insights.add(CashFlowInsight(
          message: 'Tu flujo de efectivo ha empeorado recientemente',
          icon: Icons.trending_down_rounded,
          color: Colors.red,
        ));
      }
    }
    
    // Consistencia de ingresos
    if (data.incomeSpots.isNotEmpty) {
      final incomeValues = data.incomeSpots.map((spot) => spot.y).toList();
      final variance = _calculateVariance(incomeValues);
      final avgIncome = incomeValues.reduce((a, b) => a + b) / incomeValues.length;
      
      if (variance / avgIncome < 0.2) {
        insights.add(CashFlowInsight(
          message: 'Tus ingresos son consistentes mes a mes',
          icon: Icons.trending_flat_rounded,
          color: Colors.blue,
        ));
      }
    }
    
    // Recomendación de ahorro
    if (data.averageNetFlow > 0) {
      final savingsRate = (data.averageNetFlow / data.averageIncome) * 100;
      if (savingsRate < 10) {
        insights.add(CashFlowInsight(
          message: 'Considera aumentar tu tasa de ahorro actual (${savingsRate.toStringAsFixed(0)}%)',
          icon: Icons.savings_rounded,
          color: Colors.orange,
        ));
      } else if (savingsRate >= 20) {
        insights.add(CashFlowInsight(
          message: '¡Excelente! Estás ahorrando ${savingsRate.toStringAsFixed(0)}% de tus ingresos',
          icon: Icons.star_rounded,
          color: Colors.green,
        ));
      }
    }
    
    return insights;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    
    return variance;
  }

  Color _getCashFlowColor(double netFlow) {
    if (netFlow > 0) return Colors.green;
    if (netFlow < 0) return Colors.red;
    return Colors.grey;
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

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }
}

// Clases auxiliares
class CashFlowData {
  final List<String> monthLabels;
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final List<FlSpot> netFlowSpots;
  final double averageIncome;
  final double averageExpense;
  final double averageNetFlow;
  final double currentNetFlow;
  final double maxValue;
  final double minValue;

  CashFlowData({
    required this.monthLabels,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.netFlowSpots,
    required this.averageIncome,
    required this.averageExpense,
    required this.averageNetFlow,
    required this.currentNetFlow,
    required this.maxValue,
    required this.minValue,
  });
}

class CashFlowInsight {
  final String message;
  final IconData icon;
  final Color color;

  CashFlowInsight({
    required this.message,
    required this.icon,
    required this.color,
  });
}
