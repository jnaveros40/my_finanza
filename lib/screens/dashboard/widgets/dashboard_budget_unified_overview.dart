import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:mis_finanza/models/budget.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';

class DashboardBudgetUnifiedOverview extends StatefulWidget {
  final List<Budget> budgets;
  final List<Movement> movements;
  final List<Category> categories;
  final String? initialBudgetId;
  final Function(String?) onBudgetSelected;

  const DashboardBudgetUnifiedOverview({
    super.key,
    required this.budgets,
    required this.movements,
    required this.categories,
    this.initialBudgetId,
    required this.onBudgetSelected,
  });

  @override
  State<DashboardBudgetUnifiedOverview> createState() => _DashboardBudgetUnifiedOverviewState();
}

class _DashboardBudgetUnifiedOverviewState extends State<DashboardBudgetUnifiedOverview> {
  String? _selectedBudgetId;

  @override
  void initState() {
    super.initState();
    _selectedBudgetId = widget.initialBudgetId;
    if (_selectedBudgetId == null && widget.budgets.isNotEmpty) {
      final now = DateTime.now();
      final currentMonthYear = DateFormat('yyyy-MM').format(now);
      final currentMonthBudget = widget.budgets.firstWhereOrNull((b) => b.monthYear == currentMonthYear);
      if (currentMonthBudget != null) {
        _selectedBudgetId = currentMonthBudget.id;
      } else {
        _selectedBudgetId = widget.budgets.first.id;
      }
    }
  }

  // Colores adaptativos para diferentes tipos de presupuesto
  Color _getTypeColor(String type, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (type.toLowerCase()) {
      case 'necesidades':
      case 'needs':
        return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600;
      case 'deseos':
      case 'wants':
        return isDarkMode ? Colors.purple.shade300 : Colors.purple.shade600;
      case 'ahorros':
      case 'savings':
        return isDarkMode ? Colors.green.shade300 : Colors.green.shade600;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  // Colores de estado para progreso
  Color _getProgressStatusColor(double progress, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (progress < 0.5) {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade600;
    } else if (progress < 0.8) {
      return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade600;
    } else if (progress < 0.9) {
      return isDarkMode ? Colors.deepOrange.shade300 : Colors.deepOrange.shade600;
    } else {
      return isDarkMode ? Colors.red.shade300 : Colors.red.shade600;
    }
  }
  // Color de texto adaptativo
  Color _getTextColor(BuildContext context, {bool isSecondary = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isSecondary) {
      return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
    return isDarkMode ? Colors.white : Colors.black;
  }

  // Color de iconos adaptativo para alto contraste
  Color _getIconColor(BuildContext context) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isHighContrast) {
      // En modo alto contraste, usar colores que garanticen máximo contraste
      return isDarkMode ? Colors.black : Colors.white;
    } else {
      // En modo normal, usar el color primario del tema
      return Theme.of(context).colorScheme.primary;
    }
  }
  @override
  Widget build(BuildContext context) {
    final selectedBudget = widget.budgets.firstWhereOrNull((b) => b.id == _selectedBudgetId);
    final budgetProgress = _calculateBudgetProgress(selectedBudget, widget.movements, widget.categories);
    final expenseByType = _calculateExpenseByBudgetType(selectedBudget, widget.movements, widget.categories);
    final totalExpenseByType = expenseByType.values.fold(0.0, (sum, amount) => sum + amount);

    //print('\n=== DEBUG: Dashboard Build Method ===');
    //print('Selected Budget ID: $_selectedBudgetId');
    if (selectedBudget != null) {
      //print('Selected Budget Details:');
      //print('  - Month: ${selectedBudget.monthYear}');
      //print('  - Total Budgeted: ${selectedBudget.totalBudgeted}');
      //print('  - Needs %: ${selectedBudget.needsPercentage}');
      //print('  - Wants %: ${selectedBudget.wantsPercentage}');
      //print('  - Savings %: ${selectedBudget.savingsPercentage}');
    }

    // Progreso por tipo
    final needsBudget = selectedBudget != null ? selectedBudget.totalBudgeted * (selectedBudget.needsPercentage / 100) : 0.0;
    final wantsBudget = selectedBudget != null ? selectedBudget.totalBudgeted * (selectedBudget.wantsPercentage / 100) : 0.0;
    final savingsBudget = selectedBudget != null ? selectedBudget.totalBudgeted * (selectedBudget.savingsPercentage / 100) : 0.0;
    final needsSpent = expenseByType['Necesidades'] ?? 0.0;
    final wantsSpent = expenseByType['Deseos'] ?? 0.0;
    final savingsSpent = expenseByType['Ahorros'] ?? 0.0;

    //print('\nBudget Calculations:');
    //print('  - Needs Budget: $needsBudget (${selectedBudget?.needsPercentage ?? 0}%)');
    //print('  - Wants Budget: $wantsBudget (${selectedBudget?.wantsPercentage ?? 0}%)');
    //print('  - Savings Budget: $savingsBudget (${selectedBudget?.savingsPercentage ?? 0}%)');
    
    //print('\nSpent by Type:');
    //print('  - Needs Spent: $needsSpent');
    //print('  - Wants Spent: $wantsSpent');
    //print('  - Savings Spent: $savingsSpent');

    final needsProgress = needsBudget > 0 ? (needsSpent / needsBudget).clamp(0.0, 1.0) : 0.0;
    final wantsProgress = wantsBudget > 0 ? (wantsSpent / wantsBudget).clamp(0.0, 1.0) : 0.0;
    final savingsProgress = savingsBudget > 0 ? (savingsSpent / savingsBudget).clamp(0.0, 1.0) : 0.0;

    //print('\nProgress Calculations:');
    //print('  - Needs Progress: $needsProgress (${(needsProgress * 100).toStringAsFixed(1)}%)');
    //print('  - Wants Progress: $wantsProgress (${(wantsProgress * 100).toStringAsFixed(1)}%)');
    //print('  - Savings Progress: $savingsProgress (${(savingsProgress * 100).toStringAsFixed(1)}%)');
    //print('=== END Dashboard Debug ===\n');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 8.0,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.donut_small_rounded, color: Colors.white, size: 24),
          ),
          title: Text('Presupuestos', 
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                     )),
          subtitle: selectedBudget != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, size: 16, 
                             color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 4),
                        Text('Mes: ${selectedBudget.monthYear}', 
                             style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.account_balance, size: 16, 
                             color: Theme.of(context).colorScheme.secondary),
                        SizedBox(width: 4),
                        Text('Presupuesto: ${_formatCurrency(budgetProgress['totalBudgeted']!, selectedBudget.currency)}', 
                             style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 16, 
                             color: budgetProgress['totalSpent']! > budgetProgress['totalBudgeted']! 
                                   ? Colors.red : Colors.green),
                        SizedBox(width: 4),
                        Text('Gastado: ${_formatCurrency(budgetProgress['totalSpent']!, selectedBudget.currency)}', 
                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                               color: budgetProgress['totalSpent']! > budgetProgress['totalBudgeted']! 
                                     ? Colors.red : null,
                             )),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, 
                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    SizedBox(width: 4),
                    Text('Selecciona un presupuesto para ver detalles', 
                         style: Theme.of(context).textTheme.bodyMedium),                  ],
                ),        children: [
          Padding(
            padding: const EdgeInsets.all(20.0), // Increased padding for better spacing
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Budget Selector
                _buildSectionHeader(context, Icons.calendar_month, 'Selección de Presupuesto'),                SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Presupuesto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.calendar_month),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  value: _selectedBudgetId,
                  items: widget.budgets.map((budget) {
                    return DropdownMenuItem<String>(
                      value: budget.id,
                      child: Text(budget.monthYear, style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (budgetId) {
                    setState(() {
                      _selectedBudgetId = budgetId;
                      widget.onBudgetSelected(budgetId);
                    });
                  },
                  hint: widget.budgets.isEmpty ? Text('No hay presupuestos disponibles', style: Theme.of(context).textTheme.bodyMedium) : null,                  isExpanded: true,
                ),
                ),
                
                if (selectedBudget != null) ...[
                  SizedBox(height: 24),
                  
                  // Section 2: Overall Budget Progress
                  _buildSectionHeader(context, Icons.trending_up, 'Progreso General'),
                  SizedBox(height: 12),                  Container(
                    padding: EdgeInsets.all(20), // Increased padding
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          budgetProgress['progressPercentage']! > 90 
                            ? Colors.red.withOpacity(0.1)
                            : budgetProgress['progressPercentage']! > 75
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          Theme.of(context).colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16), // Increased border radius
                      border: Border.all(
                        color: budgetProgress['progressPercentage']! > 90 
                          ? Colors.red.withOpacity(0.3)
                          : budgetProgress['progressPercentage']! > 75
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Alerta visual si se excede el presupuesto
                        if (budgetProgress['progressPercentage']! > 90) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    budgetProgress['progressPercentage']! > 100 
                                      ? '¡Presupuesto superado!'
                                      : '¡Cerca del límite!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Budget Information Grid
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Presupuestado:', 
                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                         color: _getTextColor(context, isSecondary: true)
                                       )),
                                  Text(_formatCurrency(budgetProgress['totalBudgeted']!, selectedBudget.currency), 
                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                         fontWeight: FontWeight.bold,
                                         color: _getTextColor(context)
                                       )),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Gastado:', 
                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                         color: _getTextColor(context, isSecondary: true)
                                       )),
                                  Text(_formatCurrency(budgetProgress['totalSpent']!, selectedBudget.currency), 
                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                         fontWeight: FontWeight.bold, 
                                         color: budgetProgress['totalSpent']! > budgetProgress['totalBudgeted']! 
                                           ? Colors.red 
                                           : _getTextColor(context)
                                       )),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Disponible:', 
                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                         color: _getTextColor(context, isSecondary: true)
                                       )),
                                  Text(_formatCurrency(budgetProgress['totalRemaining']!, selectedBudget.currency), 
                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                         color: budgetProgress['totalRemaining']! < 0 
                                           ? Colors.red 
                                           : Colors.green,
                                         fontWeight: FontWeight.bold,
                                       )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        // Barra de progreso mejorada con gradiente
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (budgetProgress['progressPercentage']! / 100).clamp(0.0, 1.0),
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                budgetProgress['progressPercentage']! > 100 
                                  ? Colors.red
                                  : budgetProgress['progressPercentage']! > 75
                                    ? Colors.orange
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${budgetProgress['progressPercentage']!.toStringAsFixed(1)}% utilizado', 
                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                            if (budgetProgress['progressPercentage']! > 100)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${(budgetProgress['progressPercentage']! - 100).toStringAsFixed(1)}% excedido',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Información adicional del mes
                  _buildMonthInfo(context, selectedBudget),                  SizedBox(height: 24),
                  
                  // Progreso por tipo - Sección mejorada
                  _buildSectionHeader(context, Icons.analytics_outlined, 'Progreso por tipo'),
                  SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTypeProgress(context, 'Necesidades', needsProgress, needsSpent, needsBudget, selectedBudget.currency, _getTypeColor('necesidades', context), Icons.home),
                        SizedBox(height: 12),
                        Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                        SizedBox(height: 12),
                        _buildTypeProgress(context, 'Deseos', wantsProgress, wantsSpent, wantsBudget, selectedBudget.currency, _getTypeColor('deseos', context), Icons.shopping_bag),
                        SizedBox(height: 12),
                        Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                        SizedBox(height: 12),
                        _buildTypeProgress(context, 'Ahorros', savingsProgress, savingsSpent, savingsBudget, selectedBudget.currency, _getTypeColor('ahorros', context), Icons.savings),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Gráfico de pastel mejorado - Sección mejorada
                  _buildSectionHeader(context, Icons.pie_chart, 'Distribución por tipo'),                  SizedBox(height: 16),
                  
                  if (totalExpenseByType > 0) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface.withOpacity(0.9),
                            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Título de la sección con estadísticas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gráfico de Distribución',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Total: ${_formatCurrency(totalExpenseByType, selectedBudget.currency)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          // Gráfico de pastel mejorado
                          AspectRatio(
                            aspectRatio: 1.3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(8),
                              child: PieChart(
                                PieChartData(
                                  sections: _buildBudgetPieChartSections(expenseByType, context),
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 45,
                                  startDegreeOffset: -90,
                                  borderData: FlBorderData(show: false),
                                  pieTouchData: PieTouchData(
                                    enabled: true,
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      // Añadir interactividad al gráfico
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Leyenda del gráfico mejorada
                          /*Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(context, 'Necesidades', _getTypeColor('necesidades', context), expenseByType['Necesidades'] ?? 0.0, selectedBudget.currency),
                              _buildLegendItem(context, 'Deseos', _getTypeColor('deseos', context), expenseByType['Deseos'] ?? 0.0, selectedBudget.currency),
                              _buildLegendItem(context, 'Ahorros', _getTypeColor('ahorros', context), expenseByType['Ahorros'] ?? 0.0, selectedBudget.currency),
                            ],
                          ),*/
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.pie_chart_outline, 
                              size: 48, 
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sin datos para mostrar',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No hay gastos categorizados por tipo de presupuesto en este período',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),          ),
        ],
      ),
      )
    );
  }

  // Helper method for consistent section headers
  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),            child: Icon(
              icon, 
              color: _getIconColor(context), 
              size: 18
            ),
          ),
          SizedBox(width: 12),
          Text(
            title, 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            )
          ),
          Spacer(),
          Container(
            width: 20,
            height: 2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateBudgetProgress(Budget? selectedBudget, List<Movement> movements, List<Category> categories) {
    if (selectedBudget == null) {
      return {
        'totalBudgeted': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'progressPercentage': 0.0,
      };
    }
    double totalSpent = 0.0;
    final budgetDate = DateFormat('yyyy-MM').parse(selectedBudget.monthYear);
    final startOfBudgetDate = DateTime(budgetDate.year, budgetDate.month, 1);
    final endOfBudgetDate = DateTime(budgetDate.year, budgetDate.month + 1, 0, 23, 59, 59);
    final expenseMovementsForBudget = movements.where((m) {
      final category = categories.firstWhereOrNull((cat) => cat.id == m.categoryId);
      return category != null && category.type == 'expense' &&
        m.dateTime.isAfter(startOfBudgetDate.subtract(Duration(days: 1))) &&
        m.dateTime.isBefore(endOfBudgetDate.add(Duration(days: 1)));
    }).toList();
    for (var movement in expenseMovementsForBudget) {
      totalSpent += movement.amount.abs();
    }
    double totalBudgeted = selectedBudget.totalBudgeted;
    double totalRemaining = totalBudgeted - totalSpent;
    double progressPercentage = (totalBudgeted > 0) ? (totalSpent / totalBudgeted) * 100 : 0.0;
    return {
      'totalBudgeted': totalBudgeted,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'progressPercentage': progressPercentage,
    };
  }  Map<String, double> _calculateExpenseByBudgetType(Budget? selectedBudget, List<Movement> movements, List<Category> categories) {
    Map<String, double> expenseByType = {
      'Necesidades': 0.0,
      'Deseos': 0.0,
      'Ahorros': 0.0,
    };
    
    //print('\n=== DEBUG: _calculateExpenseByBudgetType ===');
    //print('Selected Budget: ${selectedBudget?.monthYear}');
    //print('Total movements: ${movements.length}');
    //print('Total categories: ${categories.length}');
    
    if (selectedBudget == null) {
      //print('No budget selected, returning empty expense by type');
      return expenseByType;
    }
      //print('Budget month-year: ${selectedBudget.monthYear}');
    
    final expenseMovements = movements.where((m) {
      final movementMonthYear = DateFormat('yyyy-MM').format(m.dateTime);
      return m.type == 'expense' && movementMonthYear == selectedBudget.monthYear;
    });
    
    //print('Expense movements in period: ${expenseMovements.length}');
    
    for (var movement in expenseMovements) {
      final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
      //print('\nProcessing movement:');
      //print('  - Amount: ${movement.amount}');
      //print('  - Date: ${movement.dateTime}');
      //print('  - Category ID: ${movement.categoryId}');
      //print('  - Category found: ${category?.name ?? "NOT FOUND"}');
      //print('  - Budget Category: ${category?.budgetCategory ?? "NULL"}');
      
      if (category != null) {
        switch (category.budgetCategory?.toLowerCase()) {
          case 'needs':
          case 'necesidades':
            expenseByType['Necesidades'] = (expenseByType['Necesidades'] ?? 0.0) + movement.amount.abs();
            //print('  → Added to NECESIDADES: ${movement.amount.abs()}');
            break;
          case 'wants':
          case 'deseos':
            expenseByType['Deseos'] = (expenseByType['Deseos'] ?? 0.0) + movement.amount.abs();
            //print('  → Added to DESEOS: ${movement.amount.abs()}');
            break;
          case 'savings':
          case 'ahorros':
            expenseByType['Ahorros'] = (expenseByType['Ahorros'] ?? 0.0) + movement.amount.abs();
            //print('  → Added to AHORROS: ${movement.amount.abs()}');
            break;
          default:
            //print('  → NO CATEGORY MATCH - budgetCategory: "${category.budgetCategory}"');
            break;
        }
      } else {
        //print('  → Category not found for categoryId: ${movement.categoryId}');
      }
    }
    
    //print('\nFinal expense by type:');
    //print('  - Necesidades: ${expenseByType['Necesidades']}');
    //print('  - Deseos: ${expenseByType['Deseos']}');
    //print('  - Ahorros: ${expenseByType['Ahorros']}');
    //print('=== END DEBUG ===\n');
    
    return expenseByType;
  }
  List<PieChartSectionData> _buildBudgetPieChartSections(Map<String, double> expenseByType, BuildContext context) {
    final totalExpense = expenseByType.values.fold(0.0, (sum, amount) => sum + amount);
    if (totalExpense == 0) return [];
    
    return expenseByType.entries.map((entry) {
      final type = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalExpense) * 100;
      final color = _getTypeColor(type, context);
      
      if (percentage < 1.0 && percentage > 0) {
        return PieChartSectionData(
          color: color,
          value: amount,
          title: '<1%',
          radius: 85,
          titleStyle: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black.withOpacity(0.5),
                offset: Offset(1, 1),
              ),
            ],
          ),
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      } else if (percentage >= 1.0) {
        return PieChartSectionData(
          color: color,
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 85,
          titleStyle: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black.withOpacity(0.5),
                offset: Offset(1, 1),
              ),
            ],
          ),
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      } else {
        return PieChartSectionData(value: 0);
      }
    }).where((section) => section.value > 0).toList();
  }

  Widget _buildTypeProgress(BuildContext context, String label, double progress, double spent, double budget, String currency, Color color, IconData icon) {final percent = (progress * 100).clamp(0, 100);
    final available = budget - spent;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: 8),              Text(
                label, 
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: _getTextColor(context)
                )
              ),
            ],
          ),
          const SizedBox(height: 8),          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.7),
                            color,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [              Text(
                'Porcentaje utilizado: ', 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: _getTextColor(context, isSecondary: true)
                )
              ),
              Text(
                '${percent.toStringAsFixed(1)}%', 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: _getProgressStatusColor(progress, context)
                )
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [              Text(
                'Utilizado: ', 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: _getTextColor(context, isSecondary: true)
                )
              ),
              Text(
                _formatCurrency(spent, currency), 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red, 
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [              Text(
                'Disponible: ', 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: _getTextColor(context, isSecondary: true)
                )
              ),
              Text(
                _formatCurrency(available < 0 ? 0 : available, currency), 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green, 
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
        ],
      ),
    );  }
  Widget _buildMonthInfo(BuildContext context, Budget selectedBudget) {
    final budgetDate = DateFormat('yyyy-MM').parse(selectedBudget.monthYear);
    final now = DateTime.now();
    final daysInMonth = DateTime(budgetDate.year, budgetDate.month + 1, 0).day;
    final currentDay = budgetDate.year == now.year && budgetDate.month == now.month ? now.day : daysInMonth;
    final daysRemaining = daysInMonth - currentDay;
    final daysPassed = currentDay;
    final monthProgress = (daysPassed / daysInMonth);
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, 
                   color: Theme.of(context).colorScheme.primary, 
                   size: 18),
              SizedBox(width: 8),
              Text('Información del Mes', 
                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
                     fontWeight: FontWeight.bold,
                     color: Theme.of(context).colorScheme.primary,
                   )),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMonthInfoItem(
                context,
                Icons.today,
                'Días transcurridos',
                '$daysPassed',
                Colors.blue,
              ),
              _buildMonthInfoItem(
                context,
                Icons.schedule,
                'Días restantes',
                '$daysRemaining',
                daysRemaining <= 5 ? Colors.red : Colors.orange,
              ),
              _buildMonthInfoItem(
                context,
                Icons.pie_chart,
                'Progreso mes',
                '${(monthProgress * 100).toStringAsFixed(0)}%',
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: monthProgress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthInfoItem(BuildContext context, IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(value, 
             style: Theme.of(context).textTheme.titleSmall?.copyWith(
               fontWeight: FontWeight.bold, 
               color: color,
             )),
        Text(label, 
             style: Theme.of(context).textTheme.bodySmall?.copyWith(
               fontSize: 10,
               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
             ),
             textAlign: TextAlign.center),
      ],
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.currency(locale: 'es_CO', symbol: _getCurrencySymbol(currencyCode), decimalDigits: 0);
    return format.format(amount);
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'COP':
        return '\$';
      
      case 'EUR':
        return '€';
      default:
        return currencyCode;
    }
  }
/*
 // Helper method para elementos de leyenda del gráfico
  Widget _buildLegendItem(BuildContext context, String label, Color color, double amount, String currency) {
    return Flexible(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  _formatCurrency(amount, currency),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mejoras de diseño responsivo
  Widget _buildResponsiveLayout(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        
        return Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 800 : double.infinity,
          ),
          child: child,
        );
      },
    );
  }

  // Helper method para obtener espaciado adaptivo
  double _getAdaptiveSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 24.0; // Pantallas grandes
    } else if (screenWidth > 400) {
      return 20.0; // Pantallas medianas
    } else {
      return 16.0; // Pantallas pequeñas
    }
  }*/
}
