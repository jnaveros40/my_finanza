// dashboard_account_summary.dart
// Componente modular para mostrar el resumen de cuentas en el dashboard

import 'package:flutter/material.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:intl/intl.dart';

class DashboardAccountSummary extends StatelessWidget {
  final List<Account> accounts;
  final String displayCurrency;

  const DashboardAccountSummary({
    super.key,
    required this.accounts,
    this.displayCurrency = 'COP',
  });

  @override
  Widget build(BuildContext context) {
    // Calcular el saldo total de todas las cuentas (excluyendo CC adeudado)
    double totalBalance = accounts.where((acc) => !acc.isCreditCard).fold(0.0, (sum, acc) => sum + acc.currentBalance);

    // Calcular el total adeudado en tarjetas de crédito
    double totalCreditCardDebt = accounts.where((acc) => acc.isCreditCard).fold(0.0, (sum, acc) => sum + acc.currentStatementBalance);

    // Calcular el cupo total disponible en tarjetas de crédito
    double totalCreditCardAvailable = accounts.where((acc) => acc.isCreditCard).fold(0.0, (sum, acc) => sum + acc.creditLimit) - totalCreditCardDebt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen de Cuentas', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text('Saldo Total Cuentas Ahorro:', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    _formatCurrency(totalBalance, displayCurrency),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
               ],
            ),
            SizedBox(height: 4),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text('Cupo Utilizado TC:', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    _formatCurrency(totalCreditCardDebt, displayCurrency),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red
                    ),
                  ),
               ],
            ),
            SizedBox(height: 4),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text('Cupo Disponible TC:', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    _formatCurrency(totalCreditCardAvailable, displayCurrency),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green
                    ),
                  ),
               ],
            ),
          ],
        ),
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