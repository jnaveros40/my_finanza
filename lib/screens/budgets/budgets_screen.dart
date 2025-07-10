// lib/screens/budgets/budgets_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/budget.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';
import 'package:mis_finanza/screens/budgets/add_edit_budget_screen.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

// Import helper mixins
import 'budget_ui_helpers.dart';
import 'budget_calculation_helpers.dart';
import 'budget_chart_helpers.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  _BudgetsScreenState createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> 
    with BudgetUIHelpers, BudgetCalculationHelpers, BudgetChartHelpers {
  
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // State variables
  List<Category> _allCategories = [];
  bool _isLoadingCategories = true;

  final Map<String, String> _budgetCategoryNames = {
    'needs': 'Necesidades',
    'wants': 'Deseos',
    'savings': 'Ahorros',
    'all': 'Todas',
  };

  final TextEditingController _monthYearController = TextEditingController();
  DateTime _selectedMonthYear = DateTime.now();
  Map<String, String> _budgetsByMonthYear = {};
  String? _selectedBudgetId;
  String _selectedBudgetCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _monthYearController.dispose();
    super.dispose();
  }

  // Load all categories from Firestore
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      CategoryService.getCategories().listen((categories) {
        setState(() {
          _allCategories = categories;
          _isLoadingCategories = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: \\${e.toString()}')),
        );
      }
    }
  }

  // Confirm and delete budget
  Future<bool> _confirmAndDeleteBudget(BuildContext context, Budget budget) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el presupuesto para "${budget.monthYear}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Eliminar', 
                style: TextStyle(color: Theme.of(context).colorScheme.error)
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        if (budget.id != null) {
          await BudgetService.deleteBudget(budget.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Presupuesto para "${budget.monthYear}" eliminado.')),
            );
          }
          if (_selectedBudgetId == budget.id) {
            setState(() {
              _selectedBudgetId = null;
            });
          }
          return true;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar presupuesto: \\${e.toString()}')),
          );
        }
      }
    }
    return false;
  }

  // Month/Year selector
  Future<void> _selectMonthYear(BuildContext context, List<Budget> budgets) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonthYear,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null && picked != _selectedMonthYear) {
      setState(() {
        _selectedMonthYear = picked;
        final newMonthYearString = DateFormat('yyyy-MM').format(_selectedMonthYear);
        _monthYearController.text = newMonthYearString;

        final selectedBudgetForMonth = budgets.firstWhereOrNull(
            (b) => b.monthYear == newMonthYearString);

        _selectedBudgetId = selectedBudgetForMonth?.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return buildUnauthenticatedState(context);
    }

    if (_isLoadingCategories) {
      return buildLoadingState(context);
    }

    const String displayCurrency = 'COP';

    return Scaffold(
      appBar: buildModernAppBar(context),
      body: StreamBuilder<List<Budget>>(
        stream: BudgetService.getBudgets(),
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState == ConnectionState.waiting) {
            return buildLoadingState(context);
          }
          if (budgetSnapshot.hasError) {
            return buildErrorState(context, 'Error al cargar presupuestos: ${budgetSnapshot.error}');
          }          if (!budgetSnapshot.hasData || budgetSnapshot.data!.isEmpty) {
            _budgetsByMonthYear = {};
            _selectedBudgetId = null;
            _selectedMonthYear = DateTime.now();
            _monthYearController.text = DateFormat('yyyy-MM').format(_selectedMonthYear);
            return buildEmptyState(context, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditBudgetScreen(),
                ),
              );
            });
          }

          final budgets = budgetSnapshot.data!;

          // Update budget map
          _budgetsByMonthYear = {
            for (var budget in budgets) budget.monthYear: budget.id!
          };

          // Initialize selected budget if needed
          if (_selectedBudgetId == null) {
            final nowMonthYear = DateFormat('yyyy-MM').format(DateTime.now());

            if (_budgetsByMonthYear.containsKey(nowMonthYear)) {
              _selectedBudgetId = _budgetsByMonthYear[nowMonthYear];
              _selectedMonthYear = DateFormat('yyyy-MM').parse(nowMonthYear);
              _monthYearController.text = nowMonthYear;
            } else if (budgets.isNotEmpty) {
              budgets.sort((a, b) => a.monthYear.compareTo(b.monthYear));
              final firstBudget = budgets.first;
              _selectedBudgetId = firstBudget.id;
              _selectedMonthYear = DateFormat('yyyy-MM').parse(firstBudget.monthYear);
              _monthYearController.text = firstBudget.monthYear;
            } else {
              _selectedBudgetId = null;
              _selectedMonthYear = DateTime.now();
              _monthYearController.text = DateFormat('yyyy-MM').format(_selectedMonthYear);
            }
          } else {
            final currentSelectedBudget = budgets.firstWhereOrNull((b) => b.id == _selectedBudgetId);
            if (currentSelectedBudget != null) {
              _selectedMonthYear = DateFormat('yyyy-MM').parse(currentSelectedBudget.monthYear);
              _monthYearController.text = currentSelectedBudget.monthYear;
            } else {
              _selectedBudgetId = null;
              _selectedMonthYear = DateTime.now();
              _monthYearController.text = DateFormat('yyyy-MM').format(_selectedMonthYear);
            }
          }

          final selectedBudget = budgets.firstWhereOrNull((b) => b.id == _selectedBudgetId);

          return StreamBuilder<List<Movement>>(
            stream: MovementService.getMovements(),
            builder: (context, movementSnapshot) {
              if (movementSnapshot.connectionState == ConnectionState.waiting) {
                return buildLoadingState(context);
              }
              if (movementSnapshot.hasError) {
                return buildErrorState(context, 'Error al cargar movimientos: ${movementSnapshot.error}');
              }

              final movements = movementSnapshot.data ?? [];

              // Calculate budget amounts if a budget is selected
              Map<String, double>? budgetAmounts;
              if (selectedBudget != null) {
                budgetAmounts = calculateBudgetAmounts(selectedBudget);
              }

              // Calculate remaining amounts
              Map<String, double> remainingAmounts = {};
              if (selectedBudget != null && budgetAmounts != null) {
                remainingAmounts = calculateRemainingAmounts(
                  selectedBudget, 
                  movements, 
                  _allCategories, 
                  budgetAmounts
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month/Year selector
                  buildMonthYearSelector(
                    context,
                    _monthYearController,
                    () => _selectMonthYear(context, budgets),
                  ),

                  // Budget details or message
                  Expanded(
                    child: selectedBudget != null
                        ? _buildBudgetDetails(
                            context,
                            selectedBudget,
                            movements,
                            displayCurrency,
                            budgetAmounts ?? {},
                            remainingAmounts,
                          )
                        : _buildNoBudgetMessage(context),
                  ),
                ],
              );
            },
          );
        },
      ),
      /*floatingActionButton: buildFloatingActionButton(
        context,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEditBudgetScreen()),
        ),
      ),*/
    );
  }
  Widget _buildBudgetDetails(
    BuildContext context,
    Budget budget,
    List<Movement> movements,
    String displayCurrency,
    Map<String, double> budgetAmounts,
    Map<String, double> remainingAmounts,
  ) {
    final totalSpent = movements
        .where((movement) {
          final movementMonthYear = DateFormat('yyyy-MM').format(movement.dateTime);
          return movement.type == 'expense' && movementMonthYear == budget.monthYear;
        })
        .fold(0.0, (sum, movement) => sum + movement.amount);

    final totalRemaining = budget.totalBudgeted - totalSpent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final horizontalPadding = isMobile ? 16.0 : 24.0;
        final verticalSpacing = isMobile ? 20.0 : 24.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: isMobile ? 8.0 : 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              buildSummaryCards(
                context,
                budget.totalBudgeted,
                totalSpent,
                totalRemaining,
              ),

              SizedBox(height: verticalSpacing),

              // Budget breakdown
              _buildBudgetBreakdown(
                context,
                budget,
                movements,
                displayCurrency,
                budgetAmounts,
                remainingAmounts,
                isMobile,
              ),

              SizedBox(height: verticalSpacing),

              // Charts section
              _buildChartsSection(
                context,
                budget,
                movements,
                displayCurrency,
                budgetAmounts,
                remainingAmounts,
                isMobile,
              ),
            ],
          ),
        );
      },
    );
  }  Widget _buildBudgetBreakdown(
    BuildContext context,
    Budget budget,
    List<Movement> movements,
    String displayCurrency,
    Map<String, double> budgetAmounts,
    Map<String, double> remainingAmounts,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 16.0, 
        vertical: isMobile ? 6.0 : 8.0,
      ),
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: getBudgetTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      getBudgetTypeIcon(),
                      color: getBudgetTypeColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Presupuesto ${budget.monthYear}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                      tooltip: 'Editar Presupuesto',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditBudgetScreen(budget: budget),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      tooltip: 'Eliminar Presupuesto',
                      onPressed: () {
                        _confirmAndDeleteBudget(context, budget);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Budget category breakdown
          Text(
            'Resumen Presupuesto (50/30/20):',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),          const SizedBox(height: 12),

          // Debug //prints para verificar los cálculos
          Builder(
            builder: (context) {
              final needsSpent = calculateTotalSpentForBudgetCategory(budget, movements, 'needs', _allCategories);
              final wantsSpent = calculateTotalSpentForBudgetCategory(budget, movements, 'wants', _allCategories);
              final savingsSpent = calculateTotalSpentForBudgetCategory(budget, movements, 'savings', _allCategories);
              
              //print('\n=== DEBUG: Budget Screen Calculations ===');
              //print('Budget: ${budget.monthYear}');
              //print('Budget Amounts:');
              //print('  - Needs Budget: ${budgetAmounts['needs']} (${budget.needsPercentage}%)');
              //print('  - Wants Budget: ${budgetAmounts['wants']} (${budget.wantsPercentage}%)');
              //print('  - Savings Budget: ${budgetAmounts['savings']} (${budget.savingsPercentage}%)');
              //print('Spent Amounts:');
              //print('  - Needs Spent: $needsSpent');
              //print('  - Wants Spent: $wantsSpent');
              //print('  - Savings Spent: $savingsSpent');
              
              // Call debug method from helpers
              calculateExpenseByBudgetTypeDebug(budget, movements, _allCategories);
              
              //print('=== END Budget Screen Debug ===\n');
              
              return SizedBox.shrink();
            },
          ),

          _buildBudgetCategoryRow(
            context,
            'Necesidades',
            budget.needsPercentage,
            budgetAmounts['needs'] ?? 0.0,
            calculateTotalSpentForBudgetCategory(budget, movements, 'needs', _allCategories),
            displayCurrency,
          ),
          _buildBudgetCategoryRow(
            context,
            'Deseos',
            budget.wantsPercentage,
            budgetAmounts['wants'] ?? 0.0,
            calculateTotalSpentForBudgetCategory(budget, movements, 'wants', _allCategories),
            displayCurrency,
          ),
          _buildBudgetCategoryRow(
            context,
            'Ahorros',
            budget.savingsPercentage,
            budgetAmounts['savings'] ?? 0.0,
            calculateTotalSpentForBudgetCategory(budget, movements, 'savings', _allCategories),
            displayCurrency,
          ),
        ],
      ),
    );
  }
  Widget _buildBudgetCategoryRow(
    BuildContext context,
    String categoryName,
    double percentage,
    double budgetedAmount,
    double actualSpent,
    String displayCurrency,
  ) {
    final remainingAmount = budgetedAmount - actualSpent;
    
    Color remainingColor = Colors.grey;
    IconData statusIcon = Icons.remove;
    if (remainingAmount < 0) {
      remainingColor = Colors.red.shade400;
      statusIcon = Icons.trending_up;
    } else if (remainingAmount > 0) {
      remainingColor = Colors.green.shade400;
      statusIcon = Icons.trending_down;
    }

    // Determinar el color del ícono de categoría
    Color categoryColor = getBudgetCategoryColor(categoryName.toLowerCase());
    IconData categoryIcon = getBudgetCategoryIcon(categoryName.toLowerCase());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$categoryName (${percentage.toStringAsFixed(0)}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                statusIcon,
                color: remainingColor,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastado: ${formatCurrency(actualSpent, displayCurrency)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Presupuestado: ${formatCurrency(budgetedAmount, displayCurrency)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Restante',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    formatCurrency(remainingAmount, displayCurrency),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: remainingColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }  Widget _buildChartsSection(
    BuildContext context,
    Budget budget,
    List<Movement> movements,
    String displayCurrency,
    Map<String, double> budgetAmounts,
    Map<String, double> remainingAmounts,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 16.0, 
        vertical: isMobile ? 6.0 : 8.0,
      ),
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Análisis de Gastos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),          const SizedBox(height: 20),

          // Spending chart
          buildSpendingChart(
            context,
            budgetAmounts,
            calculateSpentAmounts(budget, movements, _allCategories),
          ),

          const SizedBox(height: 24),

          // Remaining budget chart  
          buildRemainingChart(
            context,
            budgetAmounts,
            calculateSpentAmounts(budget, movements, _allCategories),
          ),

          const SizedBox(height: 24),

          // Category filter and specific categories chart
          _buildSpecificCategoriesSection(
            context,
            budget,
            movements,
          ),
        ],
      ),
    );
  }
  Widget _buildSpecificCategoriesSection(
    BuildContext context,
    Budget budget,
    List<Movement> movements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.filter_list,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Desglose de Gastos por Categoría',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Modern category filter dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: getBudgetCategoryColor(_selectedBudgetCategoryFilter).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  getBudgetCategoryIcon(_selectedBudgetCategoryFilter),
                  color: getBudgetCategoryColor(_selectedBudgetCategoryFilter),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBudgetCategoryFilter,
                    hint: Text(
                      'Filtrar por Tipo de Presupuesto',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    items: _budgetCategoryNames.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(
                              getBudgetCategoryIcon(entry.key),
                              color: getBudgetCategoryColor(entry.key),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBudgetCategoryFilter = newValue;
                        });
                      }
                    },
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),        // Specific categories chart
        buildSpecificCategoriesChart(
          context,
          budget,
          movements,
          _allCategories,
          _selectedBudgetCategoryFilter,
        ),
      ],
    );
  }

  Widget _buildNoBudgetMessage(BuildContext context) {
    return Center(
      child: _selectedBudgetId == null && 
             _budgetsByMonthYear.isNotEmpty && 
             !_budgetsByMonthYear.containsKey(_monthYearController.text)
          ? Text(
              'No hay presupuesto creado para ${_monthYearController.text}.\nSelecciona otro mes o añade un presupuesto.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            )
          : Text(
              'Selecciona un presupuesto para ver los detalles.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
    );
  }
}
