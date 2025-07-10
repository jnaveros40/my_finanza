// dashboard_credit_card_unified.dart
// Widget unificado que combina el resumen gráfico y los detalles de tarjetas de crédito

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:intl/intl.dart';

class DashboardCreditCardUnified extends StatelessWidget {
  final List<Account> accounts;
  final String displayCurrency;

  const DashboardCreditCardUnified({
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

    // Calcular totales
    final totalCreditLimit = creditCards.fold(0.0, (sum, card) => sum + card.creditLimit);
    final totalStatementBalance = creditCards.fold(0.0, (sum, card) => sum + card.currentStatementBalance);
    final totalAvailableCredit = totalCreditLimit - totalStatementBalance;
    final totalUsed = creditCards.fold(0.0, (sum, card) => sum + (card.creditLimit - card.currentBalance));
    final totalAvailable = creditCards.fold(0.0, (sum, card) => sum + card.currentBalance);

    if (creditCards.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
          title: Text('Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),
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
                      'Agrega tus tarjetas de crédito para visualizar el resumen de cupos y hacer seguimiento detallado.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        leading: Icon(
          Icons.credit_card, 
          color: totalStatementBalance > totalCreditLimit * 0.8 ? Colors.red : Theme.of(context).colorScheme.primary
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text('Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${creditCards.length} tarjeta${creditCards.length != 1 ? 's' : ''} registrada${creditCards.length != 1 ? 's' : ''}', 
                style: Theme.of(context).textTheme.bodyMedium
              ),
              SizedBox(height: 2),
              Column(
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
                      SizedBox(width: 8),
                      // PORCENTAJE DE USO AGREGADO
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getUsageColor(totalUsed / totalCreditLimit).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getUsageColor(totalUsed / totalCreditLimit).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${((totalUsed / totalCreditLimit) * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getUsageColor(totalUsed / totalCreditLimit),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),                        ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de resumen gráfico
                _buildGraphSection(context, totalCreditLimit, totalStatementBalance, totalAvailableCredit),
                
                SizedBox(height: 24),
                
                // Sección de detalles individuales
                _buildDetailsSection(context, creditCards),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection(BuildContext context, double totalCreditLimit, double totalStatementBalance, double totalAvailableCredit) {
    // Preparar datos para el gráfico de pastel
    final List<PieChartSectionData> sections = [];

    // Añadir sección para "Adeudado" si es mayor a 0
    if (totalStatementBalance > 0) {
      final percentageAdeudado = (totalStatementBalance / totalCreditLimit) * 100;
      sections.add(
        PieChartSectionData(
          color: Colors.redAccent,
          value: totalStatementBalance,
          title: '${percentageAdeudado.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Añadir sección para "Cupo Disponible" si es mayor a 0
    if (totalAvailableCredit > 0) {
      final percentageDisponible = (totalAvailableCredit / totalCreditLimit) * 100;
      sections.add(
        PieChartSectionData(
          color: const Color.fromARGB(255, 16, 172, 96),
          value: totalAvailableCredit,
          title: '${percentageDisponible.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Si no hay datos para el gráfico
    if (sections.isEmpty || totalCreditLimit <= 0) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Configura los cupos de tus tarjetas de crédito para ver el resumen gráfico.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del resumen gráfico
        Row(
          children: [
            Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('Uso de Cupos', style: Theme.of(context).textTheme.titleMedium),
            Spacer(),
            Tooltip(
              message: 'Distribución del uso de cupos de tus tarjetas de crédito',
              child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Summary metrics
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 8),
                  Text('Cupo Total:', style: Theme.of(context).textTheme.bodyMedium),
                  Spacer(),
                  Text(
                    _formatCurrency(totalCreditLimit, displayCurrency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cupo Utilizado:', style: Theme.of(context).textTheme.bodyMedium),
                  Spacer(),
                  Text(
                    _formatCurrency(totalStatementBalance, displayCurrency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.trending_down, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Cupo Disponible:', style: Theme.of(context).textTheme.bodyMedium),
                  Spacer(),
                  Text(
                    _formatCurrency(totalAvailableCredit, displayCurrency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Pie chart
        AspectRatio(
          aspectRatio: 1.5,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
            ),
          ),
        ),
        SizedBox(height: 16),
        /*
        // Legend
        Row(
          children: [
            Icon(Icons.legend_toggle, color: Theme.of(context).colorScheme.secondary, size: 20),
            SizedBox(width: 8),
            Text('Leyenda', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        SizedBox(height: 8),
        Column(
          children: [
            if (totalStatementBalance > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: Colors.redAccent,
                      margin: EdgeInsets.only(right: 8),
                    ),
                    Text(
                      'Cupo Utilizado: ${_formatCurrency(totalStatementBalance, displayCurrency)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (totalAvailableCredit > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: const Color.fromARGB(255, 16, 172, 96),
                      margin: EdgeInsets.only(right: 8),
                    ),
                    Text(
                      'Cupo Disponible: ${_formatCurrency(totalAvailableCredit, displayCurrency)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),*/
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, List<Account> creditCards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de detalles
        Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.secondary),
            SizedBox(width: 8),
            Text('Detalle de Tarjetas', style: Theme.of(context).textTheme.titleMedium),
            Spacer(),
            Tooltip(
              message: 'Información detallada de cada tarjeta de crédito',
              child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Lista de tarjetas
        ...creditCards.map((card) {
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
                      child: Text(
                        card.name, 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                      ),
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
                        Text(
                          '${usagePercentage.toStringAsFixed(1)}%', 
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
                        Text(
                          _formatCurrency(used, card.currency), 
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: Colors.red
                          )
                        ),
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
                        Text(
                          _formatCurrency(available, card.currency), 
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: Colors.green
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (creditCards.indexOf(card) < creditCards.length - 1)
                Divider(height: 16, indent: 8, endIndent: 8),
            ],
          );
        }),
      ],
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
  Color _getUsageColor(double usagePercentage) {
    if (usagePercentage < 0.2) {
      return Colors.green; // Uso bajo (0-20%)
    } else if (usagePercentage < 0.6) {
      return Colors.orange; // Uso medio (20-60%)
    } else {
      return Colors.red; // Uso alto (60-100%)
    }
  }
}
