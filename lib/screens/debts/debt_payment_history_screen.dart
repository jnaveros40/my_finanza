// lib/screens/debts/debt_payment_history_screen.dart

import 'package:flutter/material.dart';
import 'package:mis_finanza/models/debt.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_finanza/screens/debts/widgets/edit_debt_payment_dialog.dart';

class DebtPaymentHistoryScreen extends StatefulWidget {
  final Debt debt;

  const DebtPaymentHistoryScreen({super.key, required this.debt});

  @override
  _DebtPaymentHistoryScreenState createState() => _DebtPaymentHistoryScreenState();
}

class _DebtPaymentHistoryScreenState extends State<DebtPaymentHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Helper para obtener el símbolo de moneda
  String _getCurrencySymbol(String currencyCode) {
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
  String _formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return format.format(amount);
  }
  // Helper para obtener el texto del tipo de pago
  String _getPaymentTypeText(String type) {
    switch (type) {
      case 'normal': return 'Cuota Normal';
      case 'extra_term': return 'Abono a Capital (Reducir Plazo)';
      case 'extra_installment': return 'Abono a Capital (Reducir Cuota)';
      case 'abono_capital': return 'Abono a Capital';
      default: return type;
    }
  }
  // Helper para obtener el ícono del tipo de pago
  IconData _getPaymentTypeIcon(String type) {
    switch (type) {
      case 'normal': return Icons.payment;
      case 'extra_term':
      case 'extra_installment':
      case 'abono_capital': return Icons.trending_up;
      default: return Icons.monetization_on;
    }
  }
  // Helper para obtener el color del tipo de pago
  Color _getPaymentTypeColor(String type) {
    switch (type) {
      case 'normal': return Colors.blue;
      case 'extra_term': return Colors.green;
      case 'extra_installment': return Colors.orange;
      case 'abono_capital': return Colors.purple;
      default: return Colors.grey;
    }
  }
  // Función para calcular el número de cuota (solo para pagos normales)
  int? _calculateInstallmentNumber(List<Map<String, dynamic>> paymentHistory, int currentIndex) {
    if (paymentHistory[currentIndex]['paymentType'] != 'normal') {
      return null; // No aplica para abonos a capital
    }
    
    // Contar cuántas cuotas normales se han hecho hasta este pago
    int normalCount = 0;
    for (int i = 0; i < paymentHistory.length; i++) {
      if (paymentHistory[i]['paymentType'] == 'normal' || paymentHistory[i]['paymentType'] == null) {
        normalCount++;
        if (i == currentIndex) {
          return normalCount;
        }
      }
    }
    return normalCount;
  }

  // Función para confirmar y eliminar pago
  Future<void> _confirmAndDeletePayment(BuildContext context, String debtId, int paymentIndex) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Eliminación de Pago'),
          content: Text('¿Estás seguro de que deseas eliminar este pago?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        await _firestoreService.deleteDebtPayment(debtId, paymentIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago eliminado con éxito.')),
        );
      } catch (e) {
        print('Error al eliminar pago de deuda: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el pago: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Pagos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<Debt>>(
        stream: DebtService.getDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }

          // Buscar la deuda actualizada
          final debts = snapshot.data ?? [];
          final updatedDebt = debts.firstWhere(
            (d) => d.id == widget.debt.id,
            orElse: () => widget.debt,
          );

          final paymentHistory = updatedDebt.paymentHistory ?? [];

          if (paymentHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay pagos registrados',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Los pagos aparecerán aquí una vez que los registres',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Ordenar historial por fecha descendente
          final sortedPaymentHistory = List<Map<String, dynamic>>.from(paymentHistory);
          sortedPaymentHistory.sort((a, b) {
            final dateA = (a['date'] as Timestamp).toDate();
            final dateB = (b['date'] as Timestamp).toDate();
            return dateB.compareTo(dateA);
          });

          return Column(
            children: [
              // Header con información de la deuda
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      updatedDebt.description,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pagado:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          _formatCurrency(
                            paymentHistory.fold(0.0, (sum, payment) => 
                              sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0)
                            ),
                            updatedDebt.currency,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Número de Pagos:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${paymentHistory.length}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              // Lista de pagos
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: sortedPaymentHistory.length,
                  itemBuilder: (context, index) {
                    final payment = sortedPaymentHistory[index];
                    final paymentDate = (payment['date'] as Timestamp).toDate();
                    final paymentAmount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
                    final paymentNotes = payment['notes'] as String?;
                    final paymentType = payment['paymentType'] as String? ?? 'normal';
                    
                    // Obtener datos de amortización si existen
                    final capitalPaid = (payment['capital_paid'] as num?)?.toDouble() ?? 0.0;
                    final interestPaid = (payment['interest_paid'] as num?)?.toDouble() ?? 0.0;
                    final insurancePaid = (payment['insurance_paid'] as num?)?.toDouble() ?? 0.0;

                    // Encontrar índice original para editar/eliminar
                    final originalIndex = paymentHistory.indexOf(payment);

                    // Calcular número de cuota si es normal
                    final installmentNumber = _calculateInstallmentNumber(paymentHistory, originalIndex);

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header del pago
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getPaymentTypeColor(paymentType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getPaymentTypeIcon(paymentType),
                                    color: _getPaymentTypeColor(paymentType),
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            installmentNumber != null 
                                              ? 'Cuota #$installmentNumber'
                                              : _getPaymentTypeText(paymentType),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _formatCurrency(paymentAmount, updatedDebt.currency),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _getPaymentTypeText(paymentType),
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: _getPaymentTypeColor(paymentType),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(paymentDate),
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Desglose de pagos (si hay información de amortización)
                            if (capitalPaid > 0 || interestPaid > 0 || insurancePaid > 0) ...[
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Desglose del Pago',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    if (capitalPaid > 0)
                                      _buildBreakdownRow(
                                        'Capital',
                                        capitalPaid,
                                        updatedDebt.currency,
                                        Colors.green[600]!,
                                        Icons.account_balance,
                                      ),
                                    if (interestPaid > 0)
                                      _buildBreakdownRow(
                                        'Intereses',
                                        interestPaid,
                                        updatedDebt.currency,
                                        Colors.orange[600]!,
                                        Icons.percent,
                                      ),
                                    if (insurancePaid > 0)
                                      _buildBreakdownRow(
                                        'Seguros',
                                        insurancePaid,
                                        updatedDebt.currency,
                                        Colors.blue[600]!,
                                        Icons.security,
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            // Notas del pago
                            if (paymentNotes != null && paymentNotes.isNotEmpty) ...[
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.note, size: 16, color: Colors.blue[700]),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        paymentNotes,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Botones de acción
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return EditDebtPaymentDialog(
                                          debt: updatedDebt,
                                          paymentIndex: originalIndex,
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(Icons.edit, size: 16),
                                  label: Text('Editar'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    _confirmAndDeletePayment(context, updatedDebt.id!, originalIndex);
                                  },
                                  icon: Icon(Icons.delete, size: 16),
                                  label: Text('Eliminar'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget helper para crear filas del desglose
  Widget _buildBreakdownRow(String label, double amount, String currency, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatCurrency(amount, currency),
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
