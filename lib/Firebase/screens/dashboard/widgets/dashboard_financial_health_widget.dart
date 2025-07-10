// lib/screens/dashboard/widgets/dashboard_financial_health_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/budget.dart';
import 'package:mis_finanza/models/debt.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardFinancialHealthWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;
  final List<Budget> budgets;
  final List<Debt> debts;
  final List<Category> categories;

  const DashboardFinancialHealthWidget({
    super.key,
    required this.accounts,
    required this.movements,
    required this.budgets,
    required this.debts,
    required this.categories,
  });

  @override
  _DashboardFinancialHealthWidgetState createState() => _DashboardFinancialHealthWidgetState();
}

class _DashboardFinancialHealthWidgetState extends State<DashboardFinancialHealthWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final healthData = _calculateFinancialHealth();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getHealthColor(healthData.overallScore).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getHealthIcon(healthData.overallScore),
            color: _getHealthColor(healthData.overallScore),
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Salud Financiera',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 14,
              color: _getHealthColor(healthData.overallScore),
            ),
            SizedBox(width: 4),
            Text(
              '${healthData.overallScore.toStringAsFixed(0)}/100',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getHealthColor(healthData.overallScore),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text(
              _getHealthLabel(healthData.overallScore),
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
                _buildHealthOverview(healthData),
                SizedBox(height: 16),
                _buildHealthMetrics(healthData),
                SizedBox(height: 16),
                _buildHealthChart(healthData),
                SizedBox(height: 16),
                _buildHealthRecommendations(healthData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthOverview(FinancialHealthData data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    // Círculo de progreso
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: data.overallScore / 100,
                        strokeWidth: 6,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getHealthColor(data.overallScore),
                        ),
                      ),
                    ),
                    // Puntaje en el centro
                    Center(
                      child: Text(
                        '${data.overallScore.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(data.overallScore),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getHealthLabel(data.overallScore),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getHealthColor(data.overallScore),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getHealthDescription(data.overallScore),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
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

  Widget _buildHealthMetrics(FinancialHealthData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas Clave',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Liquidez',
                data.liquidityRatio,
                Icons.water_drop_rounded,
                _getRatioColor(data.liquidityRatio, 3.0),
                isPercentage: false,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Ahorro',
                data.savingsRate,
                Icons.savings_rounded,
                _getRatioColor(data.savingsRate, 20.0),
                isPercentage: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Endeudamiento',
                data.debtToIncomeRatio,
                Icons.account_balance_rounded,
                _getRatioColor(30.0 - data.debtToIncomeRatio, 20.0), // Invertido: menos deuda es mejor
                isPercentage: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Diversificación',
                data.diversificationScore,
                Icons.pie_chart_rounded,
                _getRatioColor(data.diversificationScore, 80.0),
                isPercentage: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, double value, IconData icon, Color color, {bool isPercentage = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            isPercentage 
                ? '${value.toStringAsFixed(1)}%'
                : value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChart(FinancialHealthData data) {
    return Container(
      height: 200,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: _getHealthColor(data.overallScore).withOpacity(0.2),
              borderColor: _getHealthColor(data.overallScore),
              borderWidth: 2,
              dataEntries: [
                RadarEntry(value: data.liquidityScore),
                RadarEntry(value: data.savingsScore),
                RadarEntry(value: data.budgetScore),
                RadarEntry(value: data.debtScore),
                RadarEntry(value: data.diversificationScore),
              ],
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: Theme.of(context).textTheme.bodySmall!,
          getTitle: (index, angle) {
            const titles = ['Liquidez', 'Ahorro', 'Presupuesto', 'Deuda', 'Diversificación'];
            return RadarChartTitle(text: titles[index]);
          },
          tickCount: 5,
          ticksTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          tickBorderData: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
          gridBorderData: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthRecommendations(FinancialHealthData data) {
    final recommendations = _generateRecommendations(data);
    
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
            color: recommendation.priority == RecommendationPriority.high
                ? Colors.red.withOpacity(0.1)
                : recommendation.priority == RecommendationPriority.medium
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: recommendation.priority == RecommendationPriority.high
                  ? Colors.red.withOpacity(0.3)
                  : recommendation.priority == RecommendationPriority.medium
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                recommendation.icon,
                size: 16,
                color: recommendation.priority == RecommendationPriority.high
                    ? Colors.red
                    : recommendation.priority == RecommendationPriority.medium
                        ? Colors.orange
                        : Colors.blue,
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
  FinancialHealthData _calculateFinancialHealth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    
    // Calcular ingresos y gastos del mes actual
    final currentMonthMovements = widget.movements.where((m) =>
        m.dateTime.isAfter(currentMonth.subtract(Duration(days: 1))) &&
        m.dateTime.isBefore(DateTime(now.year, now.month + 1, 0).add(Duration(days: 1)))).toList();
    
    final monthlyIncome = currentMonthMovements
        .where((m) => m.type == 'income')
        .fold(0.0, (sum, m) => sum + m.amount);
    
    final monthlyExpenses = currentMonthMovements
        .where((m) => m.type == 'expense')
        .fold(0.0, (sum, m) => sum + m.amount);
    
    // Calcular activos líquidos (cuentas corrientes y ahorros)
    final liquidAssets = widget.accounts
        .where((a) => !a.isCreditCard && (a.type == 'checking' || a.type == 'savings'))
        .fold(0.0, (sum, a) => sum + a.currentBalance);
    
    // Calcular deuda total
    final totalDebt = widget.debts
        .where((d) => d.status == 'active')
        .fold(0.0, (sum, d) => sum + d.currentAmount);
    
    // Métricas de salud financiera
    final liquidityRatio = monthlyExpenses > 0 ? liquidAssets / monthlyExpenses : 0.0;
    final savingsRate = monthlyIncome > 0 ? ((monthlyIncome - monthlyExpenses) / monthlyIncome) * 100 : 0.0;
    final debtToIncomeRatio = monthlyIncome > 0 ? (totalDebt / (monthlyIncome * 12)) * 100 : 0.0;
    
    // Calcular puntajes individuales
    final liquidityScore = _calculateLiquidityScore(liquidityRatio);
    final savingsScore = _calculateSavingsScore(savingsRate);
    final budgetScore = _calculateBudgetScore();
    final debtScore = _calculateDebtScore(debtToIncomeRatio);
    final diversificationScore = _calculateDiversificationScore();
    
    // Calcular puntaje general
    final overallScore = (liquidityScore + savingsScore + budgetScore + debtScore + diversificationScore) / 5;
    
    return FinancialHealthData(
      overallScore: overallScore,
      liquidityRatio: liquidityRatio,
      savingsRate: savingsRate,
      debtToIncomeRatio: debtToIncomeRatio,
      diversificationScore: diversificationScore,
      liquidityScore: liquidityScore,
      savingsScore: savingsScore,
      budgetScore: budgetScore,
      debtScore: debtScore,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      liquidAssets: liquidAssets,
      totalDebt: totalDebt,
    );
  }

  double _calculateLiquidityScore(double liquidityRatio) {
    if (liquidityRatio >= 6) return 100;
    if (liquidityRatio >= 3) return 80;
    if (liquidityRatio >= 1) return 60;
    if (liquidityRatio >= 0.5) return 40;
    return 20;
  }

  double _calculateSavingsScore(double savingsRate) {
    if (savingsRate >= 20) return 100;
    if (savingsRate >= 15) return 80;
    if (savingsRate >= 10) return 60;
    if (savingsRate >= 5) return 40;
    if (savingsRate > 0) return 20;
    return 0;
  }

  double _calculateBudgetScore() {
    final now = DateTime.now();
    final currentMonthYear = DateFormat('yyyy-MM').format(now);
    
    final currentBudget = widget.budgets
        .where((b) => b.monthYear == currentMonthYear)
        .firstOrNull;
    
    if (currentBudget == null) return 30; // Penalización por no tener presupuesto
    
    final currentMonthMovements = widget.movements.where((m) =>
        m.type == 'expense' &&
        DateFormat('yyyy-MM').format(m.dateTime) == currentMonthYear).toList();
    
    double adherenceScore = 0;
    int categoriesEvaluated = 0;
    
    for (final categoryId in currentBudget.categoryBudgets.keys) {
      final budgetedAmount = currentBudget.categoryBudgets[categoryId]!;
      final spent = currentMonthMovements
          .where((m) => m.categoryId == categoryId)
          .fold(0.0, (sum, m) => sum + m.amount);
      
      if (budgetedAmount > 0) {
        final adherence = (budgetedAmount - spent) / budgetedAmount;
        if (adherence >= 0) {
          adherenceScore += 100;
        } else if (adherence >= -0.2) {
          adherenceScore += 70;
        } else {
          adherenceScore += 30;
        }
        categoriesEvaluated++;
      }
    }
    
    return categoriesEvaluated > 0 ? adherenceScore / categoriesEvaluated : 50;
  }

  double _calculateDebtScore(double debtToIncomeRatio) {
    if (debtToIncomeRatio <= 10) return 100;
    if (debtToIncomeRatio <= 20) return 80;
    if (debtToIncomeRatio <= 30) return 60;
    if (debtToIncomeRatio <= 40) return 40;
    return 20;
  }

  double _calculateDiversificationScore() {
    final accountTypes = <String, double>{};
    
    for (final account in widget.accounts) {
      if (!account.isCreditCard) {
        accountTypes[account.type] = (accountTypes[account.type] ?? 0) + account.currentBalance;
      }
    }
    
    final totalBalance = accountTypes.values.fold(0.0, (sum, balance) => sum + balance);
    
    if (totalBalance == 0) return 50;
    
    // Calcular índice de diversificación basado en la distribución
    double diversificationIndex = 0;
    for (final balance in accountTypes.values) {
      final percentage = balance / totalBalance;
      diversificationIndex += percentage * percentage;
    }
    
    // Convertir a puntaje (menor concentración = mayor puntaje)
    final score = (1 - diversificationIndex) * 100;
    return score.clamp(0, 100);
  }

  List<HealthRecommendation> _generateRecommendations(FinancialHealthData data) {
    List<HealthRecommendation> recommendations = [];
    
    // Recomendaciones de liquidez
    if (data.liquidityScore < 60) {
      recommendations.add(HealthRecommendation(
        title: 'Mejorar fondo de emergencia',
        description: 'Considera tener al menos 3-6 meses de gastos en cuentas líquidas para emergencias.',
        priority: data.liquidityScore < 40 ? RecommendationPriority.high : RecommendationPriority.medium,
        icon: Icons.security_rounded,
      ));
    }
    
    // Recomendaciones de ahorro
    if (data.savingsScore < 60) {
      recommendations.add(HealthRecommendation(
        title: 'Aumentar tasa de ahorro',
        description: 'Intenta ahorrar al menos 15-20% de tus ingresos mensuales.',
        priority: data.savingsScore < 40 ? RecommendationPriority.high : RecommendationPriority.medium,
        icon: Icons.savings_rounded,
      ));
    }
    
    // Recomendaciones de presupuesto
    if (data.budgetScore < 60) {
      recommendations.add(HealthRecommendation(
        title: 'Mejorar control presupuestario',
        description: 'Crea y mantén un presupuesto mensual para controlar mejor tus gastos.',
        priority: RecommendationPriority.medium,
        icon: Icons.account_balance_wallet_rounded,
      ));
    }
    
    // Recomendaciones de deuda
    if (data.debtScore < 60) {
      recommendations.add(HealthRecommendation(
        title: 'Reducir nivel de endeudamiento',
        description: 'Tu deuda representa un porcentaje alto de tus ingresos. Considera un plan de reducción de deuda.',
        priority: data.debtScore < 40 ? RecommendationPriority.high : RecommendationPriority.medium,
        icon: Icons.trending_down_rounded,
      ));
    }
    
    // Recomendaciones de diversificación
    if (data.diversificationScore < 60) {
      recommendations.add(HealthRecommendation(
        title: 'Diversificar activos',
        description: 'Considera diversificar tus ahorros en diferentes tipos de cuentas e inversiones.',
        priority: RecommendationPriority.low,
        icon: Icons.pie_chart_rounded,
      ));
    }
    
    // Si la salud financiera es buena, dar recomendaciones positivas
    if (data.overallScore >= 80) {
      recommendations.add(HealthRecommendation(
        title: '¡Excelente gestión financiera!',
        description: 'Mantienes una muy buena salud financiera. Considera explorar oportunidades de inversión.',
        priority: RecommendationPriority.low,
        icon: Icons.star_rounded,
      ));
    }
    
    return recommendations;
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getHealthIcon(double score) {
    if (score >= 80) return Icons.favorite_rounded;
    if (score >= 60) return Icons.favorite_border_rounded;
    return Icons.heart_broken_rounded;
  }

  String _getHealthLabel(double score) {
    if (score >= 80) return 'Excelente';
    if (score >= 60) return 'Buena';
    if (score >= 40) return 'Regular';
    return 'Necesita Atención';
  }

  String _getHealthDescription(double score) {
    if (score >= 80) return 'Tu salud financiera es excelente. ¡Sigue así!';
    if (score >= 60) return 'Tienes una buena base financiera con margen de mejora.';
    if (score >= 40) return 'Tu situación financiera es estable pero requiere atención.';
    return 'Es importante trabajar en mejorar tu situación financiera.';
  }

  Color _getRatioColor(double value, double threshold) {
    if (value >= threshold) return Colors.green;
    if (value >= threshold * 0.7) return Colors.orange;
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
}

// Clases auxiliares
class FinancialHealthData {
  final double overallScore;
  final double liquidityRatio;
  final double savingsRate;
  final double debtToIncomeRatio;
  final double diversificationScore;
  final double liquidityScore;
  final double savingsScore;
  final double budgetScore;
  final double debtScore;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double liquidAssets;
  final double totalDebt;

  FinancialHealthData({
    required this.overallScore,
    required this.liquidityRatio,
    required this.savingsRate,
    required this.debtToIncomeRatio,
    required this.diversificationScore,
    required this.liquidityScore,
    required this.savingsScore,
    required this.budgetScore,
    required this.debtScore,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.liquidAssets,
    required this.totalDebt,
  });
}

enum RecommendationPriority { high, medium, low }

class HealthRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;
  final IconData icon;

  HealthRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
  });
}
