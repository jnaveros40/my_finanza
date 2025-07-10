// dashboard_credit_card_summary_chart.dart
// Componente modular para mostrar el gráfico de resumen de tarjetas de crédito

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:intl/intl.dart';

class DashboardCreditCardSummaryChart extends StatelessWidget {
  final List<Account> accounts;

  const DashboardCreditCardSummaryChart({
    super.key,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar solo las cuentas de tarjeta de crédito
    final creditCards = accounts.where((account) => account.isCreditCard).toList();    // Si no hay tarjetas de crédito, mostrar un mensaje
    if (creditCards.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text('Resumen de Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '0 tarjetas de crédito',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No hay tarjetas registradas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Agrega tarjetas de crédito para visualizar el resumen de cupos.',
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

    // Calcular el total del cupo de crédito y el total adeudado
    double totalCreditLimit = creditCards.fold(0.0, (sum, card) => sum + card.creditLimit);
    double totalStatementBalance = creditCards.fold(0.0, (sum, card) => sum + card.currentStatementBalance);

    // Calcular el cupo disponible total
    double totalAvailableCredit = totalCreditLimit - totalStatementBalance;    // Si el cupo total y el adeudado son cero, no hay nada que mostrar
    if (totalCreditLimit <= 0 && totalStatementBalance <= 0) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text('Resumen de Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${creditCards.length} tarjeta${creditCards.length != 1 ? 's' : ''} de crédito',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sin cupos o saldos registrados',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configura los cupos de tus tarjetas de crédito para ver el resumen.',
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

    // Preparar datos para el gráfico de pastel
    final List<PieChartSectionData> sections = [];
    final String displayCurrency = 'COP'; // Asumimos COP para la visualización total de CC

    // Añadir sección para "Adeudado" si es mayor a 0
    if (totalStatementBalance > 0) {
      final percentageAdeudado = (totalStatementBalance / totalCreditLimit) * 100;
      sections.add(
        PieChartSectionData(
          color: Colors.redAccent, // Color para el adeudado
          value: totalStatementBalance, // Usar el total adeudado como valor
          title: '${percentageAdeudado.toStringAsFixed(1)}%', // Mostrar porcentaje
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Texto blanco
          ),
        ),
      );
    }

    // Añadir sección para "Cupo Disponible" si es mayor a 0
    if (totalAvailableCredit > 0) {
      final percentageDisponible = (totalAvailableCredit / totalCreditLimit) * 100;
      sections.add(
        PieChartSectionData(
          color: const Color.fromARGB(255, 16, 172, 96), // Color para el cupo disponible
          value: totalAvailableCredit, // Usar el cupo disponible como valor
          title: '${percentageDisponible.toStringAsFixed(1)}%', // Mostrar porcentaje
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Texto blanco
          ),
        ),
      );
    }    // Si no hay secciones para mostrar (ej. totalCreditLimit es 0)
    if (sections.isEmpty && (totalCreditLimit > 0 || totalStatementBalance > 0)) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text('Resumen de Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('Datos insuficientes para el gráfico', style: Theme.of(context).textTheme.bodyMedium),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay datos suficientes para mostrar el gráfico de tarjetas de crédito.',
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
        leading: Icon(Icons.credit_card, color: totalStatementBalance > totalCreditLimit * 0.8 ? Colors.red : Colors.blue),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text('Resumen de Tarjetas de Crédito', style: Theme.of(context).textTheme.titleLarge),        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${creditCards.length} tarjeta${creditCards.length != 1 ? 's' : ''} de crédito',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Cupo total: ${_formatCurrency(totalCreditLimit, displayCurrency)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          // Header section with summary information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.shade300
                    : Colors.blue),
                SizedBox(width: 8),
                Text('Uso de Cupos', style: Theme.of(context).textTheme.titleMedium),
                Spacer(),
                Tooltip(
                  message: 'Distribución del uso de cupos de tus tarjetas de crédito',
                  child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary section with key metrics
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
                      SizedBox(height: 12),
                      // Cupo Utilizado - Organizado verticalmente
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_up, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Cupo Utilizado',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _formatCurrency(totalStatementBalance, displayCurrency),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${((totalStatementBalance / totalCreditLimit) * 100).toStringAsFixed(1)}% del cupo total',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      // Cupo Disponible - Organizado verticalmente
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_down, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Cupo Disponible',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _formatCurrency(totalAvailableCredit, displayCurrency),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${((totalAvailableCredit / totalCreditLimit) * 100).toStringAsFixed(1)}% del cupo total',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1.2, // Relación de aspecto para el gráfico
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 55, // Radio del centro
                    ),
                  ),
                ),
                SizedBox(height: 16),
                /*
                // Legend section
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
            ),
          ),
        ],
      ),
    );
  }
/*
  Widget _buildCreditCardChartLegend(double totalStatementBalance, double totalAvailableCredit, String currencyCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalStatementBalance > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.black,
                  margin: EdgeInsets.only(right: 8),
                ),
                Text(
                  'Cupo Utilizado: ${_formatCurrency(totalStatementBalance, currencyCode)}',
                ),
              ],
            ),
          ),
        if (totalAvailableCredit > 0)
          Padding(
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
                  'Cupo Disponible: ${_formatCurrency(totalAvailableCredit, currencyCode)}',
                ),
              ],
            ),
          ),
      ],
    );
  }
*/
  // Método para formatear valores monetarios
  String _formatCurrency(double amount, String currencyCode) {
    final formatCurrency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }
}