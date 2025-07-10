// lib/screens/debts/debts_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/debt.dart'; // Importar el modelo Debt
import 'package:mis_finanza/services/firestore_service/index.dart';
import 'utils/debt_progress_calculator.dart'; // Importar utilidad de cálculo
import 'package:intl/intl.dart'; // Para formatear fechas y moneda
// Importar pantalla para añadir/editar deudas
import 'package:mis_finanza/screens/debts/add_edit_debt_screen.dart';
// Importar el diálogo para añadir pagos de deuda
import 'package:mis_finanza/screens/debts/widgets/add_debt_payment_dialog.dart';
// Importar la pantalla para ver historial de pagos
import 'package:mis_finanza/screens/debts/debt_payment_history_screen.dart';


class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  _DebtsScreenState createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Helper para obtener el texto a mostrar para el tipo de deuda
  String _getDebtTypeText(String type) {
      switch (type) {
          case 'loan': return 'Préstamo';
          case 'credit_card_debt': return 'Deuda Tarjeta Crédito';
          case 'other': return 'Otra';
          default: return type;
      }
  }

   // Helper para obtener el texto a mostrar para el estado de la deuda
  String _getDebtStatusText(String status) {
      switch (status) {
          case 'active': return 'Activa';
          case 'paid': return 'Pagada';
          case 'defaulted': return 'Incumplida';
          default: return status;
      }
  }

   // Helper para obtener el símbolo de moneda (reutilizado de MovementsScreen)
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

    // Helper para formatear moneda (reutilizado de AddEditDebtScreen)
   String _formatCurrency(double amount, String currencyCode) {
     final format = NumberFormat.currency(
       locale: 'en_US', // Puedes ajustar la localización si es necesario
       symbol: _getCurrencySymbol(currencyCode),
       decimalDigits: 2, // Mostrar 2 decimales
     );
     return format.format(amount);
   }   // --- Función para calcular el total pagado ---
   double _calculateTotalPaid(List<Map<String, dynamic>>? paymentHistory) {
       if (paymentHistory == null || paymentHistory.isEmpty) {
           return 0.0;
       }
       double total = 0.0;
       //('DEBUG: _calculateTotalPaid - Processing payment history:');
       for (var payment in paymentHistory) {
           final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
           final paymentType = payment['paymentType'] as String? ?? 'normal';
           final date = payment['date'];
           //('  Payment: type=$paymentType, amount=$amount, date=$date');
           total += amount;
       }
       //('  Total paid: $total');
       return total;
   }

   // --- Función para calcular el total pagado de capital ---
   double _calculateTotalCapitalPaid(List<Map<String, dynamic>>? paymentHistory) {
       if (paymentHistory == null || paymentHistory.isEmpty) {
           return 0.0;
       }
       return paymentHistory.fold(0.0, (sum, payment) {
           final capitalAmount = (payment['capital_paid'] as num?)?.toDouble() ?? 0.0;
           return sum + capitalAmount;
       });
   }

   // --- Función para calcular el total pagado de intereses ---
   double _calculateTotalInterestPaid(List<Map<String, dynamic>>? paymentHistory) {
       if (paymentHistory == null || paymentHistory.isEmpty) {
           return 0.0;
       }
       return paymentHistory.fold(0.0, (sum, payment) {
           final interestAmount = (payment['interest_paid'] as num?)?.toDouble() ?? 0.0;
           return sum + interestAmount;
       });
   }

   // --- Función para calcular el total pagado de seguros ---
   double _calculateTotalInsurancePaid(List<Map<String, dynamic>>? paymentHistory) {
       if (paymentHistory == null || paymentHistory.isEmpty) {
           return 0.0;
       }
       return paymentHistory.fold(0.0, (sum, payment) {
           final insuranceAmount = (payment['insurance_paid'] as num?)?.toDouble() ?? 0.0;
           return sum + insuranceAmount;
       });
   }   // --- Función para calcular el número de cuotas normales pagadas ---
   int _calculatePaidInstallments(List<Map<String, dynamic>>? paymentHistory) {
       if (paymentHistory == null || paymentHistory.isEmpty) {
           return 0;
       }
       int normalPayments = 0;
       //('DEBUG: DEBTS _calculatePaidInstallments - Processing payment history:');
       for (var payment in paymentHistory) {
         final paymentType = payment['paymentType'] as String? ?? 'normal';
         final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
         final date = payment['date'];
         //('  Payment: type=$paymentType, amount=$amount, date=$date');
         if (paymentType == 'normal') {
           normalPayments++;
         }
       }
       //('  Normal payments count: $normalPayments');
       return normalPayments;
   }

   // --- Función para confirmar y eliminar deuda ---
   Future<bool> _confirmAndDeleteDebt(BuildContext context, Debt debt) async {
       bool confirm = await showDialog(
         context: context,
         builder: (BuildContext context) {
           return AlertDialog(
             title: Text('Confirmar Eliminación'),
             content: Text('¿Estás seguro de que deseas eliminar la deuda "${debt.description}"?'),
             actions: <Widget>[
               TextButton(
                 onPressed: () => Navigator.of(context).pop(false),
                 child: Text('Cancelar'),
               ),
               TextButton(
                 onPressed: () => Navigator.of(context).pop(true),
                 // Usar el color de error del tema para la acción destructiva
                 child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
               ),
             ],
           );
         },
       ) ?? false;

       if (confirm) {
         try {
           if (debt.id != null) {
             // Llama al servicio para eliminar la deuda
             await DebtService.deleteDebt(debt.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deuda "${debt.description}" eliminada.')),
              );
              return true;
           } else {
              ////('Error: Intentando eliminar deuda sin ID.');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: No se pudo obtener el ID de la deuda para eliminar.')),
              );
              return false;
           }
         } catch (e) {
            ////('Error al eliminar deuda: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar la deuda: ${e.toString()}')),
            );
            return false;
         }
       }
       return false;
   }

    // --- Función para mostrar el diálogo de añadir pago ---
    void _showAddPaymentDialog(BuildContext context, Debt debt) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
                return AddDebtPaymentDialog(debt: debt); // Pasa la deuda al diálogo
            },
        );
    }    // --- Función para mostrar el diálogo de historial de pagos ---
    void _showPaymentHistoryDialog(BuildContext context, Debt debt) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DebtPaymentHistoryScreen(debt: debt),
            ),
        );
    }


  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(child: Text('Por favor, inicia sesión para ver tus deudas.'));
    }

    return
      // Eliminamos el Scaffold de aquí ya que MainAppScreen proporciona uno
      // Scaffold(
      // appBar: AppBar(
      //   title: const Text('Mis Deudas'), // Título de la pantalla
      // ),
      // body:
      StreamBuilder<List<Debt>>(
        stream: DebtService.getDebts(), // Obtener el stream de deudas
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             ////('Error cargando deudas: ${snapshot.error}');
            return Center(child: Text('Error al cargar las deudas: ${snapshot.error}'));
          }
           if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tienes deudas registradas aún.'));
          }

          final debts = snapshot.data!; // Lista de Debt

          // Construir la lista de deudas
          return ListView.builder(
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index]; // Cada elemento es una Debt              // Calcular total pagado y porcentaje
               final totalPaid = _calculateTotalPaid(debt.paymentHistory);               // Calcular desglose de pagos
               final totalCapitalPaid = _calculateTotalCapitalPaid(debt.paymentHistory);
               final totalInterestPaid = _calculateTotalInterestPaid(debt.paymentHistory);
               final totalInsurancePaid = _calculateTotalInsurancePaid(debt.paymentHistory);
                 // Calcular cuotas pagadas
               final paidInstallments = _calculatePaidInstallments(debt.paymentHistory);
               final totalInstallments = debt.totalInstallments ?? 0;
                 // Usar el currentAmount que ya está correctamente mantenido por el servicio
               // (reduce solo por capital, no por total de pagos)
               final remainingAmount = debt.currentAmount;               // Usar el utility unificado para calcular el progreso
               final percentagePaid = calculateDebtProgress(
                 paidInstallments: paidInstallments,
                 totalInstallments: totalInstallments,
                 initialAmount: debt.initialAmount,
                 currentAmount: debt.currentAmount,
               );

               // DEBUG: // calculation details
               final calculationMethod = getProgressCalculationMethod(totalInstallments);
               //print('=== DEBTS SCREEN PROGRESS DEBUG (${debt.description}) ===');
               //('totalPaid: $totalPaid');
               //('initialAmount: ${debt.initialAmount}');
               //('currentAmount: ${debt.currentAmount}');
               //('totalInstallments: $totalInstallments');
               //('paidInstallments: $paidInstallments');
               //('Calculation method: $calculationMethod');
               //('Progress: $percentagePaid%');
               //('Old method would have been: ($totalPaid / ${debt.initialAmount}) * 100 = ${debt.initialAmount > 0 ? (totalPaid / debt.initialAmount) * 100 : 0.0}%');
               //('===============================================');

               // Formatear montos con símbolo de moneda
               String formattedInitialAmount = _formatCurrency(debt.initialAmount, debt.currency);
               String formattedRemainingAmount = _formatCurrency(remainingAmount, debt.currency);
               String formattedTotalPaid = _formatCurrency(totalPaid, debt.currency);               // Formatear desglose de pagos
               String formattedTotalCapitalPaid = _formatCurrency(totalCapitalPaid, debt.currency);
               String formattedTotalInterestPaid = _formatCurrency(totalInterestPaid, debt.currency);
               String formattedTotalInsurancePaid = _formatCurrency(totalInsurancePaid, debt.currency);

               // Formatear tasa de interés si existe
               String? formattedInterestRate;
               if (debt.annualEffectiveInterestRate != null) {
                 formattedInterestRate = '${(debt.annualEffectiveInterestRate! * 100).toStringAsFixed(2)}%'; // Formato porcentaje correcto
               }

               // Formatear valor de cuota (puede ser el calculado o ingresado)
               String? formattedInstallmentValue;
               if (debt.installmentValue != null) {
                  formattedInstallmentValue = _formatCurrency(debt.installmentValue!, debt.currency);
               }

                // Formatear total de intereses calculado (NUEVO)
               String? formattedTotalCalculatedInterest;
               if (debt.totalCalculatedInterest != null) {
                  formattedTotalCalculatedInterest = _formatCurrency(debt.totalCalculatedInterest!, debt.currency);
               }


               // Formatear fecha de vencimiento si existe
               String? formattedDueDate;
               if (debt.dueDate != null) {
                 formattedDueDate = DateFormat('yyyy-MM-dd').format(debt.dueDate!);
               }


              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 1.5,
                  borderRadius: BorderRadius.circular(20),
                  child: Dismissible(
                    key: Key(debt.id!),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await _confirmAndDeleteDebt(context, debt);
                    },
                    onDismissed: (direction) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deuda "${debt.description}" deslizada para eliminar.')),
                      );
                    },
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddEditDebtScreen(debt: debt)),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(Icons.account_balance_wallet_rounded, color: Theme.of(context).colorScheme.primary),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        debt.description,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text('Monto Inicial: $formattedInitialAmount', style: Theme.of(context).textTheme.bodyMedium),
                                      Text('Monto Restante: $formattedRemainingAmount', style: Theme.of(context).textTheme.bodyMedium),                                      Text('Total Pagado: $formattedTotalPaid', style: Theme.of(context).textTheme.bodyMedium),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.trending_up, color: Colors.green[600], size: 18),
                                                SizedBox(width: 4),
                                                Text('Capital: $formattedTotalCapitalPaid', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green[700])),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.percent, color: Colors.orange[600], size: 18),
                                                SizedBox(width: 4),
                                                Text('Intereses: $formattedTotalInterestPaid', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange[700])),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.shield, color: Colors.blue[600], size: 18),
                                                SizedBox(width: 4),
                                                Text('Seguros: $formattedTotalInsurancePaid', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue[700])),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (formattedInterestRate != null)
                                        Text('Tasa Interés Anual: $formattedInterestRate', style: Theme.of(context).textTheme.bodyMedium),
                                      if (formattedInstallmentValue != null)
                                        Text('Valor Cuota: $formattedInstallmentValue', style: Theme.of(context).textTheme.bodyMedium),
                                      if (formattedTotalCalculatedInterest != null)
                                        Text('Total Intereses Calculado: $formattedTotalCalculatedInterest', style: Theme.of(context).textTheme.bodyMedium),
                                      SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: percentagePaid / 100,
                                          minHeight: 8,
                                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text('Progreso: ${percentagePaid.toStringAsFixed(2)}%', style: Theme.of(context).textTheme.bodyMedium),
                                      if (totalInstallments > 0)
                                        Text('Cuotas: $paidInstallments / $totalInstallments', style: Theme.of(context).textTheme.bodyMedium),
                                      if (debt.creditorDebtor != null && debt.creditorDebtor!.isNotEmpty)
                                        Text('Con: ${debt.creditorDebtor}', style: Theme.of(context).textTheme.bodyMedium),
                                      Text('Tipo: ${_getDebtTypeText(debt.type)}', style: Theme.of(context).textTheme.bodyMedium),
                                      Text('Estado: ${_getDebtStatusText(debt.status)}', style: Theme.of(context).textTheme.bodyMedium),
                                      Text('Fecha Creación: ${DateFormat('yyyy-MM-dd').format(debt.creationDate)}', style: Theme.of(context).textTheme.bodyMedium),
                                      if (formattedDueDate != null)
                                        Text('Fecha Vencimiento: $formattedDueDate', style: Theme.of(context).textTheme.bodyMedium),
                                      if (debt.notes != null && debt.notes!.isNotEmpty)
                                        Text('Notas: ${debt.notes}', style: Theme.of(context).textTheme.bodyMedium),
                                      if (debt.paymentDay != null && debt.paymentDay! >= 1 && debt.paymentDay! <= 30)
                                        Text('Próxima fecha de pago: ${_getNextPaymentDateString(debt.paymentDay!)}', style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.history, color: Theme.of(context).colorScheme.secondary),
                                  tooltip: 'Ver Historial de Pagos',
                                  onPressed: () {
                                    _showPaymentHistoryDialog(context, debt);
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
                                  tooltip: 'Registrar Pago',
                                  onPressed: () {
                                    _showAddPaymentDialog(context, debt);
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
                                  tooltip: 'Editar Deuda',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AddEditDebtScreen(debt: debt)),
                                    );
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
      // FloatingActionButton para añadir nueva deuda (ya configurado en MainAppScreen)
      // Este FAB está en MainAppScreen y navega a AddEditDebtScreen sin parámetros.
    // ); // Eliminamos el cierre del Scaffold
  }

  // --- Helper para calcular la próxima fecha de pago a partir del día ---
  String _getNextPaymentDateString(int paymentDay) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    // Si hoy ya pasó el día de pago, ir al mes siguiente
    if (now.day > paymentDay) {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
    }
    // Ajustar el día si el mes tiene menos de 30 días
    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    int day = paymentDay <= lastDayOfMonth ? paymentDay : lastDayOfMonth;
    final nextDate = DateTime(year, month, day);
    return DateFormat('yyyy-MM-dd').format(nextDate);
  }
}
