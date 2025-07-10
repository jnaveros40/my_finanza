// dashboard_general_summary.dart
// Componente modular para mostrar el resumen general en el dashboard

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardGeneralSummary extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double savableAmount;
  final double totalTransferAmount;
  final double totalPaymentAmount;
  final String displayCurrency;

  const DashboardGeneralSummary({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.savableAmount,
    required this.totalTransferAmount,
    required this.totalPaymentAmount,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,      child: ExpansionTile(
        leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text('Resumen General', style: Theme.of(context).textTheme.titleLarge),subtitle: Column(
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
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cantidad ahorrable:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(_formatCurrency(savableAmount, displayCurrency), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: savableAmountColor)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Transferido:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalTransferAmount, displayCurrency), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Pagado (Tarjetas Crédito):', style: Theme.of(context).textTheme.bodyMedium),
                    Text(_formatCurrency(totalPaymentAmount, displayCurrency), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
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
}