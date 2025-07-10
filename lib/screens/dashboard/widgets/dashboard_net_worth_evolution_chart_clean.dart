// dashboard_net_worth_evolution_chart.dart
// Widget para mostrar la evolución del patrimonio neto a lo largo del tiempo

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/debt.dart';
import 'package:mis_finanza/models/investment.dart';
import 'package:mis_finanza/models/movement.dart';

class DashboardNetWorthEvolutionChart extends StatefulWidget {
  final List<Account> accounts;
  final List<Debt> debts;
  final List<Investment> investments;
  final List<Movement> movements;
  final String displayCurrency;

  const DashboardNetWorthEvolutionChart({
    super.key,
    required this.accounts,
    required this.debts,
    required this.investments,
    required this.movements,
    this.displayCurrency = 'COP',
  });

  @override
  State<DashboardNetWorthEvolutionChart> createState() => _DashboardNetWorthEvolutionChartState();
}

class _DashboardNetWorthEvolutionChartState extends State<DashboardNetWorthEvolutionChart> {
  int _selectedMonths = 6; // Default: 6 meses
  final List<int> _availableMonths = [2, 3, 6, 9, 12, 18, 24];
  
  // Datos calculados para el chart
  final List<FlSpot> _netWorthData = [];
  final Map<String, double> _monthlyData = {};
  double _totalGrowth = 0.0;
  String _bestMonth = '';
  double _monthlyAverage = 0.0;
  
  // Nuevas métricas para Fase 2 - Patrimonio del mes actual
  double _currentMonthNetWorth = 0.0;
  double _previousMonthNetWorth = 0.0;
  double _monthlyGrowth = 0.0;
  double _projectedEndOfMonth = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateNetWorthEvolution();
  }

  @override
  void didUpdateWidget(DashboardNetWorthEvolutionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalcular si cambian los datos
    if (oldWidget.accounts != widget.accounts ||
        oldWidget.debts != widget.debts ||
        oldWidget.investments != widget.investments ||
        oldWidget.movements != widget.movements) {
      _calculateNetWorthEvolution();
    }
  }

  void _calculateNetWorthEvolution() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - _selectedMonths, 1);
    
    _netWorthData.clear();
    _monthlyData.clear();
    
    // Calcular patrimonio neto para cada mes
    for (int i = 0; i <= _selectedMonths; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      final netWorth = _calculateNetWorthAtDate(monthDate);
      final monthKey = DateFormat('yyyy-MM').format(monthDate);
      
      _monthlyData[monthKey] = netWorth;
      _netWorthData.add(FlSpot(i.toDouble(), netWorth));
    }
    
    // Calcular métricas del mes actual (Fase 2)
    _calculateCurrentMonthMetrics();
    
    _calculateMetrics();
    setState(() {});
  }

  double _calculateNetWorthAtDate(DateTime date) {
    double totalAssets = 0.0;
    double totalLiabilities = 0.0;
    
    // Calcular solo cuentas de ahorro (activos) y tarjetas de crédito (pasivos)
    for (var account in widget.accounts) {
      if (!account.isCreditCard) {
        // Solo cuentas de ahorro como activos
        double balanceAtDate = _getAccountBalanceAtDate(account, date);
        totalAssets += balanceAtDate;
      } else {
        // Tarjetas de crédito como pasivos
        double debtAtDate = _getCreditCardDebtAtDate(account, date);
        totalLiabilities += debtAtDate;
      }
    }
    
    return totalAssets - totalLiabilities;
  }

  double _getAccountBalanceAtDate(Account account, DateTime date) {
    // Iniciar con el saldo actual
    double balance = account.currentBalance;
    
    // Ajustar por movimientos posteriores a la fecha objetivo
    final movementsAfterDate = widget.movements.where((m) => 
      m.accountId == account.id && m.dateTime.isAfter(date)
    ).toList();
    
    for (var movement in movementsAfterDate) {
      switch (movement.type) {
        case 'income':
          balance -= movement.amount; // Restar ingresos futuros
          break;
        case 'expense':
          balance += movement.amount; // Sumar gastos futuros (para "deshacer" el gasto)
          break;
        case 'transfer':
          if (movement.accountId == account.id) {
            balance += movement.amount; // Era una salida, sumarla
          }
          if (movement.destinationAccountId == account.id) {
            balance -= movement.amount; // Era una entrada, restarla
          }
          break;
        case 'payment':
          if (movement.accountId == account.id) {
            balance += movement.amount; // Era una salida, sumarla
          }
          break;
      }
    }
    
    return balance;
  }

  double _getCreditCardDebtAtDate(Account account, DateTime date) {
    // Para simplificar, usar el saldo actual para fechas recientes
    // En una implementación más avanzada, se podría calcular basado en movimientos
    return account.currentStatementBalance;
  }

  // Fase 2: Calcular métricas del mes actual
  void _calculateCurrentMonthMetrics() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));
    
    // Patrimonio neto actual (hoy)
    _currentMonthNetWorth = _calculateNetWorthAtDate(now);
    
    // Patrimonio neto del mes anterior
    _previousMonthNetWorth = _calculateNetWorthAtDate(previousMonth);
    
    // Crecimiento mensual
    _monthlyGrowth = _currentMonthNetWorth - _previousMonthNetWorth;
    
    // Proyección al final del mes
    _projectedEndOfMonth = _calculateProjectedEndOfMonth(currentMonth, endOfMonth);
  }

  // Fase 2: Método para calcular la proyección al final del mes
  double _calculateProjectedEndOfMonth(DateTime startOfMonth, DateTime endOfMonth) {
    final now = DateTime.now();
    final daysInMonth = endOfMonth.day;
    final daysPassed = now.day;
    final daysRemaining = daysInMonth - daysPassed;
    
    if (daysRemaining <= 0) {
      // Si ya terminó el mes, usar el valor actual
      return _currentMonthNetWorth;
    }
    
    // Calcular la tendencia diaria promedio del mes
    final startOfMonthNetWorth = _calculateNetWorthAtDate(startOfMonth);
    final dailyGrowth = (_currentMonthNetWorth - startOfMonthNetWorth) / daysPassed;
    
    // Proyectar al final del mes
    return _currentMonthNetWorth + (dailyGrowth * daysRemaining);
  }

  void _calculateMetrics() {
    if (_monthlyData.isEmpty) return;
    
    final values = _monthlyData.values.toList();
    final firstValue = values.first;
    final lastValue = values.last;
    
    _totalGrowth = lastValue - firstValue;
    _monthlyAverage = values.reduce((a, b) => a + b) / values.length;
    
    // Encontrar el mejor mes (mayor crecimiento)
    double maxGrowth = double.negativeInfinity;
    String bestMonthKey = '';
    
    for (int i = 1; i < values.length; i++) {
      double growth = values[i] - values[i - 1];
      if (growth > maxGrowth) {
        maxGrowth = growth;
        bestMonthKey = _monthlyData.keys.elementAt(i);
      }
    }
    
    if (bestMonthKey.isNotEmpty) {
      final bestMonthDate = DateTime.parse('$bestMonthKey-01');
      _bestMonth = DateFormat('MMMM yyyy', 'es').format(bestMonthDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Icon(
          Icons.trending_up,
          color: _totalGrowth >= 0 ? Colors.green : Colors.red,
          size: 24,
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Evolución del Patrimonio Neto',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Últimos $_selectedMonths meses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              'Crecimiento: ${_formatCurrency(_totalGrowth, widget.displayCurrency)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _totalGrowth >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
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
                // Controles de filtro
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                
                // Fase 2: Sección de patrimonio del mes actual
                _buildCurrentMonthSection(),
                const SizedBox(height: 20),
                
                // Métricas principales
                _buildMetricsSection(),
                const SizedBox(height: 20),
                
                // Gráfico
                _buildChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fase 2: Widget para mostrar información del mes actual
  Widget _buildCurrentMonthSection() {
    final now = DateTime.now();
    final currentMonthName = DateFormat('MMMM yyyy', 'es').format(now);
    final projectedGrowth = _projectedEndOfMonth - _currentMonthNetWorth;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Patrimonio de $currentMonthName',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Primera fila: Patrimonio actual y crecimiento mensual
          Row(
            children: [
              Expanded(
                child: _buildCurrentMonthCard(
                  'Patrimonio Actual',
                  _formatCurrency(_currentMonthNetWorth, widget.displayCurrency),
                  Icons.account_balance_wallet,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCurrentMonthCard(
                  'Crecimiento del Mes',
                  _formatCurrency(_monthlyGrowth, widget.displayCurrency),
                  _monthlyGrowth >= 0 ? Icons.trending_up : Icons.trending_down,
                  _monthlyGrowth >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Segunda fila: Proyección al final del mes
          _buildCurrentMonthCard(
            'Proyección al Final del Mes',
            '${_formatCurrency(_projectedEndOfMonth, widget.displayCurrency)} (${projectedGrowth >= 0 ? '+' : ''}${_formatCurrency(projectedGrowth, widget.displayCurrency)})',
            Icons.insights,
            projectedGrowth >= 0 ? Colors.blue : Colors.orange,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Período de análisis:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableMonths.map((months) {
              final isSelected = months == _selectedMonths;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedMonths = months;
                  });
                  _calculateNetWorthEvolution();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${months}M',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Métricas del Período',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fila 1: Crecimiento total y Promedio mensual
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Crecimiento Total',
                  _formatCurrency(_totalGrowth, widget.displayCurrency),
                  _totalGrowth >= 0 ? Icons.trending_up : Icons.trending_down,
                  _totalGrowth >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Promedio Mensual',
                  _formatCurrency(_monthlyAverage, widget.displayCurrency),
                  Icons.show_chart,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          if (_bestMonth.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMetricCard(
              'Mejor Mes',
              _bestMonth,
              Icons.star,
              Colors.amber,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_netWorthData.isEmpty) {
      return SizedBox(
        height: 200,
        child: const Center(
          child: Text('No hay datos suficientes para mostrar el gráfico'),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Evolución del Patrimonio Neto',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Patrimonio Neto = Cuentas de Ahorro - Deudas de Tarjetas de Crédito',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: null,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCompactCurrency(value, widget.displayCurrency),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _monthlyData.length) {
                          final monthKey = _monthlyData.keys.elementAt(index);
                          final date = DateTime.parse('$monthKey-01');
                          return Text(
                            DateFormat('MMM', 'es').format(date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _netWorthData,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Theme.of(context).cardColor,
                    tooltipBorder: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        String monthLabel = '';
                        if (index >= 0 && index < _monthlyData.length) {
                          final monthKey = _monthlyData.keys.elementAt(index);
                          final date = DateTime.parse('$monthKey-01');
                          monthLabel = DateFormat('MMM yyyy', 'es').format(date);
                        }
                        
                        return LineTooltipItem(
                          '$monthLabel\n${_formatCurrency(spot.y, widget.displayCurrency)}',
                          Theme.of(context).textTheme.bodySmall!,
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value, String currency) {
    final format = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '',
      decimalDigits: 0,
    );
    return '${_getCurrencySymbol(currency)}${format.format(value)}';
  }

  String _formatCompactCurrency(double value, String currency) {
    if (value.abs() >= 1000000) {
      return '${_getCurrencySymbol(currency)}${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${_getCurrencySymbol(currency)}${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '${_getCurrencySymbol(currency)}${value.toStringAsFixed(0)}';
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'COP':
        return '\$';
      case 'USD':
        return 'US\$';
      case 'EUR':
        return '€';
      default:
        return '\$';
    }
  }
}
