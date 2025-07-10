// dashboard_trend_analysis_chart.dart
// Componente modular para mostrar el análisis de tendencias con gráfico de líneas

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:mis_finanza/models/account.dart';
import 'dart:math';

class DashboardTrendAnalysisChart extends StatefulWidget {
  final List<Movement> movements;
  final List<Category> categories;
  final List<Account> accounts;
  final String? initialTrendMetric;
  final String? initialTrendPeriod;
  final String? initialTrendCategoryId;
  final String? initialTrendAccountId;
  final Function(String)? onTrendMetricChanged;
  final Function(String)? onTrendPeriodChanged;
  final Function(String?)? onTrendCategoryChanged;
  final Function(String?)? onTrendAccountChanged;

  const DashboardTrendAnalysisChart({
    super.key,
    required this.movements,
    required this.categories,
    required this.accounts,
    this.initialTrendMetric = 'income',
    this.initialTrendPeriod = '3_months',
    this.initialTrendCategoryId,
    this.initialTrendAccountId,
    this.onTrendMetricChanged,
    this.onTrendPeriodChanged,
    this.onTrendCategoryChanged,
    this.onTrendAccountChanged,
  });

  @override
  _DashboardTrendAnalysisChartState createState() => _DashboardTrendAnalysisChartState();
}

class _DashboardTrendAnalysisChartState extends State<DashboardTrendAnalysisChart> {
  String _selectedTrendMetric = 'income';
  String _selectedTrendPeriod = '3_months';
  String? _selectedTrendCategoryId;
  String? _selectedTrendAccountId;

  @override
  void initState() {
    super.initState();
    _selectedTrendMetric = widget.initialTrendMetric ?? 'income';
    _selectedTrendPeriod = widget.initialTrendPeriod ?? '3_months';
    _selectedTrendCategoryId = widget.initialTrendCategoryId;
    _selectedTrendAccountId = widget.initialTrendAccountId;
  }

  @override
  Widget build(BuildContext context) {
    final trendData = _aggregateMovementsForTrend(
      widget.movements,
      widget.categories,
      _selectedTrendMetric,
      _selectedTrendPeriod,
      categoryId: _selectedTrendCategoryId,
      accountId: _selectedTrendAccountId,
    );

    // Convert map to sorted list of spots for LineChart
    final sortedMonths = trendData.keys.toList()..sort();
    final List<FlSpot> spots = [];
    double minY = 0;
    double maxY = 0;

    if (trendData.isNotEmpty) {
      // Determine min/max Y for the chart dynamically
      minY = trendData.values.reduce(min);
      maxY = trendData.values.reduce(max);

      // Add some padding to min/max Y
      if (minY == maxY) {
        // If all values are the same, add some padding around the value
        minY = minY - (minY.abs() * 0.1 + 1000);
        maxY = maxY + (maxY.abs() * 0.1 + 1000);
      } else {
        minY = minY - (maxY - minY) * 0.1;
        maxY = maxY + (maxY - minY) * 0.1;
      }

      for (int i = 0; i < sortedMonths.length; i++) {
        spots.add(FlSpot(i.toDouble(), trendData[sortedMonths[i]]!));
      }
    }    // Handle empty spots case
    if (spots.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
          title: Text('Análisis de Tendencias', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('Sin datos para el período seleccionado', style: Theme.of(context).textTheme.bodySmall),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No hay datos para mostrar la tendencia de ${_getTrendMetricText(_selectedTrendMetric)} para el período seleccionado.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }    Color lineColor = Colors.blue;
    String trendDisplayText = '';
    IconData trendIcon = Icons.trending_up;
    
    if (_selectedTrendMetric == 'income') {
      lineColor = Colors.green;
      trendDisplayText = 'Tendencia de Ingresos';
      trendIcon = Icons.trending_up;
    } else if (_selectedTrendMetric == 'expense') {
      lineColor = Colors.red;
      trendDisplayText = 'Tendencia de Gastos';
      trendIcon = Icons.trending_down;
    } else if (_selectedTrendMetric == 'savings') {
      lineColor = Colors.purple;
      trendDisplayText = 'Tendencia de Ahorros';
      trendIcon = Icons.savings;
    }    // Calculate both income and expense data for subtitle
    Widget subtitleWidget;
    if (sortedMonths.isNotEmpty) {
      // Calculate income and expense data separately for the current month
      final incomeData = _aggregateMovementsForTrend(
        widget.movements,
        widget.categories,
        'income',
        _selectedTrendPeriod,
        categoryId: _selectedTrendCategoryId,
        accountId: _selectedTrendAccountId,
      );
      
      final expenseData = _aggregateMovementsForTrend(
        widget.movements,
        widget.categories,
        'expense',
        _selectedTrendPeriod,
        categoryId: _selectedTrendCategoryId,
        accountId: _selectedTrendAccountId,
      );
      
      final sortedIncomeMonths = incomeData.keys.toList()..sort();
      final sortedExpenseMonths = expenseData.keys.toList()..sort();
      
      double currentIncome = 0.0;
      double currentExpense = 0.0;
      double previousIncome = 0.0;
      double previousExpense = 0.0;
      
      if (sortedIncomeMonths.isNotEmpty) {
        currentIncome = incomeData[sortedIncomeMonths.last] ?? 0.0;
        if (sortedIncomeMonths.length >= 2) {
          previousIncome = incomeData[sortedIncomeMonths[sortedIncomeMonths.length - 2]] ?? 0.0;
        }
      }
      
      if (sortedExpenseMonths.isNotEmpty) {
        currentExpense = expenseData[sortedExpenseMonths.last] ?? 0.0;
        if (sortedExpenseMonths.length >= 2) {
          previousExpense = expenseData[sortedExpenseMonths[sortedExpenseMonths.length - 2]] ?? 0.0;
        }
      }
      
      // Calculate variations
      double incomeChange = currentIncome - previousIncome;
      double expenseChange = currentExpense - previousExpense;
      
      // Helper function to build variation widget
      Widget buildVariationWidget(double change, bool isIncome) {
        if (change == 0) return SizedBox.shrink();
        
        Color changeColor;
        IconData changeIcon;
        
        if (isIncome) {
          // For income: positive change is good (green), negative is bad (red)
          changeColor = change > 0 ? Colors.green : Colors.red;
          changeIcon = change > 0 ? Icons.trending_up : Icons.trending_down;
        } else {
          // For expenses: positive change is bad (red), negative is good (green)
          changeColor = change > 0 ? Colors.red : Colors.green;
          changeIcon = change > 0 ? Icons.trending_up : Icons.trending_down;
        }
        
        return Row(
          children: [
            SizedBox(width: 8),
            Icon(
              changeIcon,
              size: 12,
              color: changeColor,
            ),
            SizedBox(width: 2),
            Text(
              _formatCurrency2(change.abs(), 'COP'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: changeColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      }
      
      subtitleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 16,
                color: Colors.green,
              ),
              SizedBox(width: 4),
              Text(
                'Ingresos: ${_formatCurrency2(currentIncome, 'COP')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (sortedIncomeMonths.length >= 2)
                buildVariationWidget(incomeChange, true),
            ],
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 16,
                color: Colors.red,
              ),
              SizedBox(width: 4),
              Text(
                'Gastos: ${_formatCurrency2(currentExpense, 'COP')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (sortedExpenseMonths.length >= 2)
                buildVariationWidget(expenseChange, false),
            ],
          ),
        ],
      );
    } else {
      subtitleWidget = Text(
        trendDisplayText,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
      return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(trendIcon, color: lineColor),
        title: Text('Análisis de Tendencias', style: Theme.of(context).textTheme.titleLarge),
        subtitle: subtitleWidget,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Controles de filtrado
                Row(
                  children: [
                    Icon(Icons.filter_alt, size: 20, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                SizedBox(height: 16),
                
                // Dropdown para métrica de tendencia
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Métrica de Tendencia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.analytics),
                  ),
                  value: _selectedTrendMetric,
                  items: {
                    'income': 'Ingresos',
                    'expense': 'Gastos',
                    'savings': 'Ahorro Neto',
                  }.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value, style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTrendMetric = newValue!;
                    });
                    widget.onTrendMetricChanged?.call(newValue!);
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 16),
                
                // Dropdown para período
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Período',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  value: _selectedTrendPeriod,
                  items: {
                    '2_months': 'Últimos 2 Meses',
                    '3_months': 'Últimos 3 Meses',
                    '6_months': 'Últimos 6 Meses',
                    '12_months': 'Últimos 12 Meses',
                    'all_time': 'Desde el Inicio',
                  }.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value, style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTrendPeriod = newValue!;
                    });
                    widget.onTrendPeriodChanged?.call(newValue!);
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 16),
                  // Dropdown para filtrar por categoría
                DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  value: _selectedTrendCategoryId,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las categorías', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    // Filtrar categorías según la métrica seleccionada
                    ...widget.categories.where((category) {
                      if (_selectedTrendMetric == 'income') {
                        return category.type == 'income';
                      } else if (_selectedTrendMetric == 'expense') {
                        return category.type == 'expense';
                      } else {
                        return true; // Para 'savings' mostrar todas
                      }
                    }).map((category) {
                      return DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text(category.name, style: Theme.of(context).textTheme.bodyMedium),
                      );
                    }),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTrendCategoryId = newValue;
                    });
                    widget.onTrendCategoryChanged?.call(newValue);
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 16),
                  // Dropdown para filtrar por cuenta
                DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: 'Cuenta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  value: _selectedTrendAccountId,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las cuentas', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    ...widget.accounts.map((account) {
                      return DropdownMenuItem<String?>(
                        value: account.id,
                        child: Text(account.name, style: Theme.of(context).textTheme.bodyMedium),
                      );
                    }),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTrendAccountId = newValue;
                    });
                    widget.onTrendAccountChanged?.call(newValue);
                  },
                  isExpanded: true,                ),
                SizedBox(height: 24),
                
                // Separador y título del gráfico
                Divider(),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.show_chart, size: 20, color: lineColor),
                    SizedBox(width: 8),
                    Text('Gráfico de Tendencia', style: Theme.of(context).textTheme.titleMedium),
                    Spacer(),
                    Tooltip(
                      message: 'Gráfico de líneas que muestra la evolución de ${_getTrendMetricText(_selectedTrendMetric).toLowerCase()} a lo largo del tiempo',
                      child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Gráfico de líneas
                AspectRatio(
                  aspectRatio: 1.8,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < sortedMonths.length) {
                                final month = sortedMonths[index];
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8.0,
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      DateFormat('MMM yy').format(month),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                );
                              }
                              return Container();
                            },
                            reservedSize: 60,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatLargeCurrency(value, 'COP'),
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                            strokeWidth: 0.5,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: lineColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (FlSpot spot) => Theme.of(context).cardColor.withOpacity(0.9),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              final month = sortedMonths[touchedSpot.spotIndex];
                              final value = trendData[month]!;
                              return LineTooltipItem(
                                '${DateFormat('MMM yy').format(month)}\n',
                                TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                    text: _formatCurrency2(value, 'COP'),
                                    style: TextStyle(color: lineColor, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Comparación del mes actual vs anterior
                if (sortedMonths.length >= 2)
                  Builder(
                    builder: (context) {
                      final currentMonthData = trendData[sortedMonths.last];
                      final previousMonthData = trendData[sortedMonths[sortedMonths.length - 2]];

                      if (currentMonthData != null && previousMonthData != null) {
                        double change = currentMonthData - previousMonthData;
                        String comparisonText = '';
                        Color comparisonColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

                        if (_selectedTrendMetric == 'income') {
                          comparisonText = 'Ingresos este mes: ${_formatCurrency2(currentMonthData, 'COP')}. ';
                          if (change > 0) {
                            comparisonText += 'Aumento de ${_formatCurrency2(change, 'COP')} respecto al mes anterior.';
                            comparisonColor = Colors.green;
                          } else if (change < 0) {
                            comparisonText += 'Disminución de ${_formatCurrency2(change.abs(), 'COP')} respecto al mes anterior.';
                            comparisonColor = Colors.red;
                          } else {
                            comparisonText += 'Sin cambios respecto al mes anterior.';
                          }
                        } else if (_selectedTrendMetric == 'expense') {
                          comparisonText = 'Gastos este mes: ${_formatCurrency2(currentMonthData, 'COP')}. ';
                          if (change > 0) {
                            comparisonText += 'Aumento de ${_formatCurrency2(change, 'COP')} respecto al mes anterior.';
                            comparisonColor = Colors.red;
                          } else if (change < 0) {
                            comparisonText += 'Disminución de ${_formatCurrency2(change.abs(), 'COP')} respecto al mes anterior.';
                            comparisonColor = Colors.green;
                          } else {
                            comparisonText += 'Sin cambios respecto al mes anterior.';
                          }
                        } else if (_selectedTrendMetric == 'savings') {
                          comparisonText = 'Ahorro neto este mes: ${_formatCurrency2(currentMonthData, 'COP')}. ';
                          if (change > 0) {
                            comparisonText += 'Mejora de ${_formatCurrency2(change, 'COP')} respecto al mes anterior.';
                            comparisonColor = Colors.green;
                          } else if (change < 0) {
                            comparisonText += 'Empeoramiento de ${_formatCurrency2(change.abs(), 'COP')} respecto al mes anterior.';
                            comparisonColor = Colors.red;
                          } else {
                            comparisonText += 'Sin cambios respecto al mes anterior.';
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            comparisonText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: comparisonColor, 
                              fontStyle: FontStyle.italic
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para obtener el texto a mostrar para la métrica de tendencia
  String _getTrendMetricText(String metric) {
    switch (metric) {
      case 'income': return 'Ingresos';
      case 'expense': return 'Gastos';
      case 'savings': return 'Ahorro Neto';
      default: return '';
    }
  }

  // Helper para agregar movimientos para el gráfico de tendencias
  Map<DateTime, double> _aggregateMovementsForTrend(
    List<Movement> movements, 
    List<Category> categories, 
    String metric, 
    String period, {
    String? categoryId, 
    String? accountId
  }) {
    final Map<DateTime, double> monthlyData = {};
    DateTime now = DateTime.now();
    DateTime startDateForPeriod;

    if (period == '2_months') {
      startDateForPeriod = DateTime(now.year, now.month - 1, 1);
    } else if (period == '3_months') {
      startDateForPeriod = DateTime(now.year, now.month - 2, 1);
    } else if (period == '6_months') {
      startDateForPeriod = DateTime(now.year, now.month - 5, 1);
    } else if (period == '12_months') {
      startDateForPeriod = DateTime(now.year, now.month - 11, 1);
    } else { // 'all_time'
      startDateForPeriod = movements.isNotEmpty
          ? movements.map((m) => m.dateTime).reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime(now.year, now.month, 1);
      startDateForPeriod = DateTime(startDateForPeriod.year, startDateForPeriod.month, 1);
    }

    // Asegurarse de que startDateForPeriod no esté en el futuro
    if (startDateForPeriod.isAfter(now)) {
      startDateForPeriod = DateTime(now.year, now.month, 1);
    }

    // Inicializar todos los meses en el rango a 0
    DateTime currentMonth = DateTime(startDateForPeriod.year, startDateForPeriod.month, 1);
    while (currentMonth.isBefore(DateTime(now.year, now.month + 1, 1))) {
      monthlyData[currentMonth] = 0.0;
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }

    // Filtrar movimientos por categoría y cuenta si se han seleccionado
    List<Movement> filteredMovements = movements.where((movement) {
      // Filtrar por categoría si se ha seleccionado una
      if (categoryId != null && movement.categoryId != categoryId) {
        return false;
      }
      
      // Filtrar por cuenta si se ha seleccionado una
      if (accountId != null && movement.accountId != accountId) {
        return false;
      }
      
      // Verificar que el movimiento esté dentro del período seleccionado
      final monthStart = DateTime(movement.dateTime.year, movement.dateTime.month, 1);
      return !monthStart.isBefore(startDateForPeriod);
    }).toList();
    
    for (var movement in filteredMovements) {
      final monthStart = DateTime(movement.dateTime.year, movement.dateTime.month, 1);

      double amount = 0.0;
      if (metric == 'income') {
        final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
        if (category?.type == 'income') {
          amount = movement.amount;
        }
      } else if (metric == 'expense') {
        final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
        if (category?.type == 'expense') {
          amount = movement.amount;
        }
      } else if (metric == 'savings') {
        final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
        if (category?.type == 'income') {
          amount = movement.amount;
        } else if (category?.type == 'expense') {
          amount = -movement.amount;
        }
      }

      monthlyData.update(monthStart, (value) => value + amount, ifAbsent: () => amount);
    }

    return monthlyData;
  }

  // Helper para formatear moneda (formato simple)
  String _formatCurrency2(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: currencyCode == 'COP' ? '\$' : currencyCode,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Helper para formatear moneda en formato grande (abreviado)
  String _formatLargeCurrency(double value, String currencyCode) {
    String symbol = currencyCode == 'COP' ? '\$' : currencyCode;
    
    if (value.abs() >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '$symbol${value.toStringAsFixed(0)}';
    }
  }
}
