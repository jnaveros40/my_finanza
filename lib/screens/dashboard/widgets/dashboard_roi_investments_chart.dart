// lib/screens/dashboard/widgets/dashboard_roi_investments_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/investment.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:mis_finanza/services/stock_quote_cache_service.dart';
import 'package:intl/intl.dart';

class DashboardROIInvestmentsChart extends StatefulWidget {
  const DashboardROIInvestmentsChart({super.key});

  @override
  _DashboardROIInvestmentsChartState createState() => _DashboardROIInvestmentsChartState();
}

class _DashboardROIInvestmentsChartState extends State<DashboardROIInvestmentsChart> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Filtros
  String _selectedFilterType = 'all'; // all, stocks, crypto, funds, etc.
  String _selectedPlatform = 'all'; // all, específicas
  String _selectedTimeframe = '1year'; // 1month, 3months, 6months, 1year, all
  String _selectedSortBy = 'roi_desc'; // roi_desc, roi_asc, alphabetical, amount_desc

  // Datos
  List<Investment> _investments = [];
  Map<String, double> _roiData = {};
  bool _isLoading = true;
  String? _error;

  // Colores para diferentes tipos de inversión
  static const Map<String, Color> _typeColors = {
    'stocks': Colors.blue,
    'crypto': Colors.orange,
    'funds': Colors.green,
    'bonds': Colors.purple,
    'real_estate': Colors.brown,
    'other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
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

      final investments = await _firestoreService.getInvestments().first;
      await _calculateROI(investments);

      setState(() {
        _investments = investments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar inversiones: $e';
      });
    }
  }

  Future<void> _calculateROI(List<Investment> investments) async {
    _roiData.clear();
    
    for (var investment in investments) {
      // Aplicar filtros de tiempo
      final investmentDate = investment.startDate;
      final now = DateTime.now();
      
      bool includeInvestment = true;
      switch (_selectedTimeframe) {
        case '1month':
          includeInvestment = now.difference(investmentDate).inDays <= 30;
          break;
        case '3months':
          includeInvestment = now.difference(investmentDate).inDays <= 90;
          break;
        case '6months':
          includeInvestment = now.difference(investmentDate).inDays <= 180;
          break;
        case '1year':
          includeInvestment = now.difference(investmentDate).inDays <= 365;
          break;
        case 'all':
          includeInvestment = true;
          break;
      }

      if (!includeInvestment) continue;

      // Calcular ROI
      double roi = 0.0;
      if (investment.totalInvested > 0) {
        // Obtener precio actual
        final symbol = _mapInvestmentToFinnhubSymbol(investment);
        double currentValue = investment.totalInvested; // Valor por defecto
        
        if (symbol != null) {
          try {
            final quote = await StockQuoteCacheService().getQuote(symbol);
            if (quote != null && quote.price > 0) {
              currentValue = quote.price * investment.currentQuantity;
            }
          } catch (e) {
            // Usar valor estimado si no hay precio en tiempo real
            currentValue = investment.estimatedCurrentValue;
          }
        }

        // ROI = ((Valor Actual - Inversión Inicial) / Inversión Inicial) * 100
        roi = ((currentValue - investment.totalInvested) / investment.totalInvested) * 100;
      }

      _roiData[investment.name] = roi;
    }
  }

  List<Investment> _getFilteredInvestments() {
    List<Investment> filtered = _investments;

    // Filtrar por tipo
    if (_selectedFilterType != 'all') {
      filtered = filtered.where((inv) => inv.type == _selectedFilterType).toList();
    }

    // Filtrar por plataforma
    if (_selectedPlatform != 'all') {
      filtered = filtered.where((inv) => 
        inv.platform?.toLowerCase() == _selectedPlatform.toLowerCase() ||
        (inv.platform == null && _selectedPlatform == 'sin_plataforma')
      ).toList();
    }

    // Ordenar
    switch (_selectedSortBy) {
      case 'roi_desc':
        filtered.sort((a, b) => (_roiData[b.name] ?? 0.0).compareTo(_roiData[a.name] ?? 0.0));
        break;
      case 'roi_asc':
        filtered.sort((a, b) => (_roiData[a.name] ?? 0.0).compareTo(_roiData[b.name] ?? 0.0));
        break;
      case 'alphabetical':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.totalInvested.compareTo(a.totalInvested));
        break;
    }

    return filtered;
  }

  List<String> _getUniquePlatforms() {
    Set<String> platforms = {'all'};
    for (var investment in _investments) {
      if (investment.platform != null && investment.platform!.isNotEmpty) {
        platforms.add(investment.platform!);
      } else {
        platforms.add('sin_plataforma');
      }
    }
    return platforms.toList()..sort();
  }

  // Helper para mapear símbolos
  String _normalizeCryptoSymbol(String name) {
    String base = name.trim().toUpperCase();
    if (base.startsWith('BINANCE:')) base = base.substring(8);
    if (base.endsWith('T')) base = base.substring(0, base.length - 1);
    if (base.endsWith('USDT')) base = base.substring(0, base.length - 4);
    return 'BINANCE:${base}USDT';
  }

  String? _mapInvestmentToFinnhubSymbol(Investment investment) {
    if (investment.type == 'stocks' || investment.type == 'funds') {
      return investment.name.toUpperCase();
    }
    if (investment.type == 'crypto') {
      return _normalizeCryptoSymbol(investment.name);
    }
    return null;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0
    );
    return formatter.format(amount);
  }

  String _formatPercentage(double percentage) {
    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(2)}%';
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
              'Inicia sesión para ver el ROI de inversiones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    final filteredInvestments = _getFilteredInvestments();
    final investmentCount = filteredInvestments.length;
    
    // Calcular ROI promedio de las inversiones filtradas
    double avgROI = 0.0;
    if (filteredInvestments.isNotEmpty) {
      avgROI = filteredInvestments.map((inv) => _roiData[inv.name] ?? 0.0)
          .reduce((a, b) => a + b) / filteredInvestments.length;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        leading: Icon(
          Icons.trending_up,
          color: avgROI >= 0 ? Colors.green : Colors.red,
          size: 24,
        ),
        title: Text(
          'ROI de Inversiones',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: _isLoading
            ? Row(
                children: [
                  Text('Cargando datos...'),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$investmentCount ${investmentCount == 1 ? 'inversión' : 'inversiones'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        avgROI >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: avgROI >= 0 ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ROI Promedio: ${_formatPercentage(avgROI)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: avgROI >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red),
              ),
            )
          else if (_isLoading)
            Container(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildContent(filteredInvestments),
        ],
      ),
    );
  }

  Widget _buildContent(List<Investment> filteredInvestments) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.analytics, size: 20, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Análisis de Retorno de Inversión',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Tooltip(
                message: 'ROI = ((Valor Actual - Inversión Inicial) / Inversión Inicial) * 100',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          Divider(height: 24),

          // Filtros
          _buildFiltersSection(),

          // Gráfico
          if (filteredInvestments.isNotEmpty)
            _buildROIChart(filteredInvestments)
          else
            _buildEmptyState(),

          // Lista detallada
          if (filteredInvestments.isNotEmpty)
            _buildDetailedList(filteredInvestments),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Filtros de Análisis',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Filtro por tipo
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Tipo:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilterType,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Todos los tipos'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'stocks',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Acciones'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'crypto',
                      child: Row(
                        children: [
                          Icon(Icons.currency_bitcoin, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Criptomonedas'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'funds',
                      child: Row(
                        children: [
                          Icon(Icons.account_balance, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Fondos'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'bonds',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Bonos'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'real_estate',
                      child: Row(
                        children: [
                          Icon(Icons.home, size: 16, color: Colors.brown),
                          SizedBox(width: 8),
                          Text('Bienes Raíces'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Row(
                        children: [
                          Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Otros'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilterType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Filtro por plataforma
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Plataforma:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPlatform,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                  ),
                  items: _getUniquePlatforms().map((platform) {
                    return DropdownMenuItem<String>(
                      value: platform,
                      child: Row(
                        children: [
                          Icon(
                            platform == 'all' 
                              ? Icons.all_inclusive 
                              : platform == 'sin_plataforma'
                                ? Icons.help_outline
                                : Icons.business,
                            size: 16,
                            color: platform == 'all' 
                              ? Colors.grey 
                              : platform == 'sin_plataforma'
                                ? Colors.orange
                                : Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            platform == 'all' 
                              ? 'Todas las plataformas'
                              : platform == 'sin_plataforma'
                                ? 'Sin plataforma'
                                : platform,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlatform = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Filtro por tiempo
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Período:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeframe,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '1month',
                      child: Text('Último mes'),
                    ),
                    DropdownMenuItem(
                      value: '3months',
                      child: Text('Últimos 3 meses'),
                    ),
                    DropdownMenuItem(
                      value: '6months',
                      child: Text('Últimos 6 meses'),
                    ),
                    DropdownMenuItem(
                      value: '1year',
                      child: Text('Último año'),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todo el tiempo'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeframe = value!;
                      _loadInvestments(); // Recargar para recalcular ROI
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Filtro de ordenamiento
          Row(
            children: [
              Icon(Icons.sort, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Ordenar por:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSortBy,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'roi_desc',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('ROI (Mayor a menor)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'roi_asc',
                      child: Row(
                        children: [
                          Icon(Icons.trending_down, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ROI (Menor a mayor)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'alphabetical',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Alfabético'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'amount_desc',
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Monto invertido'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSortBy = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildROIChart(List<Investment> filteredInvestments) {
    // Tomar máximo 10 inversiones para el gráfico
    final chartData = filteredInvestments.take(10).toList();
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Gráfico de ROI',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartData.map((inv) => _roiData[inv.name] ?? 0.0).reduce((a, b) => a > b ? a : b) * 1.2,
                minY: chartData.map((inv) => _roiData[inv.name] ?? 0.0).reduce((a, b) => a < b ? a : b) * 1.2,                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Theme.of(context).cardColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final investment = chartData[group.x.toInt()];
                      final roi = _roiData[investment.name] ?? 0.0;
                      return BarTooltipItem(
                        '${investment.name}\nROI: ${_formatPercentage(roi)}\nInvertido: ${_formatCurrency(investment.totalInvested)}',
                        TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < chartData.length) {
                          final investment = chartData[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              investment.name.length > 6 
                                ? '${investment.name.substring(0, 6)}...'
                                : investment.name,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
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
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final investment = entry.value;
                  final roi = _roiData[investment.name] ?? 0.0;
                  final color = _typeColors[investment.type] ?? Colors.grey;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: roi,
                        color: roi >= 0 ? color : Colors.red,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedList(List<Investment> filteredInvestments) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.list, size: 18, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Detalle de ROI por Inversión',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...filteredInvestments.map((investment) {
          final roi = _roiData[investment.name] ?? 0.0;
          final color = _typeColors[investment.type] ?? Colors.grey;
          
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(
                  _getTypeIcon(investment.type),
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(
                investment.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getTypeDisplayName(investment.type)}${investment.platform != null ? ' • ${investment.platform}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Invertido: ${_formatCurrency(investment.totalInvested)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roi >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: roi >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _formatPercentage(roi),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: roi >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: 12),
            Text(
              'No hay inversiones para analizar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).disabledColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ajusta los filtros para ver más datos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'stocks':
        return Icons.trending_up;
      case 'crypto':
        return Icons.currency_bitcoin;
      case 'funds':
        return Icons.account_balance;
      case 'bonds':
        return Icons.receipt_long;
      case 'real_estate':
        return Icons.home;
      default:
        return Icons.more_horiz;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'stocks':
        return 'Acciones';
      case 'crypto':
        return 'Criptomonedas';
      case 'funds':
        return 'Fondos';
      case 'bonds':
        return 'Bonos';
      case 'real_estate':
        return 'Bienes Raíces';
      default:
        return 'Otros';
    }
  }
}
