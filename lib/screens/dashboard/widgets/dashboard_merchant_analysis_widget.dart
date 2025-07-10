// lib/screens/dashboard/widgets/dashboard_merchant_analysis_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardMerchantAnalysisWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;
  final List<Category> categories;

  const DashboardMerchantAnalysisWidget({
    super.key,
    required this.accounts,
    required this.movements,
    required this.categories,
  });

  @override
  _DashboardMerchantAnalysisWidgetState createState() => _DashboardMerchantAnalysisWidgetState();
}

class _DashboardMerchantAnalysisWidgetState extends State<DashboardMerchantAnalysisWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _selectedPeriod = '3_months'; // 1_month, 3_months, 6_months
  String _selectedView = 'top_merchants'; // top_merchants, by_category, trends

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final merchantData = _analyzeMerchants();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.store_rounded,
            color: Colors.indigo,
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Análisis por Comercio',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.analytics_rounded,
              size: 14,
              color: Colors.indigo,
            ),
            SizedBox(width: 4),
            Text(
              '${merchantData.length} comercios',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.indigo,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text(
              _formatCurrency(_getTotalMerchantSpending(merchantData)),
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
                _buildControlsRow(),
                SizedBox(height: 16),
                _buildMerchantSummary(merchantData),
                SizedBox(height: 16),
                _buildSelectedView(merchantData),
                SizedBox(height: 16),
                _buildMerchantInsights(merchantData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodSelector(),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildViewSelector(),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildPeriodButton('1_month', '1M'),
          _buildPeriodButton('3_months', '3M'),
          _buildPeriodButton('6_months', '6M'),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildViewButton('top_merchants', Icons.store_rounded),
          _buildViewButton('by_category', Icons.category_rounded),
          _buildViewButton('trends', Icons.trending_up_rounded),
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
          padding: EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton(String view, IconData icon) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = view;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantSummary(List<MerchantData> data) {
    final totalSpent = _getTotalMerchantSpending(data);
    final topMerchant = data.isNotEmpty ? data.first : null;
    final averageTransaction = data.isNotEmpty 
        ? data.map((m) => m.averageTransaction).reduce((a, b) => a + b) / data.length
        : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Gastado',
              totalSpent,
              Icons.account_balance_wallet_rounded,
              Colors.indigo,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _buildSummaryItem(
              'Top Comercio',
              topMerchant?.totalSpent ?? 0,
              Icons.star_rounded,
              Colors.amber,
              subtitle: topMerchant?.name ?? 'N/A',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _buildSummaryItem(
              'Promedio/Tx',
              averageTransaction,
              Icons.receipt_rounded,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, IconData icon, Color color, {String? subtitle}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
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
          subtitle ?? _formatCurrency(value),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: subtitle != null ? 10 : null,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSelectedView(List<MerchantData> data) {
    switch (_selectedView) {
      case 'top_merchants':
        return _buildTopMerchantsView(data);
      case 'by_category':
        return _buildByCategoryView(data);
      case 'trends':
        return _buildTrendsView(data);
      default:
        return _buildTopMerchantsView(data);
    }
  }

  Widget _buildTopMerchantsView(List<MerchantData> data) {
    final topMerchants = data.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Comercios',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...topMerchants.map((merchant) => _buildMerchantCard(merchant)).toList(),
      ],
    );
  }

  Widget _buildByCategoryView(List<MerchantData> data) {
    final categoryData = _groupMerchantsByCategory(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Por Categoría',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: categoryData.entries.map((entry) {
                final percentage = (entry.value / _getTotalMerchantSpending(data)) * 100;
                return PieChartSectionData(
                  color: _getCategoryColor(entry.key),
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        SizedBox(height: 12),
        ...categoryData.entries.map((entry) => Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getCategoryColor(entry.key).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getCategoryColor(entry.key).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _formatCurrency(entry.value),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getCategoryColor(entry.key),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildTrendsView(List<MerchantData> data) {
    final trendsData = _calculateMerchantTrends(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendencias de Gasto',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...trendsData.map((trend) => Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: trend.isIncreasing 
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: trend.isIncreasing 
                  ? Colors.red.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                trend.isIncreasing 
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: trend.isIncreasing ? Colors.red : Colors.green,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.merchantName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${trend.isIncreasing ? 'Aumento' : 'Disminución'} del ${trend.changePercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(trend.currentSpending),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: trend.isIncreasing ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildMerchantCard(MerchantData merchant) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMerchantIcon(merchant.categoryName),
              color: Colors.indigo,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  merchant.categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${merchant.transactionCount} transacciones',
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
                _formatCurrency(merchant.totalSpent),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Prom: ${_formatCurrency(merchant.averageTransaction)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantInsights(List<MerchantData> data) {
    final insights = _generateMerchantInsights(data);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
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

  List<MerchantData> _analyzeMerchants() {
    final periodStart = _getPeriodStartDate();
    
    final periodMovements = widget.movements.where((m) =>
        m.type == 'expense' &&
        m.dateTime.isAfter(periodStart)).toList();
    
    final Map<String, List<Movement>> merchantGroups = {};
    
    for (final movement in periodMovements) {
      final merchantName = _extractMerchantName(movement.description);
      merchantGroups.putIfAbsent(merchantName, () => []).add(movement);
    }
    
    List<MerchantData> merchantData = [];
    
    for (final entry in merchantGroups.entries) {
      final movements = entry.value;
      final totalSpent = movements.fold(0.0, (sum, m) => sum + m.amount);
      final averageTransaction = totalSpent / movements.length;
      
      final category = widget.categories.firstWhere(
        (c) => c.id == movements.first.categoryId,
        orElse: () => Category(userId: '', name: 'Sin categoría', type: 'expense'),
      );
      
      merchantData.add(MerchantData(
        name: entry.key,
        totalSpent: totalSpent,
        transactionCount: movements.length,
        averageTransaction: averageTransaction,
        categoryName: category.name,
        movements: movements,
      ));
    }
    
    merchantData.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    
    return merchantData;
  }

  String _extractMerchantName(String description) {
    // Lógica simplificada para extraer nombre del comercio
    String cleaned = description.toLowerCase().trim();
    
    // Remover prefijos comunes
    cleaned = cleaned.replaceAll(RegExp(r'^(pago |compra |tx )', caseSensitive: false), '');
    
    // Tomar las primeras palabras significativas
    final words = cleaned.split(' ');
    final significantWords = words.take(2).join(' ');
    
    return significantWords.isNotEmpty 
        ? significantWords[0].toUpperCase() + significantWords.substring(1)
        : description;
  }

  DateTime _getPeriodStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '1_month':
        return DateTime(now.year, now.month - 1, now.day);
      case '3_months':
        return DateTime(now.year, now.month - 3, now.day);
      case '6_months':
        return DateTime(now.year, now.month - 6, now.day);
      default:
        return DateTime(now.year, now.month - 3, now.day);
    }
  }

  Map<String, double> _groupMerchantsByCategory(List<MerchantData> data) {
    final Map<String, double> categoryTotals = {};
    
    for (final merchant in data) {
      categoryTotals[merchant.categoryName] = 
          (categoryTotals[merchant.categoryName] ?? 0) + merchant.totalSpent;
    }
    
    return Map.fromEntries(
      categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  List<MerchantTrend> _calculateMerchantTrends(List<MerchantData> data) {
    // Simplificado - comparar con período anterior
    final now = DateTime.now();
    final currentPeriodStart = _getPeriodStartDate();
    final previousPeriodStart = DateTime(
      currentPeriodStart.year,
      currentPeriodStart.month - _getPeriodMonths(),
      currentPeriodStart.day,
    );
    
    List<MerchantTrend> trends = [];
    
    for (final merchant in data.take(5)) {
      final currentSpending = merchant.totalSpent;
      
      final previousMovements = widget.movements.where((m) =>
          m.type == 'expense' &&
          m.dateTime.isAfter(previousPeriodStart) &&
          m.dateTime.isBefore(currentPeriodStart) &&
          _extractMerchantName(m.description) == merchant.name).toList();
      
      final previousSpending = previousMovements.fold(0.0, (sum, m) => sum + m.amount);
      
      if (previousSpending > 0) {
        final changePercentage = ((currentSpending - previousSpending) / previousSpending) * 100;
        
        trends.add(MerchantTrend(
          merchantName: merchant.name,
          currentSpending: currentSpending,
          previousSpending: previousSpending,
          changePercentage: changePercentage.abs(),
          isIncreasing: changePercentage > 0,
        ));
      }
    }
    
    trends.sort((a, b) => b.changePercentage.compareTo(a.changePercentage));
    
    return trends;
  }

  int _getPeriodMonths() {
    switch (_selectedPeriod) {
      case '1_month':
        return 1;
      case '3_months':
        return 3;
      case '6_months':
        return 6;
      default:
        return 3;
    }
  }

  List<MerchantInsight> _generateMerchantInsights(List<MerchantData> data) {
    List<MerchantInsight> insights = [];
    
    if (data.isNotEmpty) {
      final topMerchant = data.first;
      final totalSpent = _getTotalMerchantSpending(data);
      final topPercentage = (topMerchant.totalSpent / totalSpent) * 100;
      
      if (topPercentage > 30) {
        insights.add(MerchantInsight(
          message: '${topMerchant.name} representa ${topPercentage.toStringAsFixed(0)}% de tus gastos',
          icon: Icons.warning_rounded,
          color: Colors.orange,
        ));
      }
      
      final highFrequencyMerchants = data.where((m) => m.transactionCount >= 10).length;
      if (highFrequencyMerchants > 0) {
        insights.add(MerchantInsight(
          message: 'Tienes $highFrequencyMerchants comercios con alta frecuencia de compra',
          icon: Icons.repeat_rounded,
          color: Colors.blue,
        ));
      }
      
      final averageTransactionOverall = data
          .map((m) => m.averageTransaction)
          .reduce((a, b) => a + b) / data.length;
      
      final highValueMerchants = data.where((m) => 
          m.averageTransaction > averageTransactionOverall * 2).length;
      
      if (highValueMerchants > 0) {
        insights.add(MerchantInsight(
          message: '$highValueMerchants comercios tienen transacciones de alto valor',
          icon: Icons.monetization_on_rounded,
          color: Colors.green,
        ));
      }
    }
    
    return insights;
  }

  double _getTotalMerchantSpending(List<MerchantData> data) {
    return data.fold(0.0, (sum, merchant) => sum + merchant.totalSpent);
  }

  Color _getCategoryColor(String categoryName) {
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.amber, Colors.indigo,
    ];
    return colors[categoryName.hashCode % colors.length];
  }

  IconData _getMerchantIcon(String categoryName) {
    final lowerCategory = categoryName.toLowerCase();
    if (lowerCategory.contains('alimentación') || lowerCategory.contains('comida')) {
      return Icons.restaurant_rounded;
    } else if (lowerCategory.contains('transporte')) {
      return Icons.directions_car_rounded;
    } else if (lowerCategory.contains('entretenimiento')) {
      return Icons.movie_rounded;
    } else if (lowerCategory.contains('salud')) {
      return Icons.local_hospital_rounded;
    } else if (lowerCategory.contains('compras')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.store_rounded;
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
class MerchantData {
  final String name;
  final double totalSpent;
  final int transactionCount;
  final double averageTransaction;
  final String categoryName;
  final List<Movement> movements;

  MerchantData({
    required this.name,
    required this.totalSpent,
    required this.transactionCount,
    required this.averageTransaction,
    required this.categoryName,
    required this.movements,
  });
}

class MerchantTrend {
  final String merchantName;
  final double currentSpending;
  final double previousSpending;
  final double changePercentage;
  final bool isIncreasing;

  MerchantTrend({
    required this.merchantName,
    required this.currentSpending,
    required this.previousSpending,
    required this.changePercentage,
    required this.isIncreasing,
  });
}

class MerchantInsight {
  final String message;
  final IconData icon;
  final Color color;

  MerchantInsight({
    required this.message,
    required this.icon,
    required this.color,
  });
}
