// lib/screens/dashboard/widgets/dashboard_alerts_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/budget.dart';
import 'package:mis_finanza/models/debt.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';

class DashboardAlertsWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;
  final List<Budget> budgets;
  final List<Debt> debts;
  final List<Category> categories;

  const DashboardAlertsWidget({
    super.key,
    required this.accounts,
    required this.movements,
    required this.budgets,
    required this.debts,
    required this.categories,
  });

  @override
  _DashboardAlertsWidgetState createState() => _DashboardAlertsWidgetState();
}

class _DashboardAlertsWidgetState extends State<DashboardAlertsWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final alerts = _generateAlerts();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alerts.any((alert) => alert.priority == AlertPriority.high)
                ? Colors.red.withOpacity(0.2)
                : alerts.any((alert) => alert.priority == AlertPriority.medium)
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.notification_important_rounded,
            color: alerts.any((alert) => alert.priority == AlertPriority.high)
                ? Colors.red
                : alerts.any((alert) => alert.priority == AlertPriority.medium)
                    ? Colors.orange
                    : Colors.blue,
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Alertas Financieras',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            if (alerts.isEmpty)
              Text(
                'Todo bajo control',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              )
            else ...[
              Icon(
                Icons.warning_rounded,
                size: 14,
                color: alerts.any((alert) => alert.priority == AlertPriority.high)
                    ? Colors.red
                    : Colors.orange,
              ),
              SizedBox(width: 4),
              Text(
                '${alerts.length} ${alerts.length == 1 ? 'alerta' : 'alertas'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: alerts.any((alert) => alert.priority == AlertPriority.high)
                      ? Colors.red
                      : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: alerts.isEmpty
                ? _buildNoAlertsWidget()
                : _buildAlertsList(alerts),
          ),
        ],
      ),
    );
  }

  List<FinancialAlert> _generateAlerts() {
    List<FinancialAlert> alerts = [];
    final now = DateTime.now();

    // 1. Alertas de tarjetas de crédito próximas a vencer
    alerts.addAll(_checkCreditCardDueDates(now));

    // 2. Alertas de presupuestos casi agotados
    alerts.addAll(_checkBudgetAlerts(now));

    // 3. Alertas de cuentas con saldo bajo
    alerts.addAll(_checkLowBalanceAlerts());

    // 4. Alertas de deudas próximas a vencer
    alerts.addAll(_checkDebtAlerts(now));

    // 5. Alertas de gastos inusuales
    alerts.addAll(_checkUnusualSpendingAlerts());

    // Ordenar por prioridad (alta, media, baja)
    alerts.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return alerts;
  }
  List<FinancialAlert> _checkCreditCardDueDates(DateTime now) {
    List<FinancialAlert> alerts = [];
    
    for (final account in widget.accounts) {
      if (account.isCreditCard && account.paymentDueDay != null) {
        final dueDate = DateTime(now.year, now.month, account.paymentDueDay!);
        final daysUntilDue = dueDate.difference(now).inDays;
        
        if (daysUntilDue <= 3 && daysUntilDue >= 0) {
          alerts.add(FinancialAlert(
            id: 'cc_due_${account.id}',
            title: 'Pago de TC próximo',
            message: 'La tarjeta ${account.name} vence en $daysUntilDue ${daysUntilDue == 1 ? 'día' : 'días'}',
            priority: daysUntilDue <= 1 ? AlertPriority.high : AlertPriority.medium,
            icon: Icons.credit_card_rounded,
            color: daysUntilDue <= 1 ? Colors.red : Colors.orange,
            actionText: 'Ver detalles',
            onTap: () => _showAccountDetails(account),
          ));
        }
      }
    }
    
    return alerts;
  }
  List<FinancialAlert> _checkBudgetAlerts(DateTime now) {
    List<FinancialAlert> alerts = [];
    final currentMonthYear = DateFormat('yyyy-MM').format(now);
    
    final currentBudget = widget.budgets
        .where((b) => b.monthYear == currentMonthYear)
        .firstOrNull;
    
    if (currentBudget != null) {
      final currentMonthMovements = widget.movements.where((m) =>
          m.type == 'expense' &&
          DateFormat('yyyy-MM').format(m.dateTime) == currentMonthYear).toList();
      
      for (final categoryId in currentBudget.categoryBudgets.keys) {
        final budgetedAmount = currentBudget.categoryBudgets[categoryId]!;
        final spent = currentMonthMovements
            .where((m) => m.categoryId == categoryId)
            .fold(0.0, (sum, m) => sum + m.amount);
        
        final percentage = budgetedAmount > 0 
            ? (spent / budgetedAmount) * 100 
            : 0.0;
        
        final category = widget.categories
            .where((c) => c.id == categoryId)
            .firstOrNull;
        
        if (percentage >= 90) {
          alerts.add(FinancialAlert(
            id: 'budget_$categoryId',
            title: 'Presupuesto casi agotado',
            message: '${category?.name ?? 'Categoría'}: ${percentage.toStringAsFixed(0)}% usado (${_formatCurrency(spent)}/${_formatCurrency(budgetedAmount)})',
            priority: percentage >= 100 ? AlertPriority.high : AlertPriority.medium,
            icon: Icons.account_balance_wallet_rounded,
            color: percentage >= 100 ? Colors.red : Colors.orange,
            actionText: 'Ver presupuesto',
            onTap: () => _showBudgetDetails(currentBudget),
          ));
        }
      }
    }
    
    return alerts;
  }
  List<FinancialAlert> _checkLowBalanceAlerts() {
    List<FinancialAlert> alerts = [];
    
    for (final account in widget.accounts) {
      if (!account.isCreditCard && account.currentBalance < 50000) { // Menos de $50,000
        alerts.add(FinancialAlert(
          id: 'low_balance_${account.id}',
          title: 'Saldo bajo',
          message: '${account.name}: ${_formatCurrency(account.currentBalance)}',
          priority: account.currentBalance < 20000 ? AlertPriority.high : AlertPriority.medium,
          icon: Icons.account_balance_rounded,
          color: account.currentBalance < 20000 ? Colors.red : Colors.orange,
          actionText: 'Ver cuenta',
          onTap: () => _showAccountDetails(account),
        ));
      }
    }
    
    return alerts;
  }
  List<FinancialAlert> _checkDebtAlerts(DateTime now) {
    List<FinancialAlert> alerts = [];
    
    for (final debt in widget.debts) {
      if (debt.paymentDay != null) {
        final paymentDate = DateTime(now.year, now.month, debt.paymentDay!);
        final daysUntilPayment = paymentDate.difference(now).inDays;
        
        if (daysUntilPayment <= 5 && daysUntilPayment >= 0) {
          alerts.add(FinancialAlert(
            id: 'debt_${debt.id}',
            title: 'Pago de deuda próximo',
            message: '${debt.description}: ${_formatCurrency(debt.installmentValue ?? 0)} en $daysUntilPayment ${daysUntilPayment == 1 ? 'día' : 'días'}',
            priority: daysUntilPayment <= 2 ? AlertPriority.high : AlertPriority.medium,
            icon: Icons.account_balance_rounded,
            color: daysUntilPayment <= 2 ? Colors.red : Colors.orange,
            actionText: 'Ver deuda',
            onTap: () => _showDebtDetails(debt),
          ));
        }
      }
    }
    
    return alerts;
  }

  List<FinancialAlert> _checkUnusualSpendingAlerts() {
    List<FinancialAlert> alerts = [];
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    
    // Gastos del mes actual
    final currentMonthExpenses = widget.movements
        .where((m) => 
            m.type == 'expense' && 
            m.dateTime.isAfter(currentMonth))
        .fold(0.0, (sum, m) => sum + m.amount);
    
    // Gastos del mes pasado
    final lastMonthExpenses = widget.movements
        .where((m) => 
            m.type == 'expense' && 
            m.dateTime.isAfter(lastMonth) && 
            m.dateTime.isBefore(currentMonth))
        .fold(0.0, (sum, m) => sum + m.amount);
    
    if (lastMonthExpenses > 0) {
      final increasePercentage = ((currentMonthExpenses - lastMonthExpenses) / lastMonthExpenses) * 100;
      
      if (increasePercentage > 20) {
        alerts.add(FinancialAlert(
          id: 'unusual_spending',
          title: 'Gastos inusuales',
          message: 'Gastos ${increasePercentage.toStringAsFixed(0)}% más altos que el mes pasado',
          priority: increasePercentage > 50 ? AlertPriority.high : AlertPriority.medium,
          icon: Icons.trending_up_rounded,
          color: increasePercentage > 50 ? Colors.red : Colors.orange,
          actionText: 'Ver análisis',
          onTap: () => _showSpendingAnalysis(),
        ));
      }
    }
    
    return alerts;
  }

  Widget _buildNoAlertsWidget() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Colors.green,
          ),
          SizedBox(height: 12),
          Text(
            '¡Todo bajo control!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No hay alertas financieras en este momento',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<FinancialAlert> alerts) {
    return Column(
      children: alerts.map((alert) => _buildAlertCard(alert)).toList(),
    );
  }

  Widget _buildAlertCard(FinancialAlert alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alert.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              alert.icon,
              color: alert.color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: alert.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  alert.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (alert.onTap != null) ...[
            SizedBox(width: 8),
            TextButton(
              onPressed: alert.onTap,
              style: TextButton.styleFrom(
                foregroundColor: alert.color,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(
                alert.actionText ?? 'Ver',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Métodos de navegación (placeholder - implementar según tu estructura de navegación)
  void _showAccountDetails(Account account) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver detalles de ${account.name}')),
    );
  }

  void _showBudgetDetails(Budget budget) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver presupuesto de ${budget.monthYear}')),
    );
  }
  void _showDebtDetails(Debt debt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver detalles de ${debt.description}')),
    );
  }

  void _showSpendingAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver análisis de gastos')),
    );
  }
}

// Clases auxiliares para las alertas
enum AlertPriority { high, medium, low }

class FinancialAlert {
  final String id;
  final String title;
  final String message;
  final AlertPriority priority;
  final IconData icon;
  final Color color;
  final String? actionText;
  final VoidCallback? onTap;

  FinancialAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.icon,
    required this.color,
    this.actionText,
    this.onTap,
  });
}
