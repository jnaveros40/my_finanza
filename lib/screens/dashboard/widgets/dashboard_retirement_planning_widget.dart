// lib/screens/dashboard/widgets/dashboard_retirement_planning_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class DashboardRetirementPlanningWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;

  const DashboardRetirementPlanningWidget({
    super.key,
    required this.accounts,
    required this.movements,
  });

  @override
  _DashboardRetirementPlanningWidgetState createState() => _DashboardRetirementPlanningWidgetState();
}

class _DashboardRetirementPlanningWidgetState extends State<DashboardRetirementPlanningWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _targetRetirementAge = 65;
  double _monthlyRetirementGoal = 3000000; // 3M COP
  double _expectedInflation = 3.0; // 3% anual
  double _expectedReturn = 7.0; // 7% anual

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final retirementData = _calculateRetirementProjection();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getRetirementColor(retirementData.feasibilityScore).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.elderly_rounded,
            color: _getRetirementColor(retirementData.feasibilityScore),
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Planificación de Jubilación',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 14,
              color: _getRetirementColor(retirementData.feasibilityScore),
            ),
            SizedBox(width: 4),
            Text(
              '${retirementData.feasibilityScore.toStringAsFixed(0)}% factible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getRetirementColor(retirementData.feasibilityScore),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${retirementData.yearsToRetirement} años restantes',
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
                _buildRetirementSettings(),
                SizedBox(height: 16),
                _buildRetirementSummary(retirementData),
                SizedBox(height: 16),
                _buildRetirementProjectionChart(retirementData),
                SizedBox(height: 16),
                _buildRetirementRecommendations(retirementData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementSettings() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edad de jubilación: $_targetRetirementAge años',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Slider(
                      value: _targetRetirementAge.toDouble(),
                      min: 55,
                      max: 75,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          _targetRetirementAge = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingreso mensual deseado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      initialValue: _formatNumber(_monthlyRetirementGoal),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value.replaceAll(',', ''));
                        if (parsed != null) {
                          setState(() {
                            _monthlyRetirementGoal = parsed;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementSummary(RetirementProjection data) {
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
                  'Capital Necesario',
                  data.totalNeeded,
                  Icons.savings_rounded,
                  Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Capital Actual',
                  data.currentSavings,
                  Icons.account_balance_wallet_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Ahorro Mensual Actual',
                  data.currentMonthlySavings,
                  Icons.trending_up_rounded,
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
                  'Ahorro Mensual Requerido',
                  data.requiredMonthlySavings,
                  Icons.flag_rounded,
                  _getRetirementColor(data.feasibilityScore),
                ),
              ),
            ],
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

  Widget _buildRetirementProjectionChart(RetirementProjection data) {
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,            horizontalInterval: data.projectionData.isNotEmpty 
                ? math.max(data.projectionData.map((p) => p.amount).reduce(math.max) / 5, 1000)
                : 1000000,
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
                interval: 10,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final year = DateTime.now().year + value.toInt();
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      year.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
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
          maxX: data.yearsToRetirement.toDouble(),
          minY: 0,
          maxY: data.projectionData.isNotEmpty 
              ? data.projectionData.map((p) => p.amount).reduce(math.max) * 1.1
              : 1000000,
          lineBarsData: [
            // Línea de proyección de ahorros
            LineChartBarData(
              spots: data.projectionData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.amount);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
            // Línea de meta de jubilación
            if (data.totalNeeded > 0)
              LineChartBarData(
                spots: [
                  FlSpot(0, data.totalNeeded),
                  FlSpot(data.yearsToRetirement.toDouble(), data.totalNeeded),
                ],
                isCurved: false,
                color: Colors.red,
                barWidth: 2,
                dashArray: [5, 5],
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetirementRecommendations(RetirementProjection data) {
    final recommendations = _generateRetirementRecommendations(data);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendaciones',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...recommendations.map((recommendation) => Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: recommendation.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: recommendation.color.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                recommendation.icon,
                size: 16,
                color: recommendation.color,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      recommendation.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  RetirementProjection _calculateRetirementProjection() {
    final currentAge = 30; // Asumir edad por defecto
    final yearsToRetirement = _targetRetirementAge - currentAge;
    
    // Calcular ahorros actuales (cuentas de ahorro e inversión)
    final currentSavings = widget.accounts
        .where((a) => a.type == 'savings' || a.type == 'investment')
        .fold(0.0, (sum, a) => sum + a.currentBalance);
    
    // Calcular ahorro mensual actual basado en movimientos recientes
    final now = DateTime.now();
    final last3Months = now.subtract(Duration(days: 90));
    
    final recentSavings = widget.movements
        .where((m) => 
            m.dateTime.isAfter(last3Months) &&
            (m.type == 'transfer' && widget.accounts.any((a) => 
                a.id == m.accountId && (a.type == 'savings' || a.type == 'investment'))))
        .fold(0.0, (sum, m) => sum + m.amount);
    
    final currentMonthlySavings = recentSavings / 3;
    
    // Calcular necesidades de jubilación
    final monthsInRetirement = 25 * 12; // 25 años de jubilación
    final inflationAdjustedGoal = _monthlyRetirementGoal * math.pow(1 + _expectedInflation / 100, yearsToRetirement);
    final totalNeeded = inflationAdjustedGoal * monthsInRetirement;
    
    // Calcular proyección de ahorros
    final monthlyReturn = _expectedReturn / 100 / 12;
    final futureValueCurrentSavings = currentSavings * math.pow(1 + _expectedReturn / 100, yearsToRetirement);
    
    // Calcular ahorro mensual requerido
    final annuityFactor = (math.pow(1 + monthlyReturn, yearsToRetirement * 12) - 1) / monthlyReturn;
    final requiredMonthlySavings = (totalNeeded - futureValueCurrentSavings) / annuityFactor;
      // Calcular factibilidad
    final feasibilityScore = currentMonthlySavings > 0 
        ? (currentMonthlySavings / requiredMonthlySavings * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;
    
    // Generar datos de proyección
    List<ProjectionDataPoint> projectionData = [];
    double projectedAmount = currentSavings;
    
    for (int year = 0; year <= yearsToRetirement; year++) {
      projectionData.add(ProjectionDataPoint(
        year: year,
        amount: projectedAmount,
      ));
      
      if (year < yearsToRetirement) {
        // Crecimiento anual con ahorros mensuales
        projectedAmount = projectedAmount * (1 + _expectedReturn / 100) + 
                         currentMonthlySavings * 12;
      }
    }
    
    return RetirementProjection(
      currentSavings: currentSavings,
      currentMonthlySavings: currentMonthlySavings,
      totalNeeded: totalNeeded,
      requiredMonthlySavings: requiredMonthlySavings,
      yearsToRetirement: yearsToRetirement,
      feasibilityScore: feasibilityScore,
      projectionData: projectionData,
    );
  }

  List<RetirementRecommendation> _generateRetirementRecommendations(RetirementProjection data) {
    List<RetirementRecommendation> recommendations = [];
    
    if (data.feasibilityScore < 50) {
      recommendations.add(RetirementRecommendation(
        title: 'Aumentar ahorro mensual',
        description: 'Necesitas ahorrar ${_formatCurrency(data.requiredMonthlySavings)} mensualmente para alcanzar tu meta.',
        color: Colors.red,
        icon: Icons.trending_up_rounded,
      ));
    }
    
    if (data.currentMonthlySavings < data.requiredMonthlySavings * 0.5) {
      recommendations.add(RetirementRecommendation(
        title: 'Revisar gastos',
        description: 'Considera reducir gastos no esenciales para aumentar tu capacidad de ahorro.',
        color: Colors.orange,
        icon: Icons.content_cut_rounded,
      ));
    }
    
    if (data.yearsToRetirement > 20) {
      recommendations.add(RetirementRecommendation(
        title: 'Considera inversiones',
        description: 'Con ${data.yearsToRetirement} años por delante, las inversiones pueden ayudarte a crecer tu patrimonio.',
        color: Colors.blue,
        icon: Icons.trending_up_rounded,
      ));
    }
    
    if (data.feasibilityScore >= 80) {
      recommendations.add(RetirementRecommendation(
        title: '¡Vas por buen camino!',
        description: 'Tu plan de jubilación está bien encaminado. Mantén la disciplina de ahorro.',
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      ));
    }
    
    return recommendations;
  }

  Color _getRetirementColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
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
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  String _formatNumber(double number) {
    return NumberFormat('#,###').format(number);
  }
}

// Clases auxiliares
class RetirementProjection {
  final double currentSavings;
  final double currentMonthlySavings;
  final double totalNeeded;
  final double requiredMonthlySavings;
  final int yearsToRetirement;
  final double feasibilityScore;
  final List<ProjectionDataPoint> projectionData;

  RetirementProjection({
    required this.currentSavings,
    required this.currentMonthlySavings,
    required this.totalNeeded,
    required this.requiredMonthlySavings,
    required this.yearsToRetirement,
    required this.feasibilityScore,
    required this.projectionData,
  });
}

class ProjectionDataPoint {
  final int year;
  final double amount;

  ProjectionDataPoint({
    required this.year,
    required this.amount,
  });
}

class RetirementRecommendation {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  RetirementRecommendation({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
}
