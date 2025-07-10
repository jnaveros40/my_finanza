// lib/screens/account_movements_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/account.dart';
import '../../models/movement.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart'; // Para formatear fechas y moneda
//import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp
// Importar la pantalla para editar la cuenta
import 'package:mis_finanza/screens/accounts/edit_account_screen.dart';
// Importar la pantalla para añadir/editar movimientos (si quieres añadir movimientos desde aquí)
// import 'package:mis_finanza/screens/add_edit_movement_screen.dart'; // Asumiendo que tienes una pantalla así
//import 'package:mis_finanza/screens/movements/add_movement_screen.dart';
// --- Importar la pantalla de edición de movimientos ---
import 'package:mis_finanza/screens/movements/edit_movement_screen.dart';
// -----------------------------------------------------


class AccountMovementsScreen extends StatefulWidget {
  final Account account; // Recibe la cuenta cuyos movimientos se mostrarán

  const AccountMovementsScreen({super.key, required this.account});

  @override
  _AccountMovementsScreenState createState() => _AccountMovementsScreenState();
}

class _AccountMovementsScreenState extends State<AccountMovementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Helper methods for modern UI
  IconData _getAccountTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cuenta de ahorro':
        return Icons.savings;
      case 'tarjeta de credito':
        return Icons.credit_card;
      //case 'renta fija':
        //return Icons.trending_up;
      case 'renta variable':
        return Icons.show_chart;
      case 'efectivo':
        return Icons.account_balance_wallet;
      case 'inversiones':
        return Icons.business_center;
      case 'deuda':
        return Icons.money_off;
      default:
        return Icons.account_balance;
    }
  }

  Color _getAccountTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cuenta de ahorro':
        return Colors.green;
      case 'tarjeta de credito':
        return Colors.blue;
      case 'renta fija':
        return Colors.teal;
      case 'renta variable':
        return Colors.orange;
      case 'efectivo':
        return Colors.purple;
      case 'inversiones':
        return Colors.indigo;
      case 'deuda':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  Color _getMovementTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      case 'payment':
        return Colors.orange;
      case 'debt_payment':
        return Colors.purple;
      case 'investment':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  // Helper para obtener el símbolo de moneda (reutilizado)
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'COP': return '\$';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      default: return currencyCode;
    }
  }

  // Helper para formatear montos de moneda (reutilizado)
  String _formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      locale: 'es_CO', // O la localización que prefieras
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Helper para obtener el texto a mostrar para el tipo de movimiento
  String _getMovementTypeText(String type) {
    switch (type) {
      case 'income': return 'Ingreso';
      case 'expense': return 'Gasto';
      case 'transfer': return 'Transferencia';
      case 'payment': return 'Pago'; // <-- Añadido: Traducción para 'payment'
      case 'debt_payment': return 'Pago de Deuda';
      case 'investment': return 'Inversión'; // Si los movimientos de inversión se registran aquí
      default: return type;
    }
  }
  // --- Enhanced widget para mostrar el resumen del saldo de la cuenta ---
  Widget _buildAccountSummary(Account account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Account header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getAccountTypeColor(account.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAccountTypeIcon(account.type),
                  size: 28,
                  color: _getAccountTypeColor(account.type),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAccountTypeColor(account.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getAccountTypeColor(account.type).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        account.type,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getAccountTypeColor(account.type),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Balance information
          if (account.isCreditCard) ...[
            // Credit card balances
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Adeudado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(account.currentStatementBalance, account.currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Disponible',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(account.currentBalance, account.currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Regular account balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.savings,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Saldo Actual',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(account.currentBalance, account.currency),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }  // Enhanced UI helper methods
  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando movimientos...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 40,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin movimientos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay movimientos registrados para esta cuenta.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList(List<Movement> movements) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: movements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final movement = movements[index];
        return _buildMovementTile(movement);
      },
    );
  }

  Widget _buildMovementTile(Movement movement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine colors and icons based on movement type
    Color amountColor;
    Color iconColor;
    IconData iconData;
    
    switch (movement.type) {
      case 'income':
        amountColor = Colors.green;
        iconColor = Colors.green;
        iconData = Icons.trending_up;
        break;
      case 'expense':
        amountColor = Colors.red;
        iconColor = Colors.red;
        iconData = Icons.trending_down;
        break;
      case 'transfer':
        if (movement.accountId == widget.account.id) {
          // Money going out
          amountColor = Colors.red;
          iconColor = Colors.orange;
          iconData = Icons.call_made;
        } else {
          // Money coming in
          amountColor = Colors.green;
          iconColor = Colors.blue;
          iconData = Icons.call_received;
        }
        break;
      case 'payment':
        amountColor = Colors.blue;
        iconColor = Colors.blue;
        iconData = Icons.payment;
        break;
      default:
        amountColor = colorScheme.onSurface;
        iconColor = colorScheme.secondary;
        iconData = Icons.sync;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            //print('Tapped on movement: ${movement.description}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditMovementScreen(movement: movement),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Movement details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getMovementTypeColor(movement.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getMovementTypeText(movement.type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getMovementTypeColor(movement.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(movement.dateTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (movement.notes != null && movement.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          movement.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(movement.amount, movement.currency),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withOpacity(0.4),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Acceso Requerido',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, inicia sesión para ver los movimientos de la cuenta.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Enhanced Scaffold with modern design
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movimientos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              widget.account.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.edit,
                color: colorScheme.primary,
              ),
              tooltip: 'Editar Cuenta',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAccountScreen(account: widget.account),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(// Usar Column para apilar el resumen y la lista de movimientos
        children: [
          // --- StreamBuilder para los detalles de la cuenta ---
          StreamBuilder<Account?>(            stream: _firestoreService.getAccountStreamById(widget.account.id!),
            builder: (context, accountSnapshot) {
              if (accountSnapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }
              if (accountSnapshot.hasError) {
                //print('Error cargando detalles de la cuenta: ${accountSnapshot.error}');
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error al cargar detalles de la cuenta: ${accountSnapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!accountSnapshot.hasData || accountSnapshot.data == null) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Cuenta no encontrada.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }              final updatedAccount = accountSnapshot.data!;
              return _buildAccountSummary(updatedAccount);
            },
          ),
          
          // Movements list section
          Expanded(
            child: StreamBuilder<List<Movement>>(
              stream: _firestoreService.getMovementsByAccountId(widget.account.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (snapshot.hasError) {
                  //print('Error cargando movimientos: ${snapshot.error}');
                  return _buildErrorState('Error al cargar los movimientos');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final movements = snapshot.data!;
                movements.sort((a, b) => b.dateTime.compareTo(a.dateTime));

                return _buildMovementsList(movements);
              },
            ),
          ),
        ],
      ),
    );
  }
}
*/