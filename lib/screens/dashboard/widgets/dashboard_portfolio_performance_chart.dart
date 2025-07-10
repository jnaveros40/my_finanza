// lib/screens/dashboard/widgets/dashboard_portfolio_performance_chart.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/investment.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:mis_finanza/services/stock_quote_cache_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPortfolioPerformanceChart extends StatefulWidget {
  const DashboardPortfolioPerformanceChart({super.key});

  @override
  _DashboardPortfolioPerformanceChartState createState() => _DashboardPortfolioPerformanceChartState();
}

class _DashboardPortfolioPerformanceChartState extends State<DashboardPortfolioPerformanceChart> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Datos del gráfico
  List<FlSpot> _portfolioValuePoints = [];
  List<FlSpot> _investedValuePoints = [];
  double _maxY = 0;
  double _minY = 0;
  List<DateTime> _timePoints = [];
  
  // Estado de carga
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPortfolioHistory();
  }

  // Procesar datos históricos del portafolio
  Future<void> _loadPortfolioHistory() async {
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Usuario no autenticado';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener todas las inversiones
      final investments = await _firestoreService.getInvestments().first;
      
      if (investments.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Procesar datos históricos
      await _processPortfolioHistory(investments);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar datos: $e';
      });
    }
  }

  Future<void> _processPortfolioHistory(List<Investment> investments) async {
    // Crear un mapa de fechas con valores acumulados
    Map<DateTime, double> portfolioValueByDate = {};
    Map<DateTime, double> investedValueByDate = {};
    
    // Obtener todas las fechas relevantes de movimientos
    Set<DateTime> allDates = {};
    
    for (var investment in investments) {
      if (investment.history != null) {
        for (var movement in investment.history!) {
          final date = (movement['date'] as Timestamp?)?.toDate();
          if (date != null) {
            // Normalizar a medianoche para agrupar por día
            final normalizedDate = DateTime(date.year, date.month, date.day);
            allDates.add(normalizedDate);
          }
        }
      }
      // Agregar fecha de inicio de la inversión
      final startDate = DateTime(investment.startDate.year, investment.startDate.month, investment.startDate.day);
      allDates.add(startDate);
    }

    // Agregar fecha actual
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    allDates.add(normalizedToday);

    // Ordenar fechas
    final sortedDates = allDates.toList()..sort();

    // Para cada fecha, calcular el valor total del portafolio
    for (var date in sortedDates) {
      double totalInvested = 0;
      double totalCurrentValue = 0;

      for (var investment in investments) {
        // Calcular cuánto se había invertido hasta esta fecha
        double investedUntilDate = 0;
        double quantityUntilDate = 0;

        if (investment.history != null) {
          for (var movement in investment.history!) {
            final movementDate = (movement['date'] as Timestamp?)?.toDate();
            if (movementDate != null && movementDate.isBefore(date.add(Duration(days: 1)))) {
              final type = movement['type'] as String? ?? '';
              final amount = (movement['amount'] as num?)?.toDouble() ?? 0.0;
              final quantity = (movement['quantity'] as num?)?.toDouble() ?? 0.0;

              switch (type) {
                case 'compra':
                case 'aporte':
                  investedUntilDate += amount;
                  quantityUntilDate += quantity;
                  break;
                case 'venta':
                  // Para venta, restamos proporcionalmente del total invertido
                  if (quantityUntilDate > 0) {
                    double soldProportion = quantity / quantityUntilDate;
                    investedUntilDate -= (investedUntilDate * soldProportion);
                    quantityUntilDate -= quantity;
                  }
                  break;
              }
            }
          }
        }        totalInvested += investedUntilDate;

        // Para el valor actual, usamos la misma lógica que en la wallet de inversiones
        if (quantityUntilDate > 0) {
          final symbol = _mapInvestmentToFinnhubSymbol(investment);
          if (symbol != null) {
            try {
              final quote = await StockQuoteCacheService().getQuote(symbol);
              final double? currentPrice = quote?.price;
              if (currentPrice != null) {
                totalCurrentValue += currentPrice * quantityUntilDate;
              } else {
                // Si no hay precio actual, usar el valor invertido como fallback
                totalCurrentValue += investedUntilDate;
              }
            } catch (e) {
              // En caso de error, usar el valor invertido como fallback
              totalCurrentValue += investedUntilDate;
            }
          } else {
            // Si no se puede mapear el símbolo, usar el valor invertido
            totalCurrentValue += investedUntilDate;
          }
        }
      }

      portfolioValueByDate[date] = totalCurrentValue;
      investedValueByDate[date] = totalInvested;
    }

    // Convertir a puntos para el gráfico
    _portfolioValuePoints.clear();
    _investedValuePoints.clear();
    _timePoints.clear();

    int index = 0;
    double maxValue = 0;
    double minValue = double.infinity;

    for (var date in sortedDates) {
      final portfolioValue = portfolioValueByDate[date] ?? 0;
      final investedValue = investedValueByDate[date] ?? 0;

      if (portfolioValue > 0 || investedValue > 0) {
        _portfolioValuePoints.add(FlSpot(index.toDouble(), portfolioValue));
        _investedValuePoints.add(FlSpot(index.toDouble(), investedValue));
        _timePoints.add(date);

        maxValue = [maxValue, portfolioValue, investedValue].reduce((a, b) => a > b ? a : b);
        minValue = [minValue, portfolioValue, investedValue].reduce((a, b) => a < b ? a : b);

        index++;
      }
    }

    _maxY = maxValue * 1.1; // 10% padding arriba
    _minY = minValue > 0 ? minValue * 0.9 : 0; // 10% padding abajo
  }

  // Helper para formatear moneda
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0
    );
    return formatter.format(amount);
  }

  // Helper para formatear fechas en el eje X
  String _formatDate(double value) {
    if (value.toInt() >= 0 && value.toInt() < _timePoints.length) {
      final date = _timePoints[value.toInt()];
      return DateFormat('MMM\nyyyy').format(date);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Inicia sesión para ver el rendimiento del portafolio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        leading: Icon(
          Icons.trending_up,
          color: Colors.blue.shade600,
        ),
        title: Text(
          'Rendimiento del Portafolio',
          style: Theme.of(context).textTheme.titleLarge,
        ),        subtitle: _portfolioValuePoints.isNotEmpty && _investedValuePoints.isNotEmpty 
          ? _buildSubtitleWithData()
          : Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Cargando datos del portafolio...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        initiallyExpanded: false,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            height: 300,
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_portfolioValuePoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay datos históricos suficientes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Los datos aparecerán a medida que agregues movimientos',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Gráfico principal
        Expanded(
          child: LineChart(
      LineChartData(        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (_maxY - _minY) > 0 ? (_maxY - _minY) / 5 : 1.0,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
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
              reservedSize: 40,
              interval: (_timePoints.length / 4).round().toDouble(),              getTitlesWidget: (value, meta) {
                return Text(
                  _formatDate(value),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              interval: (_maxY - _minY) / 4,              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        minX: 0,
        maxX: (_timePoints.length - 1).toDouble(),
        minY: _minY,
        maxY: _maxY,
        lineBarsData: [
          // Línea del valor total invertido
          LineChartBarData(
            spots: _investedValuePoints,
            isCurved: true,
            color: Colors.orange.shade600,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Línea del valor actual del portafolio
          LineChartBarData(
            spots: _portfolioValuePoints,
            isCurved: true,
            color: Colors.green.shade600,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.shade600.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date = _timePoints[barSpot.x.toInt()];
                final formattedDate = DateFormat('dd/MM/yyyy').format(date);
                final value = _formatCurrency(barSpot.y);
                final label = barSpot.barIndex == 0 ? 'Invertido' : 'Valor Actual';
                
                return LineTooltipItem(
                  '$label\n$value\n$formattedDate',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );              }).toList();
            },
          ),
        ),
      ),
          ),
        ),
        // Leyenda
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  // Widget para construir la leyenda del gráfico
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Leyenda para Total Invertido
          _buildLegendItem(
            color: Colors.orange.shade600,
            label: 'Total Invertido',
            icon: Icons.input,
          ),
          // Leyenda para Valor Actual
          _buildLegendItem(
            color: Colors.green.shade600,
            label: 'Valor Actual',
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }

  // Widget helper para crear un item de leyenda
  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitleWithData() {
    final double totalInvertido = _investedValuePoints.last.y;
    final double valorActual = _portfolioValuePoints.last.y;
    final double crecimiento = totalInvertido > 0 ? ((valorActual - totalInvertido) / totalInvertido) * 100 : 0.0;
    final Color crecimientoColor = crecimiento >= 0 ? Colors.green : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Total Invertido y Valor Actual
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.input, size: 12, color: Colors.orange),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Invertido: ${_formatCurrency(totalInvertido)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Actual: ${_formatCurrency(valorActual)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Fila 2: Crecimiento en porcentaje
          Row(
            children: [
              Icon(
                crecimiento >= 0 ? Icons.arrow_upward : Icons.arrow_downward, 
                size: 12, 
                color: crecimientoColor
              ),
              const SizedBox(width: 4),
              Text(
                'Crecimiento: ${crecimiento >= 0 ? '+' : ''}${crecimiento.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: crecimientoColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),        ],
      ),
    );
  }

  // Helper functions para mapear símbolos de inversión
  String _normalizeCryptoSymbol(String name) {
    String base = name.trim().toUpperCase();
    if (base.startsWith('BINANCE:')) base = base.substring(8);
    if (base.endsWith('T')) base = base.substring(0, base.length - 1); // Por si el usuario pone BTCUSDT
    if (base.endsWith('USDT')) base = base.substring(0, base.length - 4);
    final result = 'BINANCE:${base}USDT';
    return result;
  }

  String? _mapInvestmentToFinnhubSymbol(Investment investment) {
    if (investment.type == 'stocks' || investment.type == 'funds') {
      final symbol = investment.name.toUpperCase();
      return symbol;
    }
    if (investment.type == 'crypto') {
      final symbol = _normalizeCryptoSymbol(investment.name);
      return symbol;
    }
    return null;
  }
}
