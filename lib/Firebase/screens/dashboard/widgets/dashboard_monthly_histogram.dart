import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mis_finanza/models/movement.dart';

enum HistogramViewMode { comparison, netFlow }

class DashboardMonthlyHistogram extends StatefulWidget {
  final List<Movement> movements;
  final String? initialMovementType;
  final Function(String?) onMovementTypeSelected;
  
  const DashboardMonthlyHistogram({
    super.key,
    required this.movements,
    this.initialMovementType = 'comparison',
    required this.onMovementTypeSelected,
  });

  @override
  _DashboardMonthlyHistogramState createState() => _DashboardMonthlyHistogramState();
}

class _DashboardMonthlyHistogramState extends State<DashboardMonthlyHistogram> {
  HistogramViewMode _viewMode = HistogramViewMode.comparison;
  int _selectedMonths = 3; // Período por defecto: últimos 12 meses

  @override
  void initState() {
    super.initState();
    // Initialize with comparison view mode
  }
  Map<String, double> _getIncomeByMonth() {
    final incomeMovements = widget.movements.where((m) => m.type == 'income');
    return _groupMovementsByMonth(incomeMovements);
  }

  Map<String, double> _getExpensesByMonth() {
    final expenseMovements = widget.movements.where((m) => m.type == 'expense');
    return _groupMovementsByMonth(expenseMovements);
  }

  Map<String, double> _getPaymentsByMonth() {
    final paymentMovements = widget.movements.where((m) => m.type == 'payment');
    return _groupMovementsByMonth(paymentMovements);
  }

  Map<String, double> _getTransfersByMonth() {
    final transferMovements = widget.movements.where((m) => m.type == 'transfer');
    return _groupMovementsByMonth(transferMovements);
  }
  Map<String, double> _groupMovementsByMonth(Iterable<Movement> movements) {
    final Map<String, double> totalByMonth = {};
    
    // Calcular la fecha límite basada en el período seleccionado
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month - _selectedMonths + 1, 1);
    
    for (var movement in movements) {
      // Filtrar movimientos dentro del período seleccionado
      if (movement.dateTime.isAfter(cutoffDate.subtract(Duration(days: 1)))) {
        final monthYear = DateFormat('yyyy-MM').format(movement.dateTime);
        totalByMonth.update(
          monthYear, 
          (value) => value + movement.amount, 
          ifAbsent: () => movement.amount
        );
      }
    }
    
    return totalByMonth;
  }
  Widget _buildInformativeSubtitle() {
    final incomeData = _getIncomeByMonth();
    final expenseData = _getExpensesByMonth();
    final paymentData = _getPaymentsByMonth();
    final transferData = _getTransfersByMonth();
    
    if (incomeData.isEmpty && expenseData.isEmpty && paymentData.isEmpty && transferData.isEmpty) {
      return Text('Sin datos financieros', style: Theme.of(context).textTheme.bodySmall);
    }    // Get current month data
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final currentIncome = incomeData[currentMonth] ?? 0.0;
    final currentExpenses = expenseData[currentMonth] ?? 0.0;
    final currentPayments = paymentData[currentMonth] ?? 0.0;
    final currentTransfers = transferData[currentMonth] ?? 0.0;
    
    // Para el subtítulo: en modo comparación incluye todo, en flujo neto solo ingresos - gastos
    final currentNetFlow = _viewMode == HistogramViewMode.netFlow 
        ? currentIncome - currentExpenses 
        : currentIncome - currentExpenses - currentPayments.abs() - currentTransfers.abs();    // Find best and worst months
    final netFlowByMonth = <String, double>{};
    final allMonths = {...incomeData.keys, ...expenseData.keys, ...paymentData.keys, ...transferData.keys};
    
    for (final month in allMonths) {
      final income = incomeData[month] ?? 0.0;
      final expenses = expenseData[month] ?? 0.0;
      final payments = paymentData[month] ?? 0.0;
      final transfers = transferData[month] ?? 0.0;
      
      // Calcular flujo neto según el modo de vista
      if (_viewMode == HistogramViewMode.netFlow) {
        // Solo ingresos - gastos
        netFlowByMonth[month] = income - expenses;
      } else {
        // Incluir todos los movimientos
        netFlowByMonth[month] = income - expenses - payments.abs() - transfers.abs();
      }
    }

    final sortedNetFlow = netFlowByMonth.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestMonth = sortedNetFlow.isNotEmpty ? sortedNetFlow.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              currentNetFlow >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: currentNetFlow >= 0 ? Colors.green : Colors.red,
            ),
            SizedBox(width: 4),
            Text(
              'Este mes: ${_formatCurrency(currentNetFlow)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: currentNetFlow >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),        if (bestMonth != null) ...[
          SizedBox(height: 2),
          Text(
            'Mejor: ${_formatMonthName(bestMonth.key)} (${_formatCurrency(bestMonth.value)})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
        SizedBox(height: 2),
        Text(
          'Período: Últimos $_selectedMonths meses',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final incomeData = _getIncomeByMonth();
    final expenseData = _getExpensesByMonth();
    final paymentData = _getPaymentsByMonth();
    final transferData = _getTransfersByMonth();
    
    if (incomeData.isEmpty && expenseData.isEmpty && paymentData.isEmpty && transferData.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
          title: Text('Histograma Mensual', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('Sin datos financieros disponibles', style: Theme.of(context).textTheme.bodySmall),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No hay movimientos financieros para mostrar el histograma mensual.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(
          Icons.bar_chart, 
          color: _viewMode == HistogramViewMode.comparison 
            ? Theme.of(context).colorScheme.primary 
            : Colors.orange
        ),
        title: Text('Histograma Mensual', style: Theme.of(context).textTheme.titleLarge),
        subtitle: _buildInformativeSubtitle(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View Mode Toggle
                Row(
                  children: [
                    Icon(Icons.view_module, size: 20, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Modo de Vista', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _viewMode = HistogramViewMode.comparison),
                        icon: Icon(Icons.compare_arrows, size: 18),
                        label: Text('Comparación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _viewMode == HistogramViewMode.comparison 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.surface,
                          foregroundColor: _viewMode == HistogramViewMode.comparison 
                            ? Colors.white 
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _viewMode = HistogramViewMode.netFlow),
                        icon: Icon(Icons.trending_up, size: 18),
                        label: Text('Flujo Neto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _viewMode == HistogramViewMode.netFlow 
                            ? Colors.orange 
                            : Theme.of(context).colorScheme.surface,
                          foregroundColor: _viewMode == HistogramViewMode.netFlow 
                            ? Colors.white 
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),                  ],
                ),
                SizedBox(height: 24),

                // Period Filter
                Row(
                  children: [
                    Icon(Icons.date_range, size: 20, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Período', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonths,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 2, child: Text('Últimos 2 meses')),
                        DropdownMenuItem(value: 3, child: Text('Últimos 3 meses')),
                        DropdownMenuItem(value: 6, child: Text('Últimos 6 meses')),
                        DropdownMenuItem(value: 9, child: Text('Últimos 9 meses')),
                        DropdownMenuItem(value: 12, child: Text('Últimos 12 meses')),
                      ],
                      onChanged: (months) {
                        if (months != null) {
                          setState(() {
                            _selectedMonths = months;
                          });
                        }
                      },
                      icon: Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Chart Section
                Divider(),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _viewMode == HistogramViewMode.comparison ? Icons.compare_arrows : Icons.trending_up,
                      size: 20, 
                      color: _viewMode == HistogramViewMode.comparison 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.orange
                    ),
                    SizedBox(width: 8),                    Text(
                      _viewMode == HistogramViewMode.comparison 
                        ? 'Comparación de Movimientos' 
                        : 'Flujo de Efectivo Neto',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Spacer(),                    if (_viewMode == HistogramViewMode.comparison) ...[
                      // Leyenda de colores para comparación
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Ingresos', Colors.green),
                          SizedBox(height: 6),
                          _buildLegendItem('Gastos', Colors.red),
                          SizedBox(height: 6),
                          _buildLegendItem('Pagos', Colors.orange),
                          SizedBox(height: 6),
                          _buildLegendItem('Transferencias', Colors.blue),
                        ],
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16),                // Chart
                AspectRatio(
                  aspectRatio: 1.8,
                  child: _viewMode == HistogramViewMode.comparison 
                    ? _buildComparisonChart(incomeData, expenseData, paymentData, transferData)
                    : _buildNetFlowChart(incomeData, expenseData, paymentData, transferData),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
  Widget _buildComparisonChart(Map<String, double> incomeData, Map<String, double> expenseData, Map<String, double> paymentData, Map<String, double> transferData) {
    final allMonths = {...incomeData.keys, ...expenseData.keys, ...paymentData.keys, ...transferData.keys}.toList()..sort();
    
    if (allMonths.isEmpty) return Container();

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < allMonths.length; i++) {
      final month = allMonths[i];
      final income = incomeData[month] ?? 0.0;
      final expenses = (expenseData[month] ?? 0.0).abs(); // Use absolute value for expenses
      final payments = (paymentData[month] ?? 0.0).abs(); // Use absolute value for payments
      final transfers = (transferData[month] ?? 0.0).abs(); // Use absolute value for transfers
      
      maxY = [maxY, income, expenses, payments, transfers].reduce((a, b) => a > b ? a : b);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 10,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 10,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: payments,
              color: Colors.orange,
              width: 10,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: transfers,
              color: Colors.blue,
              width: 10,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ],
        ),
      );
    }

    maxY = maxY * 1.1; // Add 10% padding

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < allMonths.length) {
                  final monthYear = allMonths[index];
                  final formattedMonth = DateFormat('MMM yy')
                    .format(DateFormat('yyyy-MM').parse(monthYear));
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        formattedMonth,
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
                  _formatLargeCurrency(value),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        barGroups: barGroups,
        gridData: FlGridData(show: true, drawVerticalLine: false),
      ),
    );
  }  Widget _buildNetFlowChart(Map<String, double> incomeData, Map<String, double> expenseData, Map<String, double> paymentData, Map<String, double> transferData) {
    // Para flujo neto, solo consideramos ingresos y gastos
    final allMonths = {...incomeData.keys, ...expenseData.keys}.toList()..sort();
    
    if (allMonths.isEmpty) return Container();

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    double minY = 0;

    for (int i = 0; i < allMonths.length; i++) {
      final month = allMonths[i];
      final income = incomeData[month] ?? 0.0;
      final expenses = expenseData[month] ?? 0.0;
      // Solo ingresos - gastos (sin pagos ni transferencias)
      final netFlow = income - expenses;
      
      if (netFlow > maxY) maxY = netFlow;
      if (netFlow < minY) minY = netFlow;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: netFlow,
              color: netFlow >= 0 ? Colors.green : Colors.red,
              width: 16,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    // Add padding
    final range = maxY - minY;
    maxY = maxY + (range * 0.1);
    minY = minY - (range * 0.1);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: minY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < allMonths.length) {
                  final monthYear = allMonths[index];
                  final formattedMonth = DateFormat('MMM yy')
                    .format(DateFormat('yyyy-MM').parse(monthYear));
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        formattedMonth,
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
                  _formatLargeCurrency(value),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        barGroups: barGroups,        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 1000,
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: Theme.of(context).dividerColor,
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatMonthName(String monthYear) {
    try {
      final date = DateFormat('yyyy-MM').parse(monthYear);
      return DateFormat('MMM yyyy', 'es_CO').format(date);
    } catch (e) {
      return monthYear;
    }
  }

  String _formatLargeCurrency(double amount) {
    final absoluteAmount = amount.abs();
    
    if (absoluteAmount >= 1000000) {
      final formatted = NumberFormat.compactCurrency(
        locale: 'es_CO',
        symbol: '',
        decimalDigits: 1,
      ).format(absoluteAmount);
      return '${formatted.trim()}M';
    } else if (absoluteAmount >= 1000) {
      final formatted = NumberFormat.compactCurrency(
        locale: 'es_CO',
        symbol: '',
        decimalDigits: 1,
      ).format(absoluteAmount);
      return '${formatted.trim()}K';
    } else {
      return NumberFormat.currency(
        locale: 'es_CO',
        symbol: '',
        decimalDigits: 0,
      ).format(amount);
    }
  }
}
