// lib/screens/dashboard/widgets/dashboard_recent_transactions_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:intl/intl.dart';

class DashboardRecentTransactionsWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Movement> movements;
  final List<Category> categories;

  const DashboardRecentTransactionsWidget({
    super.key,
    required this.accounts,
    required this.movements,
    required this.categories,
  });

  @override
  _DashboardRecentTransactionsWidgetState createState() => _DashboardRecentTransactionsWidgetState();
}

class _DashboardRecentTransactionsWidgetState extends State<DashboardRecentTransactionsWidget> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _selectedFilter = 'all'; // all, income, expense, transfer
  int _transactionLimit = 10;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    final recentTransactions = _getRecentTransactions();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: Colors.blue,
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Transacciones Recientes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: Colors.blue,
            ),
            SizedBox(width: 4),
            Text(
              '${recentTransactions.length} transacciones',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'últimos 30 días',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFiltersAndControls(),
                SizedBox(height: 16),
                _buildTransactionsList(recentTransactions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndControls() {
    return Column(
      children: [
        // Filtros de tipo
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFilterButton('all', 'Todas'),
              _buildFilterButton('income', 'Ingresos'),
              _buildFilterButton('expense', 'Gastos'),
              _buildFilterButton('transfer', 'Transferencias'),
            ],
          ),
        ),
        SizedBox(height: 12),
        // Control de cantidad
        Row(
          children: [
            Text(
              'Mostrar:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(width: 12),
            DropdownButton<int>(
              value: _transactionLimit,
              underline: Container(),
              items: [5, 10, 15, 20].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value transacciones'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _transactionLimit = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionItem> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 12),
            Text(
              'No hay transacciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Las transacciones aparecerán aquí',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: transactions.map((transaction) => _buildTransactionCard(transaction)).toList(),
    );
  }

  Widget _buildTransactionCard(TransactionItem transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            width: 4,
            color: _getTransactionColor(transaction.type),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icono de la transacción
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTransactionColor(transaction.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransactionIcon(transaction.type),
              color: _getTransactionColor(transaction.type),
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          // Información de la transacción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${transaction.type == 'expense' ? '-' : '+'}${_formatCurrency(transaction.amount)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getTransactionColor(transaction.type),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    SizedBox(width: 4),
                    Text(
                      transaction.accountName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (transaction.categoryName != null) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.label_rounded,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      SizedBox(width: 4),
                      Text(
                        transaction.categoryName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                    Spacer(),
                    Text(
                      DateFormat('MMM dd', 'es').format(transaction.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionItem> _getRecentTransactions() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));
    
    // Filtrar movimientos de los últimos 30 días
    var filteredMovements = widget.movements.where((movement) =>
        movement.dateTime.isAfter(thirtyDaysAgo)).toList();
    
    // Aplicar filtro de tipo
    if (_selectedFilter != 'all') {
      filteredMovements = filteredMovements.where((movement) =>
          movement.type == _selectedFilter).toList();
    }
    
    // Ordenar por fecha (más recientes primero)
    filteredMovements.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    // Limitar cantidad
    filteredMovements = filteredMovements.take(_transactionLimit).toList();
    
    // Convertir a TransactionItem
    return filteredMovements.map((movement) {
      final account = widget.accounts.firstWhere(
        (a) => a.id == movement.accountId,
        orElse: () => Account(
          userId: '',
          name: 'Cuenta desconocida',
          type: 'unknown',
          currency: 'COP',
          initialBalance: 0,
          currentBalance: 0,
          order: 0,
        ),
      );
        final category = widget.categories.firstWhere(
        (c) => c.id == movement.categoryId,
        orElse: () => Category(
          userId: '',
          name: 'Sin categoría',
          type: movement.type,
        ),
      );
      
      return TransactionItem(
        id: movement.id ?? '',
        description: movement.description,
        amount: movement.amount,
        type: movement.type,
        date: movement.dateTime,
        accountName: account.name,
        categoryName: category.name,
      );
    }).toList();
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      case 'payment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward_rounded;
      case 'expense':
        return Icons.arrow_upward_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'payment':
        return Icons.payment_rounded;
      default:
        return Icons.receipt_rounded;
    }
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
}

// Clase auxiliar
class TransactionItem {
  final String id;
  final String description;
  final double amount;
  final String type;
  final DateTime date;
  final String accountName;
  final String? categoryName;

  TransactionItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.accountName,
    this.categoryName,
  });
}
