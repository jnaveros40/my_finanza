// dashboard_filtered_movements_chart.dart
// Componente modular para mostrar el análisis detallado de movimientos con filtros (gráfico de barras y pastel)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'dart:async'; // Para el Timer de debouncing
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:mis_finanza/models/account.dart';

class DashboardFilteredMovementsChart extends StatefulWidget {
  final List<Movement> movements;
  final List<Account> accounts;
  final List<Category> categories;
  final String? initialFilteredMovementType;
  final Set<String>? initialFilteredCategories;
  final Set<String>? initialFilteredAccounts;
  final String? initialPieChartGrouping;
  final Function(String)? onFilteredMovementTypeChanged;
  final Function(Set<String>)? onFilteredCategoriesChanged;
  final Function(Set<String>)? onFilteredAccountsChanged;
  final Function(String)? onPieChartGroupingChanged;

  const DashboardFilteredMovementsChart({
    super.key,
    required this.movements,
    required this.accounts,
    required this.categories,
    this.initialFilteredMovementType = 'all',
    this.initialFilteredCategories,
    this.initialFilteredAccounts,
    this.initialPieChartGrouping = 'account',
    this.onFilteredMovementTypeChanged,
    this.onFilteredCategoriesChanged,
    this.onFilteredAccountsChanged,
    this.onPieChartGroupingChanged,
  });

  @override
  _DashboardFilteredMovementsChartState createState() => _DashboardFilteredMovementsChartState();
}

class _DashboardFilteredMovementsChartState extends State<DashboardFilteredMovementsChart> {
  //final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilteredMovementType = 'all';
  Set<String> _selectedFilteredCategories = {};
  Set<String> _selectedFilteredAccounts = {};
  String _selectedPieChartGrouping = 'account';
  
  // Variable para el temporizador de debouncing
  Timer? _filterTimer;
  
  // Lista fija de tipos de movimiento para el filtro
  final List<String> _movementTypesForFilter = [
    'all',
    'income',
    'expense',
    'transfer',
    'payment'
  ];
  
  // Lista fija de opciones de agrupación para el gráfico de pastel dinámico
  final Map<String, String> _pieChartGroupingOptions = {
    'account': 'Por Cuenta',
    'category': 'Por Categoría',
  };

  @override
  void initState() {
    super.initState();
    
    // Inicializar valores desde los props
    _selectedFilteredMovementType = widget.initialFilteredMovementType ?? 'all';
    
    // Inicializar categorías filtradas
    if (widget.initialFilteredCategories != null && widget.initialFilteredCategories!.isNotEmpty) {
      _selectedFilteredCategories = widget.initialFilteredCategories!;
    } else {
      // Por defecto, seleccionar todas las categorías del tipo seleccionado
      _initializeCategories();
    }
    
    // Inicializar cuentas filtradas
    if (widget.initialFilteredAccounts != null && widget.initialFilteredAccounts!.isNotEmpty) {
      _selectedFilteredAccounts = widget.initialFilteredAccounts!;
    } else {
      // Por defecto, seleccionar todas las cuentas
      _initializeAccounts();
    }
    
    _selectedPieChartGrouping = widget.initialPieChartGrouping ?? 'account';
  }
  
  void _initializeCategories() {
    final filteredCategories = widget.categories.where((category) {
      if (_selectedFilteredMovementType == 'all') {
        return true;
      }
      return category.type == _selectedFilteredMovementType;
    }).toList();
    
    if (filteredCategories.isNotEmpty) {
      _selectedFilteredCategories = filteredCategories
          .where((c) => c.id != null)
          .map((c) => c.id!)
          .toSet();
    }
  }
  
  void _initializeAccounts() {
    if (widget.accounts.isNotEmpty) {
      _selectedFilteredAccounts = widget.accounts
          .where((a) => a.id != null)
          .map((a) => a.id!)
          .toSet();
    }
  }

  @override
  void dispose() {
    // Limpiar el temporizador en dispose
    _filterTimer?.cancel();
    super.dispose();
  }
  // Helper para obtener el texto a mostrar para el tipo de movimiento
  String _getMovementTypeText(String type) {
    switch (type) {
      case 'all': return 'Todos';
      case 'income': return 'Ingreso';
      case 'expense': return 'Gasto';
      case 'transfer': return 'Transferencia';
      case 'payment': return 'Pago';
      case 'debt_payment': return 'Pago de Deuda';
      case 'investment': return 'Inversión';
      default: return type;
    }
  }

  // Helper para obtener el icono para el tipo de movimiento
  IconData _getMovementTypeIcon(String type) {
    switch (type) {
      case 'all': return Icons.all_inclusive;
      case 'income': return Icons.trending_up;
      case 'expense': return Icons.trending_down;
      case 'transfer': return Icons.swap_horiz;
      case 'payment': return Icons.payment;
      case 'debt_payment': return Icons.account_balance;
      case 'investment': return Icons.show_chart;
      default: return Icons.help_outline;
    }
  }

  // Helper para obtener el color para el tipo de movimiento
  Color _getMovementTypeColor(String type) {
    switch (type) {
      case 'all': return Colors.blue;
      case 'income': return Colors.green;
      case 'expense': return Colors.red;
      case 'transfer': return Colors.orange;
      case 'payment': return Colors.purple;
      case 'debt_payment': return Colors.brown;
      case 'investment': return Colors.teal;
      default: return Colors.grey;
    }
  }

  // Helper para obtener el símbolo de moneda
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'COP':
        return '\$';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return currencyCode;
    }
  }

  // Helper para formatear montos de moneda (sin decimales para resúmenes)
  String _formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      locale: 'es_CO',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  // Helper para formatear montos de moneda (con decimales para detalles)
  String _formatCurrency2(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      locale: 'es_CO',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Helper para formatear montos grandes
  String _formatLargeCurrency(double amount, String currencyCode) {
    final absoluteAmount = amount.abs();

    if (absoluteAmount >= 1000000) {
      final formatted = NumberFormat.compactCurrency(
        locale: 'es_CO',
        symbol: '',
        decimalDigits: 1,
      ).format(amount / 1000000);
      return '${formatted.trim()}M';
    } else if (absoluteAmount >= 1000) {
       final formatted = NumberFormat.compactCurrency(
          locale: 'es_CO',
          symbol: '',
          decimalDigits: 1,
       ).format(amount / 1000);
       return '${formatted.trim()}K';
    } else {
      final format = NumberFormat.currency(
        locale: 'es_CO',
        symbol: '',
        decimalDigits: 0,
      );
      return format.format(amount).trim();
    }
  }
  
  // NUEVO HELPER: Leyenda para el Gráfico de Pastel por Cuenta
  Widget _buildPieChartAccountLegend(List<MapEntry<String, double>> sortedEntries, List<Account> accounts, List<Color> colors) {
      List<Widget> legendItems = [];
      int colorIndex = 0;

      for (var entry in sortedEntries) {
          final accountId = entry.key;
          final amount = entry.value;

          // Encontrar el nombre de la cuenta por ID
          final account = accounts.firstWhereOrNull((acc) => acc.id == accountId);
          final accountName = account?.name ?? 'Cuenta Desconocida';

          final legendColor = colors[colorIndex % colors.length];
          colorIndex++;

          legendItems.add(
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                      children: [
                          Container(
                              width: 16,
                              height: 16,
                              color: legendColor,
                              margin: EdgeInsets.only(right: 8),
                          ),
                          Expanded(
                              child: Text(
                                  '$accountName: ${_formatCurrency(amount, 'COP')}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                              ),
                          ),
                      ],
                  ),
              ),
          );
      }

      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: legendItems,
      );
  }

  // NUEVO HELPER: Leyenda para el Gráfico de Pastel por Categoría
  Widget _buildPieChartCategoryLegend(List<MapEntry<String, double>> sortedEntries, List<Category> categories, List<Color> colors) {
      List<Widget> legendItems = [];
      int colorIndex = 0;

      for (var entry in sortedEntries) {
          final categoryId = entry.key;
          final amount = entry.value;

          // Encontrar el nombre de la categoría por ID
          final category = categories.firstWhereOrNull((cat) => cat.id == categoryId);
          final categoryName = category?.name ?? 'Categoría Desconocida';

          final legendColor = colors[colorIndex % colors.length];
          colorIndex++;

          legendItems.add(
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                      children: [
                          Container(
                              width: 16,
                              height: 16,
                              color: legendColor,
                              margin: EdgeInsets.only(right: 8),
                          ),
                          Expanded(
                              child: Text(
                                  '$categoryName: ${_formatCurrency(amount, 'COP')}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                              ),
                          ),
                      ],
                  ),
              ),
          );
      }

      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: legendItems,
      );
  }

  @override
  Widget build(BuildContext context) {
    // Aplicar filtros de tipo, cuenta y categoría
    final filteredMovements = widget.movements.where((movement) {
      // Filtrar por un solo tipo de movimiento o todos
      bool typeMatch = _selectedFilteredMovementType == 'all' || movement.type == _selectedFilteredMovementType;

      bool accountMatch = _selectedFilteredAccounts.isEmpty ||
                        _selectedFilteredAccounts.contains(movement.accountId) ||
                        (movement.destinationAccountId != null && _selectedFilteredAccounts.contains(movement.destinationAccountId));

      // Filtrar categorías
      bool categoryMatch = _selectedFilteredCategories.isEmpty ||
                         _selectedFilteredCategories.contains(movement.categoryId);

      return typeMatch && accountMatch && categoryMatch;
    }).toList();

    // Calcular el total de los movimientos filtrados
    double totalFilteredAmount = 0.0;
    if (_selectedFilteredMovementType == 'all') {
      // Para 'all', sumar ingresos y restar gastos
      for (var movement in filteredMovements) {
        if (movement.type == 'income') {
          totalFilteredAmount += movement.amount;
        } else if (movement.type == 'expense') {
          totalFilteredAmount -= movement.amount;
        }
      }
    } else {
      // Para tipos específicos, sumar el valor ABSOLUTO de los montos
      totalFilteredAmount = filteredMovements.fold(0.0, (sum, movement) => sum + movement.amount.abs());
    }


    // Agrupar movimientos filtrados por DÍA (para el gráfico de barras)
    final Map<DateTime, double> totalAmountByDay = {};

    for (var movement in filteredMovements) {
      // Truncar la fecha a solo el día para agrupar
      final day = DateTime(movement.dateTime.year, movement.dateTime.month, movement.dateTime.day);

      // Calcular el monto con el signo correcto para el GRÁFICO de barras
      double amount = movement.amount;
      // Para gastos y transferencias salientes, el monto es negativo en el gráfico
      if (movement.type == 'expense' || (movement.type == 'transfer' && _selectedFilteredAccounts.contains(movement.accountId))) {
        amount = -amount;
      }
      // Para pagos a CC, si la cuenta seleccionada es la de origen, es una salida (negativo)
      if (movement.type == 'payment' && _selectedFilteredAccounts.contains(movement.accountId)) {
        amount = -amount;
      }
      
      // Si la cuenta seleccionada es la de destino de una transferencia o pago, es una entrada (positivo)
      if ((movement.type == 'transfer' || movement.type == 'payment') && 
           movement.destinationAccountId != null && 
           _selectedFilteredAccounts.contains(movement.destinationAccountId!)) {
        // Si la cuenta de origen TAMBIÉN está seleccionada, evitamos duplicar el monto
        if (!_selectedFilteredAccounts.contains(movement.accountId)) {
          // Lógica para manejar este caso si es necesario
        }
      }

      // Sumar el monto al total del día
      totalAmountByDay.update(day, (value) => value + amount, ifAbsent: () => amount);
    }
    // Si no hay movimientos filtrados, mostrar un mensaje
    if (filteredMovements.isEmpty) {
      String message = 'No hay movimientos que coincidan con los filtros seleccionados.';
      if (_selectedFilteredMovementType != 'all' && widget.movements.isNotEmpty) {
        message = 'No hay movimientos del tipo "${_getMovementTypeText(_selectedFilteredMovementType)}" que coincidan con los filtros seleccionados.';
      }
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(
            Icons.analytics,
            color: Colors.grey,
            size: 28.0,
          ),
          title: Text('Análisis Detallado de Movimientos', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text(
            'Sin movimientos para mostrar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Sin datos para analizar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          message,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }


    // Preparar datos para el gráfico de barras por día
    List<BarChartGroupData> barGroups = [];
    List<DateTime> visibleDates = []; // Para las etiquetas del eje X (fechas)

    // Obtener la lista de días con datos, ordenados cronológicamente
    final sortedDays = totalAmountByDay.keys.toList()..sort();

    // Determinar el color de las barras y el texto del total
    Color barColor = Colors.green; // Color por defecto para ingresos
    String totalText = 'Total del Gráfico:'; // Texto por defecto para 'all'

    switch (_selectedFilteredMovementType) {
      case 'income':
        barColor = Colors.green;
        totalText = 'Total de ingresos:';
        break;
      case 'expense':
        barColor = Colors.red;
        totalText = 'Total de gastos:';
        break;
      case 'transfer':
        barColor = Colors.black; // O el color que prefieras para transferencias
        totalText = 'Total de transferencias:';
        break;
      case 'payment':
        barColor = Colors.orange; // O el color que prefieras para pagos
        totalText = 'Total de pagos realizados:';
        break;
       
      case 'all':
      default:
        // Para 'all', el color de la barra se determina por el signo del monto
        totalText = 'Total del Gráfico:';
        break;
    }


    for (int i = 0; i < sortedDays.length; i++) {
      final day = sortedDays[i];
      double amount = totalAmountByDay[day] ?? 0.0;

      // Mostrar el valor ABSOLUTO en el gráfico si no es 'all'
      if (_selectedFilteredMovementType != 'all') {
        amount = amount.abs(); // Usar el valor absoluto para la altura de la barra
      }

      // Determinar el color de la barra para 'all' según el valor (positivo o negativo)
      Color actualBarColor = barColor;
      if (_selectedFilteredMovementType == 'all') {
        actualBarColor = amount >= 0 ? Colors.green : Colors.red;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount.abs(), // Altura absoluta para mantener las barras hacia arriba
              color: actualBarColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      visibleDates.add(day); // Añadir fecha para el eje X
    }

    // Encontrar el valor máximo absoluto en los datos para el rango del eje Y
    double maxY = 0.0;
    maxY = totalAmountByDay.values.map((amount) => amount.abs()).fold(0.0, (max, amount) => amount > max ? amount : max);
    maxY = maxY * 1.1; // Añadir un 10% de margen en el eje Y


    // Lógica para el gráfico de pastel (por cuenta o por categoría)
    Map<String, double> totalAmountByGrouping = {};
    String pieChartTitle = 'Distribución por ${_selectedPieChartGrouping == 'account' ? 'Cuenta' : 'Categoría'}'; // Título dinámico

    if (_selectedPieChartGrouping == 'account') {
      // Agrupar por cuenta
      for (var movement in filteredMovements) {
        String? accountIdToGroup;

        // Determinar la cuenta a usar para agrupar según el tipo de movimiento
        if (movement.type == 'transfer' || movement.type == 'payment') {
          // Para transferencias o pagos, usar la cuenta de origen si no hay destino
          accountIdToGroup = movement.accountId;
          // Casos específicos para transferencias y pagos según los filtros
          if (_selectedFilteredAccounts.contains(movement.accountId)) {
            accountIdToGroup = movement.accountId;
          } else if (movement.destinationAccountId != null && _selectedFilteredAccounts.contains(movement.destinationAccountId!)) {
            accountIdToGroup = movement.destinationAccountId;
          }
        } else {
          // Para otros tipos de movimientos, usar la cuenta principal
          accountIdToGroup = movement.accountId;
        }

        if (accountIdToGroup != null) {
          totalAmountByGrouping.update(
            accountIdToGroup,
            (value) => value + movement.amount.abs(), // Usar valor absoluto para el pastel
            ifAbsent: () => movement.amount.abs(),
          );
        }
      }    } else { // Agrupar por categoría
      // Agrupar movimientos por categoría
      for (var movement in filteredMovements) {
        if (movement.categoryId.isNotEmpty) {
          totalAmountByGrouping.update(
            movement.categoryId,
            (value) => value + movement.amount.abs(), // Usar valor absoluto para el pastel
            ifAbsent: () => movement.amount.abs(),
          );
        }
      }
    }


    // Calcular el total general de los montos por agrupación (para porcentajes)
    final double totalAmountForPie = totalAmountByGrouping.values.fold(0.0, (sum, amount) => sum + amount);


    // Preparar datos para el gráfico de pastel
    final List<PieChartSectionData> pieSections = [];
    final List<Color> pieColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
      Colors.lime,
      Colors.pink,
      Colors.amber,
      Colors.grey,
    ];
    int pieColorIndex = 0;

    // Ordenar por monto descendente para la leyenda y consistencia de colores
    final sortedPieEntries = totalAmountByGrouping.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    for (var entry in sortedPieEntries) {
      final amount = entry.value;
      final percentage = (amount / totalAmountForPie) * 100;
      
      if (percentage < 1.0 && percentage > 0) {
        // Secciones muy pequeñas
        pieSections.add(
          PieChartSectionData(
            color: pieColors[pieColorIndex % pieColors.length],
            value: amount,
            title: '<1%',
            radius: 80,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else if (percentage >= 1.0) {
        // Secciones normales
        pieSections.add(
          PieChartSectionData(
            color: pieColors[pieColorIndex % pieColors.length],
            value: amount,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      
      pieColorIndex++;
    }    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        leading: Icon(
          Icons.analytics,
          color: Colors.blue,
          size: 28.0,
        ),
        title: Text('Análisis Detallado de Movimientos', style: Theme.of(context).textTheme.titleLarge),        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${filteredMovements.length} movimientos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Total: ${_formatCurrency(totalFilteredAmount, 'COP')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

            // Header con título mejorado
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Colors.grey[600],
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Configuración de Filtros',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Aplica filtros para analizar movimientos específicos por tipo, categoría y cuenta',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Filtros
            ExpansionTile(
              leading: Icon(
                Icons.filter_list,
                color: Colors.orange,
              ),
              title: Text('Filtros de Búsqueda', style: Theme.of(context).textTheme.titleMedium),              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de Movimiento
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            color: Colors.purple,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text('Tipo de Movimiento:', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Dropdown para seleccionar un solo tipo de movimiento
                      DropdownButtonFormField<String?>(
                        decoration: InputDecoration(
                          labelText: 'Seleccionar Tipo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            _getMovementTypeIcon(_selectedFilteredMovementType),
                            color: _getMovementTypeColor(_selectedFilteredMovementType),
                          ),
                        ),
                        value: _selectedFilteredMovementType,                        items: _movementTypesForFilter.map((type) {
                          return DropdownMenuItem<String?>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  _getMovementTypeIcon(type),
                                  color: _getMovementTypeColor(type),
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getMovementTypeText(type), 
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          _filterTimer?.cancel(); // Cancelar temporizador anterior
                          _filterTimer = Timer(const Duration(milliseconds: 300), () { // Esperar 300ms
                            setState(() {
                              _selectedFilteredMovementType = newValue!;
                              // Limpiar categorías seleccionadas al cambiar el tipo de movimiento
                              _selectedFilteredCategories.clear();
                              if (widget.onFilteredMovementTypeChanged != null) {
                                widget.onFilteredMovementTypeChanged!(_selectedFilteredMovementType);
                              }
                              // Reinicializar las categorías según el nuevo tipo
                              _initializeCategories();
                            });
                          });
                        },
                        isExpanded: true,                      ),
                      SizedBox(height: 16),

                      // Categorías
                      Row(
                        children: [
                          Icon(
                            Icons.label,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text('Categorías:', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Filtrar categorías por el tipo de movimiento seleccionado
                      Builder(builder: (context) {
                        final filteredCategories = widget.categories.where((category) {
                          if (_selectedFilteredMovementType == 'all') {
                            return true;
                          }
                          return category.type == _selectedFilteredMovementType;
                        }).toList();

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: filteredCategories.map((category) {
                              if (category.id == null) return SizedBox.shrink();
                              return InkWell(
                                onTap: () {
                                  _filterTimer?.cancel();
                                  _filterTimer = Timer(const Duration(milliseconds: 300), () {
                                    setState(() {
                                      if (_selectedFilteredCategories.contains(category.id!)) {
                                        _selectedFilteredCategories.remove(category.id!);
                                      } else {
                                        _selectedFilteredCategories.add(category.id!);
                                      }
                                      if (widget.onFilteredCategoriesChanged != null) {
                                        widget.onFilteredCategoriesChanged!(_selectedFilteredCategories);
                                      }
                                    });
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _selectedFilteredCategories.contains(category.id!) 
                                        ? Colors.green.shade100 
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedFilteredCategories.contains(category.id!) 
                                          ? Colors.green 
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _selectedFilteredCategories.contains(category.id!) 
                                            ? Icons.check_circle 
                                            : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: _selectedFilteredCategories.contains(category.id!) 
                                            ? Colors.green 
                                            : Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        category.name,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: _selectedFilteredCategories.contains(category.id!) 
                                              ? Colors.green.shade700 
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                      SizedBox(height: 16),

                      // Cuentas
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text('Cuentas:', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Checkboxes para Cuentas
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: widget.accounts.map((account) {
                            if (account.id == null) return SizedBox.shrink();
                            return InkWell(
                              onTap: () {
                                _filterTimer?.cancel();
                                _filterTimer = Timer(const Duration(milliseconds: 300), () {
                                  setState(() {
                                    if (_selectedFilteredAccounts.contains(account.id!)) {
                                      _selectedFilteredAccounts.remove(account.id!);
                                    } else {
                                      _selectedFilteredAccounts.add(account.id!);
                                    }
                                    if (widget.onFilteredAccountsChanged != null) {
                                      widget.onFilteredAccountsChanged!(_selectedFilteredAccounts);
                                    }
                                  });
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _selectedFilteredAccounts.contains(account.id!) 
                                      ? Colors.blue.shade100 
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedFilteredAccounts.contains(account.id!) 
                                        ? Colors.blue 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedFilteredAccounts.contains(account.id!) 
                                          ? Icons.check_circle 
                                          : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: _selectedFilteredAccounts.contains(account.id!) 
                                          ? Colors.blue 
                                          : Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      account.name,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: _selectedFilteredAccounts.contains(account.id!) 
                                            ? Colors.blue.shade700 
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),            // Espacio adicional entre secciones
            SizedBox(height: 8),// Mostrar el Total de los movimientos filtrados
            if (filteredMovements.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFilteredMovementType == 'all'
                        ? (totalFilteredAmount >= 0 ? Colors.green.shade300 : Colors.red.shade300)
                        : _getMovementTypeColor(_selectedFilteredMovementType).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: _selectedFilteredMovementType == 'all'
                          ? (totalFilteredAmount >= 0 ? Colors.green : Colors.red)
                          : _getMovementTypeColor(_selectedFilteredMovementType),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalText,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatCurrency2(totalFilteredAmount, 'COP'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _selectedFilteredMovementType == 'all'
                                ? (totalFilteredAmount >= 0 ? Colors.green : Colors.red)
                                : _getMovementTypeColor(_selectedFilteredMovementType),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedFilteredMovementType == 'all'
                            ? (totalFilteredAmount >= 0 ? Colors.green.shade100 : Colors.red.shade100)
                            : _getMovementTypeColor(_selectedFilteredMovementType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filteredMovements.length} movs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _selectedFilteredMovementType == 'all'
                              ? (totalFilteredAmount >= 0 ? Colors.green : Colors.red)
                              : _getMovementTypeColor(_selectedFilteredMovementType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),            SizedBox(height: 16),

            // Header del Gráfico de Barras
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evolución Diaria',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Muestra la distribución de movimientos por día',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Gráfico de Barras por Día
            if (totalAmountByDay.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: BarChart(
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
                              if (index >= 0 && index < visibleDates.length) {
                                final date = visibleDates[index];
                                final formattedDate = DateFormat('dd/MM').format(date);
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8.0,
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      formattedDate,
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
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                      ),
                      barGroups: barGroups,
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
              )            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sin datos para mostrar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'No hay movimientos que coincidan con los filtros',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Gráfico de Pastel Dinámico (Por Cuenta o Por Categoría)
            if (totalAmountForPie > 0) ...[
              SizedBox(height: 24),

              // Header del Gráfico de Pastel
              Row(
                children: [
                  Icon(
                    Icons.pie_chart,
                    color: Colors.purple,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Distribución de Movimientos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Agrupa movimientos por cuenta o categoría para análisis detallado',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Selector de Agrupación para el Gráfico de Pastel
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Agrupar Distribución Por',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    _selectedPieChartGrouping == 'account' 
                        ? Icons.account_balance_wallet 
                        : Icons.label,
                    color: _selectedPieChartGrouping == 'account' 
                        ? Colors.blue 
                        : Colors.green,
                  ),
                ),
                value: _selectedPieChartGrouping,                items: _pieChartGroupingOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(
                          entry.key == 'account' 
                              ? Icons.account_balance_wallet 
                              : Icons.label,
                          color: entry.key == 'account' 
                              ? Colors.blue 
                              : Colors.green,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value, 
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _filterTimer?.cancel();
                  _filterTimer = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _selectedPieChartGrouping = newValue!;
                      if (widget.onPieChartGroupingChanged != null) {
                        widget.onPieChartGroupingChanged!(_selectedPieChartGrouping);
                      }
                    });
                  });
                },
                isExpanded: true,              ),
              SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pieChartTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),

                    AspectRatio(
                      aspectRatio: 1.5,
                      child: PieChart(
                        PieChartData(
                          sections: pieSections,
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Leyenda del gráfico de pastel con header
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.legend_toggle,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Leyenda',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _selectedPieChartGrouping == 'account'
                      ? _buildPieChartAccountLegend(sortedPieEntries, widget.accounts, pieColors)
                      : _buildPieChartCategoryLegend(sortedPieEntries, widget.categories, pieColors),
                  ],
                ),
              ),            ]
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sin datos para mostrar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'No hay datos para el gráfico con la agrupación seleccionada',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
