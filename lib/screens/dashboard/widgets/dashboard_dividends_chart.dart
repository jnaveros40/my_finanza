// lib/screens/dashboard/widgets/dashboard_dividends_chart.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/investment.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class DashboardDividendsChart extends StatefulWidget {
  const DashboardDividendsChart({super.key});

  @override
  _DashboardDividendsChartState createState() => _DashboardDividendsChartState();
}

class _DashboardDividendsChartState extends State<DashboardDividendsChart> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Filtros
  String? _selectedTypeFilter; // Filtro por tipo de inversión
  DateTime? _startDate; // Fecha de inicio del filtro
  DateTime? _endDate; // Fecha de fin del filtro    // Datos procesados
  List<DividendData> _dividendData = [];
  Map<String, double> _dividendsByInvestment = {};  Map<String, double> _ratiosByInvestment = {}; // Nuevo: ratios por inversión
  double _totalDividends = 0.0;

  // Lista de tipos de inversión
  final List<String> _investmentTypesValues = ['stocks', 'funds', 'crypto', 'real_estate', 'bonds', 'other'];

  @override
  void initState() {
    super.initState();
  }

  // Helper para obtener el texto del tipo de inversión
  String _getInvestmentTypeText(String type) {
    switch (type) {
      case 'stocks': return 'Acciones';
      case 'funds': return 'Fondos de Inversión';
      case 'crypto': return 'Criptomonedas';
      case 'real_estate': return 'Bienes Raíces';
      case 'bonds': return 'Bonos';
      case 'other': return 'Otra';
      default: return type;
    }
  }

  // Helper para obtener el icono del tipo de inversión
  IconData _getInvestmentTypeIcon(String type) {
    switch (type) {
      case 'stocks': return Icons.trending_up;
      case 'funds': return Icons.account_balance;
      case 'crypto': return Icons.currency_bitcoin;
      case 'real_estate': return Icons.home_work;
      case 'bonds': return Icons.receipt_long;
      case 'other': return Icons.more_horiz;
      default: return Icons.monetization_on;
    }
  }

  // Helper para obtener el color del tipo de inversión
  Color _getInvestmentTypeColor(String type) {
    switch (type) {
      case 'stocks': return Colors.blue.shade600;
      case 'funds': return Colors.green.shade600;
      case 'crypto': return Colors.orange.shade600;
      case 'real_estate': return Colors.brown.shade600;
      case 'bonds': return Colors.purple.shade600;
      case 'other': return Colors.grey.shade600;
      default: return Colors.indigo.shade600;
    }
  }

  // Helper para obtener el símbolo de moneda
  String _getCurrencySymbol(String? currencyCode) {
    if (currencyCode == null) return '';
    switch (currencyCode) {
      case 'COP': return '\$';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      default: return currencyCode;
    }
  }

  // Helper para formatear moneda
  String _formatCurrency(double amount, String? currencyCode) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2
    );
    return formatter.format(amount);
  }  // Procesar datos de dividendos
  void _processDividendData(List<Investment> investments) {    _dividendData.clear();
    _dividendsByInvestment.clear();
    _ratiosByInvestment.clear(); // Limpiar ratios
    _totalDividends = 0.0;

    for (var investment in investments) {
      // Aplicar filtro por tipo
      if (_selectedTypeFilter != null && investment.type != _selectedTypeFilter) {
        continue;
      }      double investmentDividends = 0.0; // Para calcular dividendos de esta inversión específica

      if (investment.history != null) {
        for (var movementData in investment.history!) {
          final type = movementData['type'] as String? ?? '';
          if (type == 'dividendo') {
            final date = (movementData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final amount = (movementData['amount'] as num?)?.toDouble() ?? 0.0;

            // Aplicar filtro por fecha
            if (_startDate != null && date.isBefore(_startDate!)) continue;
            if (_endDate != null && date.isAfter(_endDate!)) continue;

            // Agregar a datos de gráfico de barras
            _dividendData.add(DividendData(
              date: date,
              amount: amount,
              investmentName: investment.name,
              investmentType: investment.type,
              currency: investment.currency ?? 'COP',
            ));

            // Agregar a datos de gráfico de pastel
            _dividendsByInvestment[investment.name] = 
                (_dividendsByInvestment[investment.name] ?? 0.0) + amount;
            
            investmentDividends += amount;
            _totalDividends += amount;
          }
        }
      }      // Calcular ratio de dividendos para esta inversión
      if (investment.totalInvested > 0 && investmentDividends > 0) {
        double ratio = (investmentDividends / investment.totalInvested) * 100;
        _ratiosByInvestment[investment.name] = ratio;
      }
    }

    // Ordenar datos por fecha
    _dividendData.sort((a, b) => a.date.compareTo(b.date));
  }

  // Mostrar selector de fechas
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // Limpiar filtro de fechas
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }
  // Widget de filtros responsive
  Widget _buildFiltersSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
          return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 8.0 : 16.0, 
            vertical: isMobile ? 8.0 : 12.0
          ),          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary,
                    size: isMobile ? 18 : 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtros',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              
              // Layout responsive para filtros
              if (isMobile) ...[
                // Layout vertical para móviles
                _buildTypeDropdown(isMobile),
                const SizedBox(height: 12),
                _buildDateFilter(isMobile),
              ] else ...[
                // Layout horizontal para tablets/desktop
                Row(
                  children: [
                    Expanded(child: _buildTypeDropdown(isMobile)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateFilter(isMobile)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Widget dropdown para tipo de inversión
  Widget _buildTypeDropdown(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12, 
        vertical: isMobile ? 6 : 8
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedTypeFilter,
          hint: Text(
            'Todos los tipos',
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
          isExpanded: true,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.all_inclusive, size: isMobile ? 14 : 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos los tipos',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ..._investmentTypesValues.map((String typeValue) {
              return DropdownMenuItem<String>(
                value: typeValue,
                child: Row(
                  children: [
                    Icon(
                      _getInvestmentTypeIcon(typeValue),
                      size: isMobile ? 14 : 16,
                      color: _getInvestmentTypeColor(typeValue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getInvestmentTypeText(typeValue),
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (newValue) {
            setState(() {
              _selectedTypeFilter = newValue;
            });
          },
        ),
      ),
    );
  }

  // Widget filtro de fechas
  Widget _buildDateFilter(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectDateRange,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: isMobile ? 14 : 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat(isMobile ? 'dd/MM/yy' : 'dd/MM/yyyy').format(_startDate!)} - ${DateFormat(isMobile ? 'dd/MM/yy' : 'dd/MM/yyyy').format(_endDate!)}'
                          : isMobile ? 'Período' : 'Seleccionar período',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_startDate != null || _endDate != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: _clearDateFilter,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white),
              ),
              child: Icon(
                Icons.clear,
                color: Colors.red.shade600,
                size: isMobile ? 14 : 16,
              ),
            ),
          ),
        ],
      ],
    );
  }
  // Widget de gráfico de barras responsive
  Widget _buildBarChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (_dividendData.isEmpty) {
          return Container(
            height: isMobile ? 200 : 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: isMobile ? 36 : 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SizedBox(height: isMobile ? 8 : 16),
                  Text(
                    'No hay datos de dividendos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    'No se encontraron dividendos con los filtros aplicados.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isMobile ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }        // Agrupar dividendos por mes para el gráfico de barras
        Map<String, double> monthlyDividends = {};
        for (var dividend in _dividendData) {
          String monthKey = DateFormat(isMobile ? 'MMM yy' : 'MMM yyyy').format(dividend.date);
          monthlyDividends[monthKey] = (monthlyDividends[monthKey] ?? 0.0) + dividend.amount;
        }

        // Ordenar meses cronológicamente
        List<String> months = monthlyDividends.keys.toList();
        months.sort((a, b) {
          // Crear fechas a partir de las claves de mes para ordenar cronológicamente
          DateTime dateA = DateFormat(isMobile ? 'MMM yy' : 'MMM yyyy').parse(a);
          DateTime dateB = DateFormat(isMobile ? 'MMM yy' : 'MMM yyyy').parse(b);
          return dateA.compareTo(dateB);
        });
        
        List<BarChartGroupData> barGroups = [];
        
        // Encontrar el valor máximo para el escalado
        double maxValue = 0;
        for (String month in months) {
          maxValue = math.max(maxValue, monthlyDividends[month]!);
        }
        
        for (int i = 0; i < months.length; i++) {
          // Asegurarnos que las barras pequeñas sean visibles usando un mínimo relativo
          double value = monthlyDividends[months[i]]!;
          // Si el valor es demasiado pequeño pero no cero, garantizar una altura mínima visible
          double displayValue = value;
          if (value > 0 && value < maxValue * 0.05) {
            displayValue = maxValue * 0.05; // Garantizar al menos 5% de altura para visibilidad
          }
          
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: displayValue,
                  color: Theme.of(context).colorScheme.primary,
                  width: isMobile ? 16 : 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }        return Container(
          height: isMobile ? 250 : 300,
          padding: EdgeInsets.all(isMobile ? 8 : 16),          child: BarChart(
            BarChartData(              barGroups: barGroups,
              minY: 0,
              maxY: maxValue * 1.1, // 10% adicional para espacio arriba
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() < months.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: isMobile ? 4.0 : 8.0),
                          child: Text(
                            months[value.toInt()],
                            style: TextStyle(
                              fontSize: isMobile ? 8 : 10,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: isMobile ? 40 : 60,
                    getTitlesWidget: (double value, TitleMeta meta) {                      // Ajuste para valores pequeños en móvil con formato de moneda
                      String formattedValue;
                      String symbol = _getCurrencySymbol('COP'); // Obtener símbolo de moneda
                      
                      if (isMobile) {
                        if (value == 0) {
                          formattedValue = '${symbol}0';
                        } else if (value < 1000) {
                          formattedValue = '${symbol}${value.toStringAsFixed(0)}';
                        } else if (value < 1000000) {
                          formattedValue = '${symbol}${(value / 1000).toStringAsFixed(1)}K';
                        } else {
                          formattedValue = '${symbol}${(value / 1000000).toStringAsFixed(1)}M';
                        }
                      } else {
                        formattedValue = _formatCurrency(value, 'COP');
                      }
                      
                      return Text(
                        formattedValue,
                        style: TextStyle(
                          fontSize: isMobile ? 8 : 10,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.transparent,
            ),
          ),
        );
      },
    );
  }
  // Widget de gráfico de pastel responsive
  Widget _buildPieChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (_dividendsByInvestment.isEmpty) {
          return Container(
            height: isMobile ? 200 : 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart,
                    size: isMobile ? 36 : 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SizedBox(height: isMobile ? 8 : 16),
                  Text(
                    'No hay datos de dividendos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }        List<PieChartSectionData> sections = [];
        List<Color> colors = [
          Theme.of(context).colorScheme.primary,
          Colors.green.shade600,
          Colors.orange.shade600,
          Colors.purple.shade600,
          Colors.red.shade600,
          Colors.teal.shade600,
          Colors.indigo.shade600,
          Colors.brown.shade600,
        ];

        // Ordenar inversiones por dividendos de mayor a menor
        List<MapEntry<String, double>> sortedEntries = _dividendsByInvestment.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        int colorIndex = 0;
        for (var entry in sortedEntries) {
          double percentage = (entry.value / _totalDividends) * 100;
          sections.add(
            PieChartSectionData(
              color: colors[colorIndex % colors.length],
              value: percentage,
              title: percentage >= 5.0 ? '${percentage.toStringAsFixed(1)}%' : '',
              radius: isMobile ? 70 : 100,
              titleStyle: TextStyle(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
          colorIndex++;
        }

        return Container(
          height: isMobile ? 300 : 350,
          child: isMobile
              ? Column(
                  children: [
                    // Gráfico arriba en móviles
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Leyenda abajo en móviles
                    Expanded(
                      flex: 1,
                      child: _buildLegend(colors, isMobile),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Gráfico a la izquierda en tablets/desktop
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Leyenda a la derecha en tablets/desktop
                    Expanded(
                      flex: 1,
                      child: _buildLegend(colors, isMobile),
                    ),
                  ],
                ),
        );
      },
    );
  }  // Widget de leyenda para el gráfico de pastel
  Widget _buildLegend(List<Color> colors, bool isMobile) {
    // Ordenar inversiones por dividendos de mayor a menor
    List<MapEntry<String, double>> sortedEntries = _dividendsByInvestment.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEntries.map((entry) {
          int index = sortedEntries.indexOf(entry);
          double percentage = (entry.value / _totalDividends) * 100;
          
          return Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 6.0 : 8.0),
            child: Row(
              children: [
                Container(
                  width: isMobile ? 12 : 16,
                  height: isMobile ? 12 : 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '${_formatCurrency(entry.value, 'COP')} (${percentage.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 10 : 11,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget de gráfico de pastel para ratios de dividendos
  Widget _buildRatiosPieChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        // Filtrar solo inversiones con ratio > 0
        Map<String, double> validRatios = Map.fromEntries(
          _ratiosByInvestment.entries.where((entry) => entry.value > 0)
        );
        
        if (validRatios.isEmpty) {
          return Container(
            height: isMobile ? 200 : 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart,
                    size: isMobile ? 36 : 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SizedBox(height: isMobile ? 8 : 16),
                  Text(
                    'No hay ratios de dividendos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    'No se encontraron inversiones con ratio de dividendos mayor a 0%.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isMobile ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        List<PieChartSectionData> sections = [];
        List<Color> colors = [
          Colors.teal.shade600,
          Theme.of(context).colorScheme.primary,
          Colors.green.shade600,
          Colors.orange.shade600,
          Colors.purple.shade600,
          Colors.red.shade600,
          Colors.indigo.shade600,
          Colors.brown.shade600,
        ];        // Calcular el total para porcentajes relativos
        double totalRatio = validRatios.values.fold(0.0, (sum, ratio) => sum + ratio);

        // Ordenar ratios de mayor a menor
        List<MapEntry<String, double>> sortedRatios = validRatios.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        int colorIndex = 0;
        for (var entry in sortedRatios) {
          double percentage = (entry.value / totalRatio) * 100;
          sections.add(
            PieChartSectionData(
              color: colors[colorIndex % colors.length],
              value: percentage,
              title: percentage >= 5.0 ? '${entry.value.toStringAsFixed(1)}%' : '',
              radius: isMobile ? 70 : 100,
              titleStyle: TextStyle(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
          colorIndex++;
        }

        return Container(
          height: isMobile ? 300 : 350,
          child: isMobile
              ? Column(
                  children: [
                    // Gráfico arriba en móviles
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Leyenda abajo en móviles
                    Expanded(
                      flex: 1,
                      child: _buildRatiosLegend(colors, isMobile, validRatios),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Gráfico a la izquierda en tablets/desktop
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Leyenda a la derecha en tablets/desktop
                    Expanded(
                      flex: 1,
                      child: _buildRatiosLegend(colors, isMobile, validRatios),
                    ),
                  ],
                ),
        );
      },
    );
  }
  // Widget de leyenda para el gráfico de ratios
  Widget _buildRatiosLegend(List<Color> colors, bool isMobile, Map<String, double> validRatios) {
    // Ordenar ratios de mayor a menor
    List<MapEntry<String, double>> sortedRatios = validRatios.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedRatios.map((entry) {
          int index = sortedRatios.indexOf(entry);
          
          return Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 6.0 : 8.0),
            child: Row(
              children: [
                Container(
                  width: isMobile ? 12 : 16,
                  height: isMobile ? 12 : 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Ratio: ${entry.value.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 10 : 11,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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
              'Inicia sesión para ver los dividendos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: StreamBuilder<List<Investment>>(
        stream: _firestoreService.getInvestments(),
        builder: (context, snapshot) {          // Calcular el total de dividendos y inversiones con dividendos para el subtítulo cuando está contraído
          double totalDividends = 0.0;
          int investmentsWithDividends = 0;
          int totalInvestments = 0;
          if (snapshot.hasData && snapshot.data != null) {
            totalInvestments = snapshot.data!.length;
            for (var investment in snapshot.data!) {
              bool hasGeneratedDividends = false;
              if (investment.history != null) {
                for (var movement in investment.history!) {
                  if (movement['type'] == 'dividendo') {
                    totalDividends += (movement['amount'] as num?)?.toDouble() ?? 0.0;
                    hasGeneratedDividends = true;
                  }
                }
              }
              if (hasGeneratedDividends) {
                investmentsWithDividends++;
              }
            }
          }return ExpansionTile(
            leading: Icon(
              Icons.paid,
              color: Colors.green.shade600,
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Text(
              'Análisis de Dividendos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  Text(
                    '$investmentsWithDividends/$totalInvestments inversiones con dividendos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Total: ${_formatCurrency(totalDividends, 'COP')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            initiallyExpanded: false, // Siempre inicia contraído
            childrenPadding: const EdgeInsets.only(bottom: 8.0),
        children: [
          StreamBuilder<List<Investment>>(
            stream: _firestoreService.getInvestments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error al cargar datos: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.paid,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay dividendos registrados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final investments = snapshot.data!;
              _processDividendData(investments);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros
                    _buildFiltersSection(),
                    
                    // Resumen
                    if (_totalDividends > 0) ...[                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.paid, color: Colors.green.shade600),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Dividendos',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(_totalDividends, 'COP'),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],                    // Gráfico de barras por fecha
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dividendos por Mes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBarChart(),
                        ],
                      ),
                    ),                    // Gráfico de pastel por inversión
                    Container(
                      margin: const EdgeInsets.all(16.2),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distribución de Dividendos por Inversión',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPieChart(),
                        ],
                      ),
                    ),                    // Nuevo: Gráfico de pastel para ratios de dividendos
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Colors.teal.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ratios de Rendimiento por Dividendos',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Porcentaje que representan los dividendos del total invertido en cada inversión',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRatiosPieChart(),
                        ],
                      ),
                    ),
                  ],
                  ),
              );
            },
          ),
        ],
      );
    },
  ),
);
  }
}

// Clase para datos de dividendos
class DividendData {
  final DateTime date;
  final double amount;
  final String investmentName;
  final String investmentType;
  final String currency;

  DividendData({
    required this.date,
    required this.amount,
    required this.investmentName,
    required this.investmentType,
    required this.currency,
  });
}
