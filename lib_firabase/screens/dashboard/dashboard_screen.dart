// lib/screens/dashboard_screen.dart
import 'package:mis_finanza/screens/dashboard/widgets/dashboard_widgets.dart';
import 'package:mis_finanza/models/models.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mis_finanza/services/firestore_service.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';
import 'package:mis_finanza/services/credit_card_notifications.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'dart:async'; 
import 'package:shared_preferences/shared_preferences.dart';





class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Variables para el filtrado por fechas (para movimientos)
  DateTime? _startDate;
  DateTime? _endDate;

  //Variable para el presupuesto seleccionado
  String? _selectedBudgetId;

  // Variables de estado para los filtros del NUEVO Gráfico Dinámico
  String? _selectedFilteredMovementType = 'all'; // Tipo de movimiento seleccionado ('all' para todos)
  Set<String> _selectedFilteredCategories = {}; // IDs de categorías seleccionadas
  Set<String> _selectedFilteredAccounts = {}; // IDs de cuentas seleccionadas

  // NUEVA VARIABLE DE ESTADO para el filtro del Histograma Mensual
  String? _selectedHistogramMovementType = 'income'; // Tipo de movimiento seleccionado para el histograma

  // NUEVA VARIABLE DE ESTADO para el filtro del Gráfico de Pastel Dinámico
  String _selectedPieChartGrouping = 'account'; // Agrupación seleccionada para el gráfico de pastel ('account' o 'category')

  // NUEVAS VARIABLES DE ESTADO para el Análisis de Tendencias
  String _selectedTrendMetric = 'income'; // Métrica seleccionada: 'income', 'expense', 'savings'
  String _selectedTrendPeriod = '3_months'; // Período seleccionado: '2_months', '3_months', '6_months', '12_months'
  String? _selectedTrendCategoryId; // Categoría seleccionada para filtrar el análisis de tendencia
  String? _selectedTrendAccountId; // Cuenta seleccionada para filtrar el análisis de tendencia

  // Variable para el temporizador de debouncing
  Timer? _filterTimer;  // Implementar wantKeepAlive
  @override
  bool get wantKeepAlive => true;

  // Estado para el calendario financiero
  bool _calendarExpanded = false;

  Map<String, bool> _dashboardWidgetsVisibility = {
    'AlertasFinancieras': true,
    'MetasAhorro': true,
    'FlujoEfectivo': true,
    'ComparacionesFinancieras': true,
    'SaludFinanciera': true,
    'TransaccionesRecientes': true,
    'GastosRecurrentes': true,
    'PlanificacionJubilacion': true,
    'AnalisisComercios': true,
    'CalendarioFinanciero': true,
    'ResumenGeneral': true,
    'ResumenCuentas': true,
    'TarjetasCredito': true,
    'MovimientosFiltrados': true,
    'Tendencias': true,
    'Ahorros': true,
    'ResumenTarjetas': true,
    'GastosPorCategoria': true,
    'IngresosPorCategoria': true,
    'Presupuestos': true,
    'HistogramaMensual': true,
    'Deudas': true,
    'EvolucionPatrimonio': true,
    'WalletInversiones': true,
    'Dividendos': true,
    'RendimientoPortafolio': true,
    'ROIInversiones': true,
  };

  List<String> _dashboardWidgetsOrder = [
    'AlertasFinancieras',
    'MetasAhorro',
    'FlujoEfectivo',
    'ComparacionesFinancieras',
    'SaludFinanciera',
    'TransaccionesRecientes',
    'GastosRecurrentes',
    'PlanificacionJubilacion',
    'AnalisisComercios',
    'CalendarioFinanciero',
    'ResumenGeneral',
    'ResumenCuentas',
    'TarjetasCredito',
    'MovimientosFiltrados',
    'Tendencias',
    'Ahorros',
    'ResumenTarjetas',
    'GastosPorCategoria',
    'IngresosPorCategoria',
    'Presupuestos',
    'HistogramaMensual',
    'Deudas',
    'EvolucionPatrimonio',
    'WalletInversiones',
    'Dividendos',
    'RendimientoPortafolio',
    'ROIInversiones',
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardWidgetsVisibility();
    _loadDashboardWidgetsOrder();
    //print('DEBUG: DashboardScreen initState llamado.'); // DEBUG    // Inicializar el rango de fechas con los últimos 30 días
    if (_endDate == null) _endDate = DateTime.now();
    if (_startDate == null) _startDate = _endDate!.subtract(Duration(days: 30));
    //print('DEBUG: Fechas iniciales: $_startDate a $_endDate'); // DEBUG

    // Inicializar los filtros
    if (_selectedFilteredMovementType == null) _selectedFilteredMovementType = 'all';
    if (_selectedHistogramMovementType == null) _selectedHistogramMovementType = 'income';
    if (_selectedPieChartGrouping == 'account') {} 
    if (_selectedTrendMetric == 'income') {} 
    if (_selectedTrendPeriod == '3_months') {} 

    
  }

  @override
  void dispose() {
    //print('DEBUG: DashboardScreen dispose llamado.'); // DEBUG
    // Limpiar el temporizador en dispose
    _filterTimer?.cancel();
    super.dispose();
  }

  // Helper para calcular el saldo neto total (considerando activos y deudas)
  double _calculateNetWorth(List<Account> accounts, List<Debt> debts) {
      double totalAssets = 0.0;
      double totalLiabilities = 0.0; // Pasivos (deudas y adeudado CC)

      for (var account in accounts) {
          if (!account.isCreditCard) {
              totalAssets += account.currentBalance; // Saldo real de cuentas no CC
          }
          // Para CC, el adeudado es un pasivo
          if (account.isCreditCard) {
              totalLiabilities += account.currentStatementBalance;
          }
      }

      // Sumar el total de deudas activas
      totalLiabilities += debts.where((debt) => debt.status == 'active').fold(0.0, (sum, debt) => sum + debt.currentAmount);


      return totalAssets - totalLiabilities;
  }


  // Filtrar movimientos por rango de fechas
  List<Movement> _filterMovementsByDate(List<Movement> movements) {
    if (_startDate == null && _endDate == null) return movements;
    return movements.where((m) {
      final date = m.dateTime;
      // Ajustar fechas para incluir todo el día
      final start = _startDate != null ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day) : null;
      final end = _endDate != null ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59) : null;

      if (start != null && date.isBefore(start)) return false;
      if (end != null && date.isAfter(end)) return false;
      return true;
    }).toList();
  }


  // Helper para calcular ingresos, gastos y ahorro en el rango seleccionado
  Map<String, double> _calculateSummary(List<Movement> movements, List<Category> categories) {
    double income = 0.0;
    double expense = 0.0;

    for (var movement in movements) {
      // Asegurarse de que la categoría no sea null antes de acceder a category.type
      final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);

      if (category != null) {
        if (category.type == 'income') {
          income += movement.amount;
        } else if (category.type == 'expense') {
          expense += movement.amount;
        }
      } else {
        // Manejar movimientos sin categoría asignada si es necesario
      }
    }

    double savings = income - expense;

    return {
      'income': income,
      'expense': expense,
      'savings': savings,
    };
  }

  // Helper para calcular gastos por categoría para el gráfico (rango seleccionado)
  Map<String, double> _calculateExpenseByCategory(List<Movement> movements, List<Category> categories) {
    final Map<String, double> expenseByCategory = {};

    final expenseMovements = movements.where((m) {
       final category = categories.firstWhereOrNull((cat) => cat.id == m.categoryId);
       return category != null && category.type == 'expense';
    }).toList();


    for (var movement in expenseMovements) {
      final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
      if (category != null) { // Doble check por si acaso
        expenseByCategory.update(category.name, (value) => value + movement.amount, ifAbsent: () => movement.amount);
      }
    }

    return expenseByCategory;
  }

  //Helper para calcular ingresos por categoría para el gráfico (rango seleccionado)
  Map<String, double> _calculateIncomeByCategory(List<Movement> movements, List<Category> categories) {
    final Map<String, double> incomeByCategory = {};

    final incomeMovements = movements.where((m) {
       final category = categories.firstWhereOrNull((cat) => cat.id == m.categoryId);
       return category != null && category.type == 'income';
    }).toList();


    for (var movement in incomeMovements) {
      final category = categories.firstWhereOrNull((cat) => cat.id == movement.categoryId);
      if (category != null) { // Doble check por si acaso
        incomeByCategory.update(category.name, (value) => value + movement.amount, ifAbsent: () => movement.amount);
      }
    }

    return incomeByCategory;
  }


  //Helper para calcular el progreso del presupuesto (del presupuesto seleccionado)
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

    // Obtener el rango de fechas del presupuesto seleccionado (asumiendo que monthYear es 'yyyy-MM')
    final budgetDate = DateFormat('yyyy-MM').parse(selectedBudget.monthYear);
    final startOfBudgetDate = DateTime(budgetDate.year, budgetDate.month, 1);
    final endOfBudgetDate = DateTime(budgetDate.year, budgetDate.month + 1, 0, 23, 59, 59); // Último día del mes

    // Filtrar movimientos de gasto relevantes para el presupuesto seleccionado
    final expenseMovementsForBudget = movements.where((m) {
       final category = categories.firstWhereOrNull((cat) => cat.id == m.categoryId);
       // Asegurarse de que el movimiento sea de gasto y dentro del rango de fechas del presupuesto
       return category != null && category.type == 'expense' &&
              m.dateTime.isAfter(startOfBudgetDate.subtract(Duration(days: 1))) && // Incluir movimientos desde el inicio del mes
              m.dateTime.isBefore(endOfBudgetDate.add(Duration(days: 1))); // Incluir movimientos hasta el final del mes
    }).toList();


    for (var movement in expenseMovementsForBudget) {
      totalSpent += movement.amount;
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
  }

  // Helper para obtener el total de deudas pendientes
  double _calculateTotalDebt(List<Debt> debts) {
    double total = 0.0;
    for (var debt in debts) {
      if (debt.status == 'active') {
        total += debt.currentAmount;
      }
    }
    return total;
  }

  // Helper para obtener las próximas cuotas de deuda (ej. las 3 más próximas)
  List<Debt> _getUpcomingDebtPayments(List<Debt> debts) {
    final activeDebtsWithDueDate = debts.where((d) =>
        d.status == 'active' &&
        d.dueDate != null &&
        d.dueDate!.isAfter(DateTime.now().subtract(Duration(days: 1))) // Considerar deudas con fecha de vencimiento en el futuro (desde ayer)
    ).toList();

    activeDebtsWithDueDate.sort((a, b) => b.dueDate!.compareTo(a.dueDate!)); // Ordenar por fecha de vencimiento descendente

    return activeDebtsWithDueDate.take(3).toList(); // Tomar las 3 primeras
  }

// Helper para calcular el total invertido por tipo de inversión
Map<String, double> _calculateTotalInvestedByType(List<Investment> investments) {
    Map<String, double> investedByType = {};

    // Sumar el totalInvested para cada tipo de inversión
    for (var investment in investments) {
        // Usar el tipo de inversión como clave (ej. 'stocks', 'funds')
        investedByType.update(
            investment.type,
            (value) => value + investment.totalInvested,
            ifAbsent: () => investment.totalInvested,
        );
    }
    return investedByType;
}

// Widget para el selector de rango de fechas
  Widget _buildDateRangeSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0), // Eliminar padding horizontal del Card
      child: Card( // Envolver en Card para aplicar el estilo del tema
         elevation: 4.0,
         color: Theme.of(context).cardColor, // Usar color del tema para el Card
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Row(
             children: [
               Expanded(
                 child: InkWell(
                   onTap: () => _selectDateRange(context),
                   child: InputDecorator(
                     decoration: InputDecoration(
                       labelText: 'Rango de Fechas',
                       border: OutlineInputBorder(),
                       // Los colores de la decoración se adaptan al tema
                     ),
                     child: Text(
                       _startDate == null || _endDate == null
                           ? 'Seleccionar rango'
                           : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                       style: Theme.of(context).textTheme.bodyMedium, // Usar estilo de texto del tema
                     ),
                   ),
                 ),
               ),
               if (_startDate != null || _endDate != null) // Mostrar botón de limpiar solo si hay fechas seleccionadas
                 IconButton(
                   icon: Icon(Icons.clear),
                   onPressed: _clearDateRange,
                   // El color del icono se adapta al tema por defecto con IconButton
                 ),
             ],
           ),
         ),
      ),
    );
  }

  // Función para seleccionar rango de fechas
   Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(Duration(days: 30)), // 30 días atrás por defecto
      end: _endDate ?? DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // Fecha mínima
      lastDate: DateTime(2101), // Fecha máxima
      initialDateRange: initialDateRange,
      // Los colores del DateRangePicker se adaptan al tema
    );

    if (picked != null && picked != DateTimeRange(start: _startDate ?? DateTime.now(), end: _endDate ?? DateTime.now())) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
         //print('DEBUG: Rango de fechas seleccionado: ${_startDate} a ${_endDate}'); // DEBUG
      });
    }
  }
  // Función para limpiar rango de fechas
  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
       //print('DEBUG: Rango de fechas limpiado.'); // DEBUG
    });
  }  

  // Aquí comienza la implementación del método build  @override
  @override
  Widget build(BuildContext context) {
    super.build(context); // Llamada obligatoria por @mustCallSuper
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Text('Por favor, inicia sesión para ver tu dashboard.', style: Theme.of(context).textTheme.bodyMedium), // Usar estilo de texto del tema
        ),
      );
    }

    // Encadenar StreamBuilders para obtener todos los datos necesarios
    return StreamBuilder<List<Account>>(
      stream: _firestoreService.getAccounts(),
      builder: (context, accountsSnapshot) {
        if (accountsSnapshot.hasError) {
          return Center(child: Text('Error al cargar cuentas: ${accountsSnapshot.error}', style: Theme.of(context).textTheme.bodyMedium)); // Usar estilo de texto del tema
        }
        final accounts = accountsSnapshot.data ?? [];
        //print('DEBUG: Cuentas cargadas: ${accounts.length}'); // DEBUG


        return StreamBuilder<List<Movement>>(
          stream: _firestoreService.getMovements(),
          builder: (context, movementsSnapshot) {
            if (movementsSnapshot.hasError) {
              return Center(child: Text('Error al cargar movimientos: {movementsSnapshot.error}', style: Theme.of(context).textTheme.bodyMedium)); // Usar estilo de texto del tema
            }
            final movements = movementsSnapshot.data ?? [];
            //print('DEBUG: Movimientos cargados: {movements.length}'); // DEBUG

            // NOTIFICACIONES DE TARJETAS DE CRÉDITO
            checkCreditCardNotifications(accounts);


            return StreamBuilder<List<Budget>>(
              stream: _firestoreService.getBudgets(),
              builder: (context, budgetsSnapshot) {
                if (budgetsSnapshot.hasError) {
                  return Center(child: Text('Error al cargar presupuestos: ${budgetsSnapshot.error}', style: Theme.of(context).textTheme.bodyMedium)); // Usar estilo de texto del tema
                }
                final budgets = budgetsSnapshot.data ?? [];
                 //print('DEBUG: Presupuestos cargados: ${budgets.length}'); // DEBUG


                //Inicializar _selectedBudgetId si es la primera vez que cargan los presupuestos
                if (_selectedBudgetId == null && budgets.isNotEmpty) {
                   // Intentar seleccionar el presupuesto del mes actual por defecto
                   final now = DateTime.now();
                   final currentMonthYear = DateFormat('yyyy-MM').format(now);
                   final currentMonthBudget = budgets.firstWhereOrNull((b) => b.monthYear == currentMonthYear);

                   if (currentMonthBudget != null) {
                       _selectedBudgetId = currentMonthBudget.id;
                       //print('DEBUG: Presupuesto del mes actual seleccionado por defecto: ${_selectedBudgetId}'); // DEBUG
                   } else {
                       // Si no hay presupuesto para el mes actual, seleccionar el primero de la lista si hay alguno
                       _selectedBudgetId = budgets.first.id;
                        //print('DEBUG: Primer presupuesto de la lista seleccionado por defecto: ${_selectedBudgetId}'); // DEBUG
                   }
                }

                //Obtener el presupuesto seleccionado
                final selectedBudget = budgets.firstWhereOrNull((b) => b.id == _selectedBudgetId);


                return StreamBuilder<List<Debt>>(
                  stream: DebtService.getDebts(),
                  builder: (context, debtsSnapshot) {
                    if (debtsSnapshot.hasError) {
                      return Center(child: Text('Error al cargar deudas: ${debtsSnapshot.error}', style: Theme.of(context).textTheme.bodyMedium)); // Usar estilo de texto del tema
                    }
                    final debts = debtsSnapshot.data ?? [];
                    //print('DEBUG: Deudas cargadas: ${debts.length}'); // DEBUG


                    return StreamBuilder<List<Category>>(
                      stream: CategoryService.getCategories(),
                      builder: (context, categoriesSnapshot) {
                        if (categoriesSnapshot.hasError) {
                          return Center(child: Text('Error al cargar categorías: ${categoriesSnapshot.error}', style: Theme.of(context).textTheme.bodyMedium)); // Usar estilo de texto del tema
                        }
                        final categories = categoriesSnapshot.data ?? [];
                        //print('DEBUG: Categorías cargadas: ${categories.length}'); // DEBUG


                        //StreamBuilder para Inversiones
                        return StreamBuilder<List<Investment>>(
                          stream: _firestoreService.getInvestments(), // Obtener stream de inversiones
                          builder: (context, investmentsSnapshot) {
                             if (investmentsSnapshot.hasError) {
                                return Center(child: Text('Error al cargar inversiones: ${investmentsSnapshot.error}', style: Theme.of(context).textTheme.bodyMedium)); // Usar estilo de texto del tema
                             }
                             final investments = investmentsSnapshot.data ?? []; // Lista de inversiones
                             //print('DEBUG: Inversiones cargadas: ${investments.length}'); // DEBUG


                            // Esperar a que todos los streams tengan datos activos
                            if (accountsSnapshot.connectionState == ConnectionState.active &&
                                movementsSnapshot.connectionState == ConnectionState.active &&
                                budgetsSnapshot.connectionState == ConnectionState.active &&
                                debtsSnapshot.connectionState == ConnectionState.active &&
                                categoriesSnapshot.connectionState == ConnectionState.active &&
                                investmentsSnapshot.connectionState == ConnectionState.active) {

                                //print('DEBUG: Todos los streams activos. Construyendo Dashboard.'); // DEBUG

                              // Calcular datos para el Dashboard
                              final filteredMovementsByDate = _filterMovementsByDate(movements); // Movimientos filtrados por fecha
                               //print('DEBUG: Movimientos filtrados por fecha (${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}): ${filteredMovementsByDate.length}'); // DEBUG


                              // CALCULAR LA CANTIDAD DE DINERO EN TRANSFERENCIAS Y PAGOS
                              final double totalTransferAmount = filteredMovementsByDate
                                  .where((m) => m.type == 'transfer')
                                  .fold(0.0, (sum, m) => sum + m.amount);
                               //print('DEBUG: Total Transferido (rango fecha): $totalTransferAmount'); // DEBUG


                              // Filtrar por tipo 'payment' para pagos a tarjetas de crédito
                              final double totalPaymentAmount = filteredMovementsByDate
                                  .where((m) => m.type == 'payment') // Filtrar por pagos
                                  .fold(0.0, (sum, m) => sum + m.amount); // Sumar los montos de pagos
                               //print('DEBUG: Total Pagado TC (rango fecha): $totalPaymentAmount'); // DEBUG

                              final netWorth = _calculateNetWorth(accounts, debts); // Calcular patrimonio neto
                               //print('DEBUG: Patrimonio Neto: $netWorth'); // DEBUG

                              final summary = _calculateSummary(filteredMovementsByDate, categories);
                               //print('DEBUG: Resumen (rango fecha) - Ingresos: ${summary['income']}, Gastos: ${summary['expense']}, Ahorro: ${summary['savings']}'); // DEBUG


                              // Pasar el presupuesto seleccionado a _calculateBudgetProgress
                              final budgetProgress = _calculateBudgetProgress(selectedBudget, movements, categories); // Presupuesto usa movimientos sin filtrar por rango de dashboard
                               //print('DEBUG: Progreso Presupuesto (ID: ${_selectedBudgetId}) - Presupuestado: ${budgetProgress['totalBudgeted']}, Gastado: ${budgetProgress['totalSpent']}, %: ${budgetProgress['progressPercentage']}'); // DEBUG
                              final totalDebt = _calculateTotalDebt(debts);
                               //print('DEBUG: Total Deuda Pendiente: $totalDebt'); // DEBUG

                              final upcomingDebts = _getUpcomingDebtPayments(debts);
                               //print('DEBUG: Próximas cuotas de deuda: ${upcomingDebts.length}'); // DEBUG

                              final expenseByCategory = _calculateExpenseByCategory(filteredMovementsByDate, categories);
                               //print('DEBUG: Gastos por Categoría (rango fecha): ${expenseByCategory.length} categorías.'); // DEBUG

                              final incomeByCategory = _calculateIncomeByCategory(filteredMovementsByDate, categories); // Calcular ingresos por categoría
                               //print('DEBUG: Ingresos por Categoría (rango fecha): ${incomeByCategory.length} categorías.'); // DEBUG


                              final totalExpense = summary['expense'] ?? 0.0;
                              final totalIncome = summary['income'] ?? 0.0; // Obtener total de ingresos

                              // CÁLCULO DE LA CANTIDAD AHORRABLE
                              final savableAmount = totalIncome - totalExpense;
                               //print('DEBUG: Cantidad Ahorrable (rango fecha): $savableAmount'); // DEBUG                              // Calcular datos para el gráfico de Inversiones (ahora también se manejan en el widget modular)
                              // Estas variables se mantienen por compatibilidad con otras partes del código
                              final investedByType = _calculateTotalInvestedByType(investments); // Calcular total invertido por tipo
                              final totalInvestedSum = investedByType.values.fold(0.0, (sum, amount) => sum + amount); // Suma total invertida
                               //print('DEBUG: Total Invertido: $totalInvestedSum'); // DEBUG

                              final String displayCurrencyForInvestmentTotal = 'COP'; // Moneda para mostrar el total (ajustar si es necesario)


                              // Construir la UI del Dashboard
                              return Scaffold(
                                appBar: AppBar(
                                  title: const Text('Dashboard Financiero'),
                                ),
                                body: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      // FILTRO DE FECHAS (Aplica a movimientos)
                                      _buildDateRangeSelector(context),
                                      SizedBox(height: 24),
                                      ..._dashboardWidgetsOrder.expand((key) {
                                        if (!(_dashboardWidgetsVisibility[key] ?? true)) return [];                                        switch (key) {                                          case 'AlertasFinancieras':
                                            return [DashboardAlertsWidget(
                                              accounts: accounts,
                                              movements: movements,
                                              budgets: budgets,
                                              debts: debts,
                                              categories: categories,
                                            ), SizedBox(height: 24)];                                          case 'MetasAhorro':
                                            return [DashboardSavingsGoalsWidget(
                                              accounts: accounts,
                                              movements: movements,
                                            ), SizedBox(height: 24)];                                          case 'FlujoEfectivo':
                                            return [DashboardCashFlowWidget(
                                              accounts: accounts,
                                              movements: movements,
                                              categories: categories,
                                            ), SizedBox(height: 24)];                                          case 'ComparacionesFinancieras':
                                            return [DashboardComparisonsWidget(
                                              accounts: accounts,
                                              movements: movements,
                                              categories: categories,
                                            ), SizedBox(height: 24)];                                          case 'SaludFinanciera':
                                            return [DashboardFinancialHealthWidget(
                                              accounts: accounts,
                                              movements: movements,
                                              budgets: budgets,
                                              debts: debts,
                                              categories: categories,
                                            ), SizedBox(height: 24)];                                          case 'TransaccionesRecientes':
                                            return [DashboardRecentTransactionsWidget(
                                              accounts: accounts,
                                              movements: movements,
                                              categories: categories,
                                            ), SizedBox(height: 24)];                                          case 'GastosRecurrentes':
                                            return [DashboardRecurringExpensesWidget(
                                              accounts: accounts,
                                              movements: movements,
                                              categories: categories,
                                            ), SizedBox(height: 24)];
                                          case 'PlanificacionJubilacion':
                                            return [DashboardRetirementPlanningWidget(
                                              accounts: accounts,
                                              movements: movements,
                                            ), SizedBox(height: 24)];
                                          case 'AnalisisComercios':
                                            return [DashboardMerchantAnalysisWidget(
                                              accounts: accounts,
                                              movements: movements,
                                              categories: categories,
                                            ), SizedBox(height: 24)];                                          case 'CalendarioFinanciero':
                                            return [DashboardFinancialCalendarWidget(
                                              isExpanded: _calendarExpanded,
                                              onToggleExpansion: () {
                                                setState(() {
                                                  _calendarExpanded = !_calendarExpanded;
                                                });
                                              },
                                            ), SizedBox(height: 24)];
                                          case 'ResumenGeneral':
                                            return [DashboardUnifiedSummary(
                                              totalIncome: totalIncome,
                                              totalExpense: totalExpense,
                                              savableAmount: savableAmount,
                                              totalTransferAmount: totalTransferAmount,
                                              totalPaymentAmount: totalPaymentAmount,
                                              accounts: accounts,
                                              displayCurrency: 'COP',
                                            ), SizedBox(height: 24)];
                                          case 'ResumenCuentas':
                                            return [AccountSummaryWidget(), SizedBox(height: 24)];
                                            case 'TarjetasCredito':
                                            return [DashboardCreditCardUnified(
                                              accounts: accounts,
                                              displayCurrency: 'COP',
                                            ), SizedBox(height: 24)];
                                          case 'MovimientosFiltrados':
                                            return [DashboardFilteredMovementsChart(
                                              movements: filteredMovementsByDate,
                                              accounts: accounts,
                                              categories: categories,
                                              initialFilteredMovementType: _selectedFilteredMovementType,
                                              initialFilteredCategories: _selectedFilteredCategories,
                                              initialFilteredAccounts: _selectedFilteredAccounts,
                                              initialPieChartGrouping: _selectedPieChartGrouping,
                                              onFilteredMovementTypeChanged: (type) {
                                                setState(() {
                                                  _selectedFilteredMovementType = type;
                                                });
                                              },
                                              onFilteredCategoriesChanged: (categories) {
                                                setState(() {
                                                  _selectedFilteredCategories = categories;
                                                });
                                              },
                                              onFilteredAccountsChanged: (accounts) {
                                                setState(() {
                                                  _selectedFilteredAccounts = accounts;
                                                });
                                              },
                                              onPieChartGroupingChanged: (grouping) {
                                                setState(() {
                                                  _selectedPieChartGrouping = grouping;
                                                });
                                              },
                                            ), SizedBox(height: 24)];
                                          case 'Tendencias':
                                            return [DashboardTrendAnalysisChart(
                                              movements: movements,
                                              categories: categories,
                                              accounts: accounts,
                                              initialTrendMetric: _selectedTrendMetric,
                                              initialTrendPeriod: _selectedTrendPeriod,
                                              initialTrendCategoryId: _selectedTrendCategoryId,
                                              initialTrendAccountId: _selectedTrendAccountId,
                                              onTrendMetricChanged: (metric) {
                                                setState(() {
                                                  _selectedTrendMetric = metric;
                                                });
                                              },
                                              onTrendPeriodChanged: (period) {
                                                setState(() {
                                                  _selectedTrendPeriod = period;
                                                });
                                              },
                                              onTrendCategoryChanged: (categoryId) {
                                                setState(() {
                                                  _selectedTrendCategoryId = categoryId;
                                                });
                                              },
                                              onTrendAccountChanged: (accountId) {
                                                setState(() {
                                                  _selectedTrendAccountId = accountId;
                                                });
                                              },
                                            ), SizedBox(height: 24)];
                                          case 'Ahorros':
                                            return [DashboardSavingsAccountChart(
                                              accounts: accounts,
                                            ), SizedBox(height: 24)];
                                          case 'GastosPorCategoria':
                                            return [DashboardExpenseByCategoryChart(
                                              movements: filteredMovementsByDate,
                                              categories: categories,
                                            ), SizedBox(height: 24)];
                                          case 'IngresosPorCategoria':
                                            return [DashboardIncomeByCategoryChart(
                                              movements: filteredMovementsByDate,
                                              categories: categories,
                                            ), SizedBox(height: 24)];
                                          case 'Presupuestos':
                                            return [
                                              DashboardBudgetUnifiedOverview(
                                                budgets: budgets,
                                                movements: movements,
                                                categories: categories,
                                                initialBudgetId: _selectedBudgetId,
                                                onBudgetSelected: (budgetId) {
                                                  setState(() {
                                                    _selectedBudgetId = budgetId;
                                                  });
                                                },
                                              ),
                                              SizedBox(height: 24),
                                            ];
                                          case 'HistogramaMensual':
                                            return [DashboardMonthlyHistogram(
                                              movements: movements,
                                              initialMovementType: _selectedHistogramMovementType,
                                              onMovementTypeSelected: (movementType) {
                                                setState(() {
                                                  _selectedHistogramMovementType = movementType;
                                                });
                                              },
                                            ), SizedBox(height: 24)];                                          case 'Deudas':
                                            return [
                                              
                                              DashboardDebtOverview(
                                                debts: debts,
                                                displayCurrency: 'COP',
                                              ),
                                              SizedBox(height: 24)
                                            ];
                                          case 'EvolucionPatrimonio':
                                            return [
                                              DashboardNetWorthEvolutionChart(
                                                accounts: accounts,
                                                debts: debts,
                                                investments: investments,
                                                movements: movements,
                                                displayCurrency: 'COP',
                                              ),
                                              SizedBox(height: 24)
                                            ];                                          case 'Inversiones':
                                              case 'WalletInversiones':
                                            return [
                                              DashboardWalletInvestment(
                                                investments: investments,
                                                displayCurrency: displayCurrencyForInvestmentTotal,
                                              ),
                                              SizedBox(height: 24)
                                            ];                                          case 'Dividendos':
                                            return [
                                              DashboardDividendsChart(),
                                              SizedBox(height: 24)
                                            ];                                          case 'RendimientoPortafolio':
                                            return [
                                              DashboardPortfolioPerformanceChart(),
                                              SizedBox(height: 24)
                                            ];
                                          case 'ROIInversiones':
                                            return [
                                              DashboardROIInvestmentsChart(),
                                              SizedBox(height: 24)
                                            ];
                                          default:
                                            return [];
                                        }
                                      }),
                                    ],
                                  ),
                                ),                              );
                            } else {
                              // Mostrar indicador de carga si algún stream aún no tiene datos activos
                              return Scaffold(
                                appBar: AppBar(title: const Text('Dashboard Financiero')),
                                body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)), // Usar color primario del tema
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }  // El método _buildBudgetCategoryRow ha sido eliminado ya que ahora se usa en el componente modular DashboardBudgetOverview

  Future<void> _loadDashboardWidgetsVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dashboardWidgetsVisibility.forEach((key, value) {
        _dashboardWidgetsVisibility[key] = prefs.getBool('dashboard_widget_' + key) ?? true;
      });
    });
  }  Future<void> _loadDashboardWidgetsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('dashboard_widgets_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      // Filtrar el orden guardado para incluir solo widgets que existen en el código actual
      List<String> validSavedWidgets = savedOrder.where((widget) => 
        _dashboardWidgetsOrder.contains(widget)).toList();
      
      // Agregar widgets que están en el código actual pero no en el orden guardado
      List<String> missingWidgets = [];
      for (var widgetKey in _dashboardWidgetsOrder) {
        if (!validSavedWidgets.contains(widgetKey)) {
          missingWidgets.add(widgetKey);
        }
      }
      
      setState(() {
        if (missingWidgets.isEmpty) {
          _dashboardWidgetsOrder = validSavedWidgets;
        } else {
          // Crear una nueva lista que incluya los widgets válidos guardados más los faltantes
          _dashboardWidgetsOrder = [...validSavedWidgets, ...missingWidgets];
        }
      });
    }
  }

  Future<void> _saveDashboardWidgetsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dashboard_widgets_order', _dashboardWidgetsOrder);
  }
}
