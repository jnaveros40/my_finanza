import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/movement.dart';
import '../../../models/debt.dart';
import '../../../models/budget.dart';
import '../../../services/firestore_service.dart';

class DashboardFinancialCalendarWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpansion;

  const DashboardFinancialCalendarWidget({
    Key? key,
    required this.isExpanded,
    required this.onToggleExpansion,
  }) : super(key: key);

  @override
  State<DashboardFinancialCalendarWidget> createState() => _DashboardFinancialCalendarWidgetState();
}

class _DashboardFinancialCalendarWidgetState extends State<DashboardFinancialCalendarWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Movement> _movements = [];
  List<Debt> _debts = [];
  List<Budget> _budgets = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  List<FinancialEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener los primeros valores de los streams
      final movementsStream = _firestoreService.getMovements();
      final debtsStream = _firestoreService.getDebts();
      final budgetsStream = _firestoreService.getBudgets();
      
      final movements = await movementsStream.first;
      final debts = await debtsStream.first;
      final budgets = await budgetsStream.first;
      
      setState(() {
        _movements = movements;
        _debts = debts;
        _budgets = budgets;
        _generateEvents();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _generateEvents() {
    _events.clear();
    final now = DateTime.now();
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // Eventos de transacciones programadas
    for (var movement in _movements) {
      if (movement.dateTime.isAfter(monthStart.subtract(Duration(days: 1))) &&
          movement.dateTime.isBefore(monthEnd.add(Duration(days: 1)))) {
        _events.add(FinancialEvent(
          date: movement.dateTime,
          title: movement.description,
          amount: movement.amount,
          type: movement.amount > 0 ? EventType.income : EventType.expense,
          category: movement.categoryId,
        ));
      }
    }

    // Eventos de vencimientos de deudas
    for (var debt in _debts) {
      if (debt.dueDate != null) {
        final dueDate = debt.dueDate!;
        if (dueDate.isAfter(monthStart.subtract(Duration(days: 1))) &&
            dueDate.isBefore(monthEnd.add(Duration(days: 1)))) {
          _events.add(FinancialEvent(
            date: dueDate,
            title: 'Vencimiento: ${debt.description}',
            amount: debt.currentAmount,
            type: EventType.debt,
            category: 'Deuda',
          ));
        }
      }
    }

    // Eventos de presupuestos (inicio de período)
    for (var budget in _budgets) {
      final periodStart = DateTime(now.year, now.month, 1);
      if (periodStart.month == _selectedMonth.month && 
          periodStart.year == _selectedMonth.year) {
        _events.add(FinancialEvent(
          date: periodStart,
          title: 'Presupuesto: ${budget.monthYear}',
          amount: budget.totalBudgeted,
          type: EventType.budget,
          category: 'Presupuesto',
        ));
      }
    }

    // Eventos recurrentes estimados
    _generateRecurringEvents();
    
    // Ordenar eventos por fecha
    _events.sort((a, b) => a.date.compareTo(b.date));
  }

  void _generateRecurringEvents() {
    // Detectar patrones de gastos recurrentes
    final recurringPatterns = <String, List<Movement>>{};
    
    for (var movement in _movements) {
      final key = '${movement.description}_${movement.amount.abs()}';
      recurringPatterns[key] ??= [];
      recurringPatterns[key]!.add(movement);
    }

    // Predecir próximos eventos recurrentes
    for (var pattern in recurringPatterns.entries) {
      if (pattern.value.length >= 2) {
        final movements = pattern.value..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final intervals = <int>[];
        
        for (int i = 1; i < movements.length; i++) {
          intervals.add(movements[i].dateTime.difference(movements[i-1].dateTime).inDays);
        }
        
        if (intervals.isNotEmpty) {
          final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
          final lastMovement = movements.last;
          final nextDate = lastMovement.dateTime.add(Duration(days: avgInterval.round()));
          
          if (nextDate.month == _selectedMonth.month && 
              nextDate.year == _selectedMonth.year &&
              nextDate.isAfter(DateTime.now())) {
            _events.add(FinancialEvent(
              date: nextDate,
              title: '${lastMovement.description} (Estimado)',
              amount: lastMovement.amount,
              type: lastMovement.amount > 0 ? EventType.recurringIncome : EventType.recurringExpense,
              category: lastMovement.categoryId,
            ));
          }
        }
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue.shade800, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendario Financiero',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Eventos y recordatorios financieros',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onToggleExpansion,
            icon: Icon(
              widget.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                _generateEvents();
              });
            },
            icon: Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy', 'es').format(_selectedMonth),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                _generateEvents();
              });
            },
            icon: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
  Widget _buildCalendarView() {
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    // Ajustar para que lunes = 0, domingo = 6 (formato L M X J V S D)
    final firstDayWeekday = (monthStart.weekday - 1) % 7;
    final daysInMonth = monthEnd.day;
    
    return Column(
      children: [
        // Días de la semana
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),        // Días del mes - Altura aumentada para mostrar todas las fechas
        Container(
          height: 250, // Altura aumentada para 6 filas completas
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0, // Aspecto cuadrado para mejor visualización
              mainAxisSpacing: 3,
              crossAxisSpacing: 2,
            ),itemCount: 42, // 6 semanas x 7 días
            itemBuilder: (context, index) {
              final dayIndex = index - firstDayWeekday + 1;
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return Container(); // Días vacíos
              }
              
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayIndex);
              final dayEvents = _events.where((e) => 
                e.date.year == date.year && 
                e.date.month == date.month && 
                e.date.day == date.day
              ).toList();
              
              final isToday = DateTime.now().year == date.year && 
                             DateTime.now().month == date.month && 
                             DateTime.now().day == date.day;
            
            return GestureDetector(
              onTap: dayEvents.isNotEmpty ? () => _showDayEvents(date, dayEvents) : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.shade100 : null,
                  border: dayEvents.isNotEmpty ? Border.all(color: Colors.blue, width: 2) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayIndex.toString(),
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.blue : Colors.black,
                      ),
                    ),
                    if (dayEvents.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getEventColor(dayEvents.first.type),
                          shape: BoxShape.circle,
                        ),
                      ),                  ],
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }
  Widget _buildEventsList() {
    if (_events.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 32, color: Colors.grey.shade400),
              SizedBox(height: 8),
              Text(
                'No hay eventos este mes',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200, // Altura fija para hacer scroll
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.event_rounded, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Eventos del mes (${_events.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return _buildCompactEventCard(event);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEventCard(FinancialEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getEventColor(event.type).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),        border: Border(
          left: BorderSide(
            color: _getEventColor(event.type),
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getEventColor(event.type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getEventIcon(event.type),
              color: _getEventColor(event.type),
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM').format(event.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.category, size: 10, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(symbol: r'$', decimalDigits: 0)
                    .format(event.amount.abs()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getEventColor(event.type),
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getEventColor(event.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getEventTypeLabel(event.type),
                  style: TextStyle(
                    fontSize: 9,
                    color: _getEventColor(event.type),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),        ],
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.income:
      case EventType.recurringIncome:
        return Colors.green;
      case EventType.expense:
      case EventType.recurringExpense:
        return Colors.red;
      case EventType.debt:
        return Colors.orange;
      case EventType.budget:
        return Colors.blue;
    }
  }
  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.income:
      case EventType.recurringIncome:
        return Icons.arrow_upward;
      case EventType.expense:
      case EventType.recurringExpense:
        return Icons.arrow_downward;
      case EventType.debt:
        return Icons.warning;
      case EventType.budget:
        return Icons.account_balance_wallet;
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.income:
        return 'Ingreso';
      case EventType.expense:
        return 'Gasto';
      case EventType.debt:
        return 'Deuda';
      case EventType.budget:
        return 'Presupuesto';
      case EventType.recurringIncome:
        return 'Ing. Rec.';
      case EventType.recurringExpense:
        return 'Gas. Rec.';
    }
  }

  void _showDayEvents(DateTime date, List<FinancialEvent> events) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eventos del ${DateFormat('dd/MM/yyyy').format(date)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: Icon(
                  _getEventIcon(event.type),
                  color: _getEventColor(event.type),
                ),
                title: Text(event.title),
                subtitle: Text(event.category),
                trailing: Text(
                  NumberFormat.currency(symbol: r'$', decimalDigits: 0)
                      .format(event.amount.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: event.amount >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildHeader(),
            if (widget.isExpanded) ...[
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else ...[
                _buildMonthSelector(),
                _buildCalendarView(),
                SizedBox(height: 16),
                _buildEventsList(),
                SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

enum EventType {
  income,
  expense,
  debt,
  budget,
  recurringIncome,
  recurringExpense,
}

class FinancialEvent {
  final DateTime date;
  final String title;
  final double amount;
  final EventType type;
  final String category;

  FinancialEvent({
    required this.date,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
  });
}
