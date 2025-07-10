// lib/widgets/dashboard/dashboard_debt_overview.dart

import 'package:flutter/material.dart';
import 'package:mis_finanza/models/debt.dart';
import 'package:mis_finanza/screens/debts/utils/debt_progress_calculator.dart';
import 'package:intl/intl.dart';

class DashboardDebtOverview extends StatelessWidget {
  final List<Debt> debts;
  final String displayCurrency;

  const DashboardDebtOverview({
    super.key,
    required this.debts,
    required this.displayCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular el total de la deuda pendiente
    final totalDebt = _calculateTotalDebt(debts);
    // Obtener próximas cuotas de deudas
    final upcomingDebts = _getUpcomingDebtPayments(debts);      return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Icon(Icons.trending_up, color: totalDebt > 0 ? Colors.red : Colors.green),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text('Resumen de Deudas', style: Theme.of(context).textTheme.titleLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${debts.where((d) => d.status == 'active').length} deuda${debts.where((d) => d.status == 'active').length != 1 ? 's' : ''} activa${debts.where((d) => d.status == 'active').length != 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodyMedium),
            Text('Total: ${_formatCurrency(totalDebt, displayCurrency)}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        children: [
          // Header section with summary information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.account_balance, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 8),
                Text('Análisis de Deudas', style: Theme.of(context).textTheme.titleMedium),
                Spacer(),
                Tooltip(
                  message: 'Resumen completo de tus deudas y próximas cuotas',
                  child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
          // Total debt display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  totalDebt > 0 ? Icons.warning : Icons.check_circle,
                  color: totalDebt > 0 ? Colors.red : Colors.green,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Total Deuda Pendiente: ${_formatCurrency(totalDebt, displayCurrency)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: totalDebt > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,              children: [
                // Sección de deudas activas
                Row(
                  children: [
                    Icon(Icons.list_alt, color: Theme.of(context).colorScheme.secondary, size: 20),
                    SizedBox(width: 8),
                    Text('Deudas Activas:', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                SizedBox(height: 8),
                  // Mostrar lista de todas las deudas activas
                if (debts.where((d) => d.status == 'active').isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,                    children: debts.where((d) => d.status == 'active').map((debt) {                      // Calcular cuotas pagadas usando la utilidad
                      final paidInstallments = calculatePaidInstallments(debt.paymentHistory);
                      final totalInstallments = debt.totalInstallments ?? 0;
                      
                      // Calcular progreso del pago usando la utilidad
                      final progressPercentage = calculateDebtProgress(
                        paidInstallments: paidInstallments,
                        totalInstallments: totalInstallments,
                        initialAmount: debt.initialAmount,
                        currentAmount: debt.currentAmount,
                      );
                      
                      // DEBUG: //Print calculation details
                      //print('=== DASHBOARD DEBT PROGRESS DEBUG (${debt.description}) ===');
                      //print('totalInstallments: $totalInstallments');
                      //print('paidInstallments: $paidInstallments');
                      //print('initialAmount: ${debt.initialAmount}');
                      //print('currentAmount: ${debt.currentAmount}');
                      //print('Calculation method: ${totalInstallments > 0 ? "installments" : "amount"}');
                      if (totalInstallments > 0) {
                        //print('Progress = ($paidInstallments / $totalInstallments) * 100 = $progressPercentage%');
                      } else {
                        //print('Progress = ((${debt.initialAmount} - ${debt.currentAmount}) / ${debt.initialAmount}) * 100 = $progressPercentage%');
                      }
                      //print('===============================================');
                      
                      // Calcular próximo pago si tiene paymentDay
                      String nextPaymentText = 'Sin fecha definida';
                      if (debt.paymentDay != null) {
                        final nextPayment = _calculateNextPaymentDate(debt.paymentDay!);
                        final daysUntil = nextPayment.difference(DateTime.now()).inDays;
                        
                        if (daysUntil < 0) {
                          nextPaymentText = 'Vencido hace ${(-daysUntil)} día${(-daysUntil) > 1 ? 's' : ''}';
                        } else if (daysUntil == 0) {
                          nextPaymentText = 'Vence hoy';
                        } else if (daysUntil == 1) {
                          nextPaymentText = 'Vence mañana';
                        } else {
                          nextPaymentText = 'En $daysUntil días';
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: Theme.of(context).colorScheme.secondary,
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        debt.description,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            'Próximo pago: $nextPaymentText',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          if (debt.installmentValue != null) ...[
                                            Text(
                                              ' • ${_formatCurrency(debt.installmentValue!, debt.currency)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatCurrency(debt.currentAmount, debt.currency),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),                                    if (progressPercentage > 0)
                                      Text(
                                        '${progressPercentage.toStringAsFixed(1)}% pagado',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (totalInstallments > 0)
                                      Text(
                                        '$paidInstallments/$totalInstallments cuotas',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Mostrar barra de progreso
                            if (progressPercentage > 0) ...[
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progressPercentage / 100,
                                  minHeight: 5,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  color: progressPercentage > 75 
                                    ? Colors.green 
                                    : progressPercentage > 50 
                                      ? Colors.orange 
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No tienes deudas activas.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 16),
                  // Sección de próximas cuotas
                Container(
                  padding: const EdgeInsets.all(16.0),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Próximas Cuotas',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (upcomingDebts.isNotEmpty)
                                  Text(
                                    '${upcomingDebts.length} cuota${upcomingDebts.length > 1 ? 's' : ''} programada${upcomingDebts.length > 1 ? 's' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Mostrar lista de próximas cuotas si hay
                      if (upcomingDebts.isNotEmpty) ...[
                        // Destacar la primera cuota (más urgente)
                        _buildHighlightedDebtCard(context, upcomingDebts.first),
                        
                        // Mostrar el resto de cuotas si hay más
                        if (upcomingDebts.length > 1) ...[
                          SizedBox(height: 12),
                          Text(
                            'Otras cuotas próximas:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...upcomingDebts.skip(1).map((debt) => _buildRegularDebtCard(context, debt)),
                        ],
                      ],
                    ],
                  ),
                ),
                
                // Mostrar mensaje si no hay próximas cuotas
                if (upcomingDebts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(top: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Todo al día',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'No hay próximas cuotas de deuda programadas.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),                  ),
                
                SizedBox(height: 16),
                  // Distribución por deudas individuales (si hay deudas)
                if (debts.where((debt) => debt.status == 'active').isNotEmpty) ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.secondary, size: 20),
                      SizedBox(width: 8),
                      Text('Distribución de Deudas:', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildIndividualDebtDistribution(context),
                  
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.secondary, size: 20),
                      SizedBox(width: 8),
                      Text('Resumen de Pagos Mensuales:', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildMonthlyPaymentSummary(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
    // Widget para construir la distribución por deudas individuales
  Widget _buildIndividualDebtDistribution(BuildContext context) {
    // Filtrar deudas activas y ordenar por monto descendente
    final activeDebts = debts
        .where((debt) => debt.status == 'active')
        .toList()
        ..sort((a, b) => b.currentAmount.compareTo(a.currentAmount));
    
    if (activeDebts.isEmpty) return SizedBox.shrink();
    
    final totalAmount = activeDebts.fold(0.0, (sum, debt) => sum + debt.currentAmount);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activeDebts.map((debt) {
        final percentage = totalAmount > 0 ? (debt.currentAmount / totalAmount) * 100 : 0.0;
        
        // Calcular progreso usando la utilidad
        final paidInstallments = calculatePaidInstallments(debt.paymentHistory);
        final progress = calculateDebtProgress(
          paidInstallments: paidInstallments,
          totalInstallments: debt.totalInstallments ?? 0,
          initialAmount: debt.initialAmount,
          currentAmount: debt.currentAmount,
        );
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getDebtTypeColor(debt.type),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    margin: EdgeInsets.only(right: 12),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${percentage.toStringAsFixed(1)}% del total',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(debt.currentAmount, debt.currency),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      if (progress > 0)
                        Text(
                          '${progress.toStringAsFixed(1)}% pagado',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              // Barra de progreso del porcentaje del total
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: _getDebtTypeColor(debt.type),
                ),
              ),
              
              // Información adicional si hay pagos programados
              if (debt.installmentValue != null) ...[
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cuota mensual:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _formatCurrency(debt.installmentValue!, debt.currency),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // Widget para construir el resumen de pagos mensuales
  Widget _buildMonthlyPaymentSummary(BuildContext context) {
    final activeDebts = debts.where((debt) => debt.status == 'active').toList();
    
    if (activeDebts.isEmpty) return SizedBox.shrink();
    
    // Calcular total de pagos mensuales
    double totalMonthlyPayments = 0.0;
    int debtsWithPayments = 0;
    double averagePayment = 0.0;
    
    for (var debt in activeDebts) {
      if (debt.installmentValue != null && debt.installmentValue! > 0) {
        totalMonthlyPayments += debt.installmentValue!;
        debtsWithPayments++;
      }
    }
    
    if (debtsWithPayments > 0) {
      averagePayment = totalMonthlyPayments / debtsWithPayments;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payments,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Compromisos Mensuales',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPaymentMetric(
                  context,
                  'Total Mensual',
                  _formatCurrency(totalMonthlyPayments, displayCurrency),
                  Icons.account_balance_wallet,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPaymentMetric(
                  context,
                  'Deudas con Pagos',
                  '$debtsWithPayments de ${activeDebts.length}',
                  Icons.list_alt,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          
          if (averagePayment > 0) ...[
            SizedBox(height: 12),
            _buildPaymentMetric(
              context,
              'Pago Promedio',
              _formatCurrency(averagePayment, displayCurrency),
              Icons.trending_up,
              Colors.green,
              fullWidth: true,
            ),
          ],
          
          // Mostrar advertencia si hay deudas sin valor de cuota definido
          if (debtsWithPayments < activeDebts.length) ...[
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${activeDebts.length - debtsWithPayments} deuda${activeDebts.length - debtsWithPayments > 1 ? 's' : ''} sin valor de cuota definido',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Helper para construir métricas de pago
  Widget _buildPaymentMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: fullWidth ? TextAlign.center : TextAlign.start,
          ),
        ],
      ),
    );
  }
  
  // Helper para calcular el total de deuda pendiente
  double _calculateTotalDebt(List<Debt> debts) {
    double total = 0.0;
    for (var debt in debts) {
      if (debt.status == 'active') {
        total += debt.currentAmount;
      }
    }
    return total;
  }
    // Helper para obtener las próximas cuotas de deuda usando paymentDay
  List<Debt> _getUpcomingDebtPayments(List<Debt> debts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return debts
      .where((d) => d.status == 'active' && d.paymentDay != null)
      .map((d) {
        final nextPaymentDate = _calculateNextPaymentDate(d.paymentDay!);
        // Crear una copia de la deuda con la fecha calculada
        return d.copyWith(dueDate: nextPaymentDate);
      })
      .where((d) => d.dueDate!.isAfter(today.subtract(Duration(days: 1))))
      .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }
    // Helper para calcular la próxima fecha de pago basada en paymentDay
  DateTime _calculateNextPaymentDate(int paymentDay) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    
    // Si hoy ya pasó el día de pago, ir al mes siguiente
    if (now.day > paymentDay) {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
    }
    
    // Ajustar el día si el mes tiene menos días que paymentDay
    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    int day = paymentDay <= lastDayOfMonth ? paymentDay : lastDayOfMonth;
    
    return DateTime(year, month, day);
  }  // Helper para asociar colores a tipos de deuda
  Color _getDebtTypeColor(String type) {
    switch (type) {
      case 'loan': return Colors.red;
      case 'mortgage': return Colors.orange;
      case 'credit_card_debt': return Colors.pink;
      case 'student_loan': return Colors.deepPurple;
      case 'other': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }
  
  // Helper para formatear moneda
  String _formatCurrency(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  // Helper para obtener el símbolo de moneda
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'COP': return '\$';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      default: return currencyCode;
    }
  }  // Helper para crear card destacada de deuda próxima (la más urgente)
  Widget _buildHighlightedDebtCard(BuildContext context, Debt debt) {
    final isOverdue = debt.dueDate!.isBefore(DateTime.now());
    final daysUntilDue = debt.dueDate!.difference(DateTime.now()).inDays;
    final isUrgent = daysUntilDue <= 3 && !isOverdue;
    
    // Calcular cuotas pagadas vs totales usando la utilidad
    final paidInstallments = calculatePaidInstallments(debt.paymentHistory);
    final totalInstallments = debt.totalInstallments ?? 0;
    
    // Calcular progreso del pago usando la utilidad
    final progressPercentage = calculateDebtProgress(
      paidInstallments: paidInstallments,
      totalInstallments: totalInstallments,
      initialAmount: debt.initialAmount,
      currentAmount: debt.currentAmount,
    );
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isOverdue 
          ? Colors.red.withOpacity(0.1)
          : isUrgent 
            ? Colors.orange.withOpacity(0.1)
            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue 
            ? Colors.red.withOpacity(0.3)
            : isUrgent 
              ? Colors.orange.withOpacity(0.3)
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOverdue 
                    ? Colors.red 
                    : isUrgent 
                      ? Colors.orange 
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOverdue 
                    ? Icons.warning 
                    : isUrgent 
                      ? Icons.priority_high 
                      : Icons.payment,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? Colors.red : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      isOverdue 
                        ? 'Vencida hace ${(-daysUntilDue)} día${(-daysUntilDue) > 1 ? 's' : ''}'
                        : daysUntilDue == 0
                          ? 'Vence hoy'
                          : daysUntilDue == 1
                            ? 'Vence mañana'
                            : 'Vence en $daysUntilDue días',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue 
                          ? Colors.red 
                          : isUrgent 
                            ? Colors.orange 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Progreso de pago
          if (progressPercentage > 0) ...[
            Row(
              children: [
                Text(
                  'Progreso: ${progressPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (totalInstallments > 0) ...[
                  Text(
                    ' • $paidInstallments/$totalInstallments cuotas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercentage / 100,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: progressPercentage > 75 
                  ? Colors.green 
                  : progressPercentage > 50 
                    ? Colors.orange 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 12),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximo pago',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(debt.dueDate!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? Colors.red : null,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Valor cuota',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _formatCurrency(debt.installmentValue ?? debt.currentAmount, debt.currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Información adicional
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo: ${_formatCurrency(debt.currentAmount, debt.currency)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (debt.creditorDebtor != null)
                Text(
                  debt.creditorDebtor!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }  // Helper para crear card regular de deuda próxima
  Widget _buildRegularDebtCard(BuildContext context, Debt debt) {
    final isOverdue = debt.dueDate!.isBefore(DateTime.now());
    final daysUntilDue = debt.dueDate!.difference(DateTime.now()).inDays;
    
    // Calcular cuotas pagadas vs totales usando la utilidad
    final paidInstallments = calculatePaidInstallments(debt.paymentHistory);
    final totalInstallments = debt.totalInstallments ?? 0;
    
    // Calcular progreso del pago usando la utilidad
    final progressPercentage = calculateDebtProgress(
      paidInstallments: paidInstallments,
      totalInstallments: totalInstallments,
      initialAmount: debt.initialAmount,
      currentAmount: debt.currentAmount,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isOverdue 
          ? Colors.red.withOpacity(0.05)
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue 
            ? Colors.red.withOpacity(0.2)
            : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isOverdue 
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isOverdue ? Icons.warning : Icons.payment,
                  color: isOverdue 
                    ? Colors.red 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      isOverdue 
                        ? 'Vencida hace ${(-daysUntilDue)} día${(-daysUntilDue) > 1 ? 's' : ''}'
                        : DateFormat('dd/MM/yyyy').format(debt.dueDate!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(debt.installmentValue ?? debt.currentAmount, debt.currency),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red : null,
                    ),
                  ),                  if (progressPercentage > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [                        Text(
                          '${progressPercentage.toStringAsFixed(1)}% pagado',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (totalInstallments > 0)
                          Text(
                            '$paidInstallments/$totalInstallments cuotas',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          
          // Mostrar barra de progreso para tarjetas regulares también
          if (progressPercentage > 0) ...[
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progressPercentage / 100,
                minHeight: 4,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                color: progressPercentage > 75 
                  ? Colors.green.withOpacity(0.7) 
                  : progressPercentage > 50 
                    ? Colors.orange.withOpacity(0.7)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
