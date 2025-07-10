import 'package:flutter/material.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:intl/intl.dart';

class DashboardCreditCardDetails extends StatelessWidget {
  final List<Account> accounts;
  final String displayCurrency;

  const DashboardCreditCardDetails({
    super.key,
    required this.accounts,
    this.displayCurrency = 'COP',
  });
  @override
  Widget build(BuildContext context) {
    final creditCards = accounts.where((acc) => acc.isCreditCard).toList();
    // Ordenar de mayor a menor cupo utilizado
    creditCards.sort((a, b) {
      final usedA = a.creditLimit - a.currentBalance;
      final usedB = b.creditLimit - b.currentBalance;
      return usedB.compareTo(usedA);
    });

    // Calcular totales para el subtitle
    final totalUsed = creditCards.fold(0.0, (sum, card) => sum + (card.creditLimit - card.currentBalance));
    final totalAvailable = creditCards.fold(0.0, (sum, card) => sum + card.currentBalance);if (creditCards.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
          title: Text('Detalle de Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('No hay tarjetas de crédito registradas', style: Theme.of(context).textTheme.bodyMedium),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Agrega tus tarjetas de crédito para hacer seguimiento de tus cupos y fechas de pago.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),        title: Text('Detalle de Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${creditCards.length} tarjeta${creditCards.length != 1 ? 's' : ''} registrada${creditCards.length != 1 ? 's' : ''}', 
                   style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Utilizado: ${_formatCurrency(totalUsed, displayCurrency)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Disponible: ${_formatCurrency(totalAvailable, displayCurrency)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          // Header section with summary information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 8),
                Text('Resumen de Tarjetas', style: Theme.of(context).textTheme.titleMedium),
                Spacer(),
                Tooltip(
                  message: 'Información detallada de tus tarjetas de crédito',
                  child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: creditCards.map((card) {
                final used = card.creditLimit - card.currentBalance;
                final available = card.currentBalance;
                final usagePercentage = (used / card.creditLimit * 100).clamp(0, 100);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header with name and currency
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(card.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_money, size: 14, color: Theme.of(context).colorScheme.secondary),
                                Text(card.currency, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Payment dates
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Theme.of(context).colorScheme.secondary),
                          SizedBox(width: 4),
                          Text('Corte: ${card.cutOffDay ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
                          SizedBox(width: 16),
                          Icon(Icons.payment, size: 16, color: Theme.of(context).colorScheme.secondary),
                          SizedBox(width: 4),
                          Text('Pago: ${card.paymentDueDay ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    // Usage indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Uso del cupo:', style: Theme.of(context).textTheme.bodySmall),
                              Text('${usagePercentage.toStringAsFixed(1)}%', 
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: usagePercentage > 80 ? Colors.red : usagePercentage > 60 ? Colors.orange : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: usagePercentage / 100,
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              usagePercentage > 80 ? Colors.red : usagePercentage > 60 ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Balance details
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.trending_up, size: 16, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text('Cupo utilizado:', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                              Text(_formatCurrency(used, card.currency), 
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.trending_down, size: 16, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text('Cupo disponible:', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                              Text(_formatCurrency(available, card.currency), 
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (creditCards.indexOf(card) < creditCards.length - 1)
                      Divider(height: 16, indent: 8, endIndent: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      locale: 'es_CO',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 0,
    );
    return format.format(amount);
  }

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
