// dashboard_savings_account_chart.dart
// Componente modular para mostrar el gráfico de distribución de cuentas de ahorro

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:intl/intl.dart';

class DashboardSavingsAccountChart extends StatelessWidget {
  final List<Account> accounts;

  const DashboardSavingsAccountChart({
    super.key,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar solo las cuentas de ahorro
    final savingsAccounts = accounts.where((account) => account.type == 'Cuenta de ahorro').toList();    // Si no hay cuentas de ahorro, mostrar un mensaje
    if (savingsAccounts.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.savings, color: Theme.of(context).colorScheme.primary),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text('Distribución de Cuentas de Ahorro', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '0 cuentas de ahorro',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No hay cuentas registradas',
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
                      'Agrega cuentas de ahorro para visualizar la distribución de tus ahorros.',
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

    // Calcular el saldo total de las cuentas de ahorro
    double totalSavingsBalance = savingsAccounts.fold(0.0, (sum, account) => sum + account.currentBalance);    // Si el saldo total es cero, no hay nada que mostrar en el gráfico
    if (totalSavingsBalance <= 0) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.savings, color: Theme.of(context).colorScheme.primary),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text('Distribución de Cuentas de Ahorro', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${savingsAccounts.length} cuenta${savingsAccounts.length != 1 ? 's' : ''} de ahorro',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Saldo total: \$0',
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
                      'El saldo total de las cuentas de ahorro es cero. Agrega fondos para ver la distribución.',
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

    // Definir el umbral del 5%
    final double thresholdPercentage = 5.0;
    final double thresholdAmount = totalSavingsBalance * (thresholdPercentage / 100.0);

    // Listas para cuentas por encima y por debajo del umbral
    final List<Account> accountsAboveThreshold = [];
    final List<Account> accountsBelowThreshold = [];
    double otherAccountsTotal = 0.0;

    // Clasificar cuentas y sumar las que están por debajo del umbral
    for (var account in savingsAccounts) {
      if (account.currentBalance >= thresholdAmount) {
        accountsAboveThreshold.add(account);
      } else {
        accountsBelowThreshold.add(account);
        otherAccountsTotal += account.currentBalance;
      }
    }

    // Ordenar las cuentas por encima del umbral por saldo descendente
    accountsAboveThreshold.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));

    // Preparar datos para el gráfico de pastel
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blueAccent,
      const Color.fromARGB(255, 0, 139, 19),
      Colors.orangeAccent,
      Colors.purpleAccent,
      const Color.fromARGB(255, 1, 81, 253),
      Colors.brown,
      Colors.indigoAccent,
      Colors.limeAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
    ];
    int colorIndex = 0;

    // Añadir secciones para las cuentas individuales por encima del umbral
    for (var account in accountsAboveThreshold) {
      final percentage = (account.currentBalance / totalSavingsBalance) * 100;
      final sectionColor = colors[colorIndex % colors.length];
      colorIndex++;

      sections.add(
        PieChartSectionData(
          color: sectionColor,
          value: account.currentBalance, // Usar el saldo como valor
          title: '${percentage.toStringAsFixed(1)}%', // Mostrar porcentaje
          radius: 80, // Radio de la sección
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff), // Texto blanco
          ),
        ),
      );
    }

    // Añadir sección para "Otros" si hay cuentas por debajo del umbral
    if (otherAccountsTotal > 0) {
      final percentageOtros = (otherAccountsTotal / totalSavingsBalance) * 100;
      // Asignar siempre Colors.black a la sección "Otros"
      const otherSectionColor = Colors.black;

      sections.add(
        PieChartSectionData(
          color: otherSectionColor, // Color para "Otros"
          value: otherAccountsTotal, // Usar el total de las cuentas pequeñas
          // Mostrar el porcentaje de "Otros"
          title: '${percentageOtros.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff), // Texto blanco
          ),
        ),
      );
    }    // Si después de filtrar saldos cero y agrupar no quedan secciones, mostrar mensaje
    if (sections.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        child: ExpansionTile(
          leading: Icon(Icons.savings, color: Theme.of(context).colorScheme.primary),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text('Distribución de Cuentas de Ahorro', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${savingsAccounts.length} cuenta${savingsAccounts.length != 1 ? 's' : ''} de ahorro',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sin saldo positivo para mostrar',
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
                      'No hay cuentas de ahorro con saldo positivo para mostrar en el gráfico.',
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

    // DEBUG: Imprimir cuentas de ahorro y sus saldos
    // print('DEBUG - savingsAccounts:');
    // for (var acc in savingsAccounts) {
    //   print('   {acc.name} - saldo:  {acc.currentBalance}');
    // }
    // print('DEBUG - thresholdAmount: $thresholdAmount');
    // print('DEBUG - accountsAboveThreshold:');
    // for (var acc in accountsAboveThreshold) {
    //   print('   {acc.name} - saldo:  {acc.currentBalance}');
    // }
    // print('DEBUG - accountsBelowThreshold:');
    // for (var acc in accountsBelowThreshold) {
    //   print('   {acc.name} - saldo:  {acc.currentBalance}');
    // }
    // print('DEBUG - otherAccountsTotal: $otherAccountsTotal');
    // print('DEBUG - sections: ${sections.length}');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 4.0,
      child: ExpansionTile(
        leading: Icon(Icons.savings, color: Colors.green),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text('Distribución de Cuentas de Ahorro', style: Theme.of(context).textTheme.titleLarge),        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${savingsAccounts.length} cuenta${savingsAccounts.length != 1 ? 's' : ''} de ahorro',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Total: ${_formatCurrency(totalSavingsBalance, 'COP')}',
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
                Icon(Icons.pie_chart, color: Colors.green),
                SizedBox(width: 8),
                Text('Distribución de Ahorros', style: Theme.of(context).textTheme.titleMedium),
                Spacer(),
                Tooltip(
                  message: 'Distribución porcentual de tus cuentas de ahorro',
                  child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
          // Total amount display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Total en Ahorros: ${_formatCurrency(totalSavingsBalance, 'COP')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
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
                AspectRatio(
                  aspectRatio: 1.1,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 55,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Leyenda del gráfico de cuentas de ahorro
                _buildSavingsAccountChartLegend(accountsAboveThreshold, otherAccountsTotal, 'COP'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Leyenda para el Gráfico de Pastel de Cuentas de Ahorro con "Otros"
  Widget _buildSavingsAccountChartLegend(List<Account> accountsAboveThreshold, double otherAccountsTotal, String currencyCode) {
    // Los colores deben coincidir con los usados en el gráfico principal
    final List<Color> colors = [
      Colors.blueAccent,
      const Color.fromARGB(255, 0, 139, 19),
      Colors.orangeAccent,
      Colors.purpleAccent,
      const Color.fromARGB(255, 1, 81, 253),
      Colors.brown,
      Colors.indigoAccent,
      Colors.limeAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
    ];
    int colorIndex = 0;

    List<Widget> legendItems = [];

    // Añadir elementos de leyenda para las cuentas individuales por encima del umbral
    for (var account in accountsAboveThreshold) {
      // Filtrar cuentas con saldo > 0 para la leyenda
      if (account.currentBalance > 0) {
        final legendColor = colors[colorIndex % colors.length];
        colorIndex++;

        legendItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: legendColor,
                  margin: EdgeInsets.only(right: 8),
                ),
                Expanded(
                  child: Text(
                    '${account.name}: ${_formatCurrency(account.currentBalance, account.currency)}',
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Añadir elemento de leyenda para "Otros" si hay cuentas por debajo del umbral
    if (otherAccountsTotal > 0) {
      // Asignar siempre Colors.black a la leyenda "Otros"
      const otherLegendColor = Colors.black;

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: otherLegendColor,
                margin: EdgeInsets.only(right: 8),
              ),
              Expanded(
                child: Text(
                  'Cuentas menores: ${_formatCurrency(otherAccountsTotal, currencyCode)}',
                  style: TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: legendItems,
    );
  }

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
