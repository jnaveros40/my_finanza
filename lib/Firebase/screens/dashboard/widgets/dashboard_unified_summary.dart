// dashboard_unified_summary.dart
// Componente modular unificado para mostrar el resumen general y de cuentas en el dashboard

import 'package:flutter/material.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:intl/intl.dart';

class DashboardUnifiedSummary extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double savableAmount;
  final double totalTransferAmount;
  final double totalPaymentAmount;
  final List<Account> accounts;
  final String displayCurrency;

  const DashboardUnifiedSummary({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.savableAmount,
    required this.totalTransferAmount,
    required this.totalPaymentAmount,
    required this.accounts,
    this.displayCurrency = 'COP',
  });

  @override
  Widget build(BuildContext context) {
    // Determinar el color para la cantidad ahorrable
    Color savableAmountColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    if (savableAmount > 0) {
      savableAmountColor = Colors.green;
    } else if (savableAmount < 0) {
      savableAmountColor = Colors.red;
    }

    // Calcular el saldo total de todas las cuentas (excluyendo CC adeudado)
    double totalBalance = accounts.where((acc) => !acc.isCreditCard).fold(0.0, (sum, acc) => sum + acc.currentBalance);

    // Calcular el total adeudado en tarjetas de crédito
    double totalCreditCardDebt = accounts.where((acc) => acc.isCreditCard).fold(0.0, (sum, acc) => sum + acc.currentStatementBalance);

    // Calcular el cupo total disponible en tarjetas de crédito
    double totalCreditCardAvailable = accounts.where((acc) => acc.isCreditCard).fold(0.0, (sum, acc) => sum + acc.creditLimit) - totalCreditCardDebt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,      child: ExpansionTile(
        leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text('Resumen Financiero', style: Theme.of(context).textTheme.titleLarge),subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos: ${_formatCurrency(totalIncome, displayCurrency)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Gastos: ${_formatCurrency(totalExpense, displayCurrency)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        initiallyExpanded: false,children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen Principal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ingresos:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalIncome, displayCurrency), 
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gastos:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalExpense, displayCurrency), 
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cantidad Ahorrable:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(_formatCurrency(savableAmount, displayCurrency), 
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: savableAmountColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 16),                // Sección de Resumen General
                Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text('Detalle de Movimientos', 
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Transferido:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalTransferAmount, displayCurrency), 
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Pagado (TC):', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalPaymentAmount, displayCurrency), 
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 16),                // Sección de Resumen de Cuentas
                Row(
                  children: [
                    Icon(Icons.account_balance, size: 16, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text('Resumen de Cuentas', 
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saldo Total Cuentas Ahorro:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalBalance, displayCurrency),
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cupo Utilizado TC:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalCreditCardDebt, displayCurrency),
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                           color: Colors.red
                         )),
                  ],
                ),
                SizedBox(height: 4),                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cupo Disponible TC:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalCreditCardAvailable, displayCurrency),
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                           color: Colors.green
                         )),
                  ],
                ),
                SizedBox(height: 8),
                // Separador visual
                Divider(thickness: 1, color: Theme.of(context).dividerColor),
                SizedBox(height: 8),                // Dinero Real (Patrimonio Neto Líquido)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on, size: 16, 
                             color: (totalBalance - totalCreditCardDebt) >= 0 ? Colors.green : Colors.red),
                        SizedBox(width: 4),
                        Text('Dinero Real (Neto):', 
                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Tooltip(
                          message: 'Saldo total en cuentas menos deudas de tarjetas de crédito',
                          child: Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        ),
                      ],
                    ),                    Text(_formatCurrency(totalBalance - totalCreditCardDebt, displayCurrency),
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                           fontSize: 16,
                           color: (totalBalance - totalCreditCardDebt) >= 0 ? Colors.green : Colors.red
                         )),
                  ],
                ),
                SizedBox(height: 8),
                // Porcentaje de Endeudamiento
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 16, 
                             color: _getDebtPercentageColor(totalBalance, totalCreditCardDebt)),
                        SizedBox(width: 4),
                        Text('% Endeudamiento:', 
                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Tooltip(
                          message: 'Porcentaje de deuda respecto al total disponible',
                          child: Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    Text('${_calculateDebtPercentage(totalBalance, totalCreditCardDebt).toStringAsFixed(1)}%',
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                           color: _getDebtPercentageColor(totalBalance, totalCreditCardDebt)
                         )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  // Helper para calcular el porcentaje de endeudamiento
  double _calculateDebtPercentage(double totalBalance, double totalDebt) {
    if (totalBalance <= 0) return 100.0; // Si no hay dinero, endeudamiento al 100%
    return (totalDebt / totalBalance) * 100;
  }

  // Helper para obtener el color según el porcentaje de endeudamiento
  Color _getDebtPercentageColor(double totalBalance, double totalDebt) {
    double percentage = _calculateDebtPercentage(totalBalance, totalDebt);
    if (percentage <= 30) return Colors.green;      // Saludable
    if (percentage <= 50) return Colors.orange;     // Moderado
    return Colors.red;                               // Alto riesgo
  }
}
