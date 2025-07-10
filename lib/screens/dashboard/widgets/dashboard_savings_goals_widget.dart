// lib/screens/dashboard/widgets/dashboard_savings_goals_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:intl/intl.dart';

class DashboardSavingsGoalsWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;

  const DashboardSavingsGoalsWidget({
    super.key,
    required this.accounts,
    required this.movements,
  });

  @override
  _DashboardSavingsGoalsWidgetState createState() => _DashboardSavingsGoalsWidgetState();
}

class _DashboardSavingsGoalsWidgetState extends State<DashboardSavingsGoalsWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final savingsGoals = _getSavingsGoals();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.savings_rounded,
            color: Colors.green,
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Metas de Ahorro',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.track_changes_rounded,
              size: 14,
              color: Colors.green,
            ),
            SizedBox(width: 4),
            Text(
              savingsGoals.isEmpty 
                  ? 'Sin metas configuradas'
                  : '${savingsGoals.length} ${savingsGoals.length == 1 ? 'meta activa' : 'metas activas'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: savingsGoals.isEmpty
                ? _buildNoGoalsWidget()
                : _buildGoalsList(savingsGoals),
          ),
        ],
      ),
    );
  }

  List<SavingsGoal> _getSavingsGoals() {
    List<SavingsGoal> goals = [];
    
    for (final account in widget.accounts) {
      if (account.savingsTargetAmount != null && 
          account.savingsTargetAmount! > 0 &&
          account.savingsTargetDate != null) {
        
        final currentAmount = account.currentBalance;
        final targetAmount = account.savingsTargetAmount!;
        final targetDate = account.savingsTargetDate!;
        final progress = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
        
        // Calcular días restantes
        final now = DateTime.now();
        final daysRemaining = targetDate.difference(now).inDays;
        
        // Calcular ahorro mensual requerido
        final monthsRemaining = daysRemaining / 30.44; // Promedio de días por mes
        final remainingAmount = targetAmount - currentAmount;
        final requiredMonthlySavings = monthsRemaining > 0 ? remainingAmount / monthsRemaining : 0.0;
        
        goals.add(SavingsGoal(
          accountId: account.id ?? '',
          accountName: account.name,
          currentAmount: currentAmount,
          targetAmount: targetAmount,
          targetDate: targetDate,
          progress: progress.clamp(0.0, 1.0),
          daysRemaining: daysRemaining,
          requiredMonthlySavings: requiredMonthlySavings,
          currency: account.currency,
        ));
      }
    }
    
    // Ordenar por progreso (menor progreso primero)
    goals.sort((a, b) => a.progress.compareTo(b.progress));
    
    return goals;
  }

  Widget _buildNoGoalsWidget() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 12),
          Text(
            'Sin metas de ahorro',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Configura metas de ahorro en tus cuentas para hacer seguimiento a tus objetivos financieros',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToAccounts(),
            icon: Icon(Icons.add_rounded, size: 18),
            label: Text('Configurar metas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<SavingsGoal> goals) {
    return Column(
      children: goals.map((goal) => _buildGoalCard(goal)).toList(),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    final isOverdue = goal.daysRemaining < 0;
    final isUrgent = goal.daysRemaining <= 30 && goal.daysRemaining >= 0;
    final isCompleted = goal.progress >= 1.0;
    
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle_rounded;
    String statusText = 'Completada';
    
    if (!isCompleted) {
      if (isOverdue) {
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        statusText = 'Vencida';
      } else if (isUrgent) {
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        statusText = 'Urgente';
      } else {
        statusColor = Colors.blue;
        statusIcon = Icons.trending_up_rounded;
        statusText = 'En progreso';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nombre y estado
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.accountName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Barra de progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso: ${(goal.progress * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_formatCurrency(goal.currentAmount)} / ${_formatCurrency(goal.targetAmount)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Información adicional
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.calendar_today_rounded,
                  isOverdue 
                      ? 'Venció hace ${(-goal.daysRemaining)} días'
                      : '${goal.daysRemaining} días restantes',
                  isOverdue ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  Icons.savings_rounded,
                  'Req: ${_formatCurrency(goal.requiredMonthlySavings)}/mes',
                  Colors.green,
                ),
              ),
            ],
          ),
          
          if (!isCompleted && goal.daysRemaining > 0) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showGoalDetails(goal),
                    icon: Icon(Icons.insights_rounded, size: 16),
                    label: Text('Ver detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: statusColor,
                      side: BorderSide(color: statusColor),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeDeposit(goal),
                    icon: Icon(Icons.add_rounded, size: 16),
                    label: Text('Depositar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
  void _navigateToAccounts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a configuración de cuentas...')),
    );
  }

  void _showGoalDetails(SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Meta: ${goal.accountName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Meta:', _formatCurrency(goal.targetAmount)),
            _buildDetailRow('Actual:', _formatCurrency(goal.currentAmount)),
            _buildDetailRow('Faltante:', _formatCurrency(goal.targetAmount - goal.currentAmount)),
            _buildDetailRow('Fecha límite:', DateFormat('dd/MM/yyyy').format(goal.targetDate)),
            _buildDetailRow('Días restantes:', '${goal.daysRemaining} días'),
            _buildDetailRow('Ahorro mensual requerido:', _formatCurrency(goal.requiredMonthlySavings)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _makeDeposit(SavingsGoal goal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de depósito para ${goal.accountName}')),
    );
  }
}

// Clase auxiliar para las metas de ahorro
class SavingsGoal {
  final String accountId;
  final String accountName;
  final double currentAmount;
  final double targetAmount;
  final DateTime targetDate;
  final double progress;
  final int daysRemaining;
  final double requiredMonthlySavings;
  final String currency;

  SavingsGoal({
    required this.accountId,
    required this.accountName,
    required this.currentAmount,
    required this.targetAmount,
    required this.targetDate,
    required this.progress,
    required this.daysRemaining,
    required this.requiredMonthlySavings,
    required this.currency,
  });
}
