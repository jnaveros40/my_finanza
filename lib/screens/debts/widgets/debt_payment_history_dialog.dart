// lib/screens/debts/widgets/debt_payment_history_dialog.dart

import 'package:flutter/material.dart';
import 'package:mis_finanza/models/debt.dart'; // Importar el modelo Debt
import 'package:mis_finanza/services/firestore_service.dart'; // Importar el servicio
import 'package:intl/intl.dart'; // Para formatear fechas y moneda
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp
// Importar el diálogo para editar pagos
import 'package:mis_finanza/screens/debts/widgets/edit_debt_payment_dialog.dart';


class DebtPaymentHistoryDialog extends StatelessWidget {
  final Debt debt; // La deuda cuyo historial de pagos se mostrará

  const DebtPaymentHistoryDialog({super.key, required this.debt});

  // Helper para obtener el símbolo de moneda (reutilizado de otras pantallas)
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

   // Helper para obtener el texto a mostrar para el tipo de pago
  String _getPaymentTypeText(String type) {
      switch (type) {
          case 'normal': return 'Cuota Normal';
          case 'extra_term': return 'Abono a Capital (Reducir Plazo)';
          case 'extra_installment': return 'Abono a Capital (Reducir Cuota)';
          default: return type;
      }
  }

   // --- Función para confirmar y eliminar un pago específico ---
   Future<void> _confirmAndDeletePayment(BuildContext context, String debtId, int paymentIndex) async {
       bool confirm = await showDialog(
         context: context,
         builder: (BuildContext context) {
           return AlertDialog(
             title: Text('Confirmar Eliminación de Pago'),
             content: Text('¿Estás seguro de que deseas eliminar este pago?'),
             actions: <Widget>[
               TextButton(
                 onPressed: () => Navigator.of(context).pop(false),
                 child: Text('Cancelar'),
               ),
               TextButton(
                 onPressed: () => Navigator.of(context).pop(true),
                 child: Text('Eliminar', style: TextStyle(color: Colors.red)),
               ),
             ],
           );
         },
       ) ?? false;

       if (confirm) {
         try {
           // Llama al servicio para eliminar el pago específico
           await FirestoreService().deleteDebtPayment(debtId, paymentIndex);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pago eliminado con éxito.')),
            );
            // No cerramos el diálogo de historial aquí, ya que el StreamBuilder lo actualizará
         } catch (e) {
            print('Error al eliminar pago de deuda: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar el pago: ${e.toString()}')),
            );
         }
       }
   }


  @override
  Widget build(BuildContext context) {
    // Obtener el historial de pagos (puede ser null o vacío)
    final paymentHistory = debt.paymentHistory ?? [];

    // Ordenar el historial por fecha descendente (los pagos más recientes primero)
    // Crear una copia para no modificar la lista original de la deuda
    final sortedPaymentHistory = List<Map<String, dynamic>>.from(paymentHistory);
    sortedPaymentHistory.sort((a, b) {
      final dateA = (a['date'] as Timestamp).toDate();
      final dateB = (b['date'] as Timestamp).toDate();
      return dateB.compareTo(dateA); // Orden descendente
    });


    return AlertDialog(
      title: Text('Historial de Pagos: "${debt.description}"'), // Título con nombre de la deuda
      content: SizedBox(
        width: double.maxFinite, // Ocupar el ancho máximo disponible en el diálogo
        child: sortedPaymentHistory.isEmpty // Usar la lista ordenada
            ? Center(child: Text('No hay pagos registrados para esta deuda.'))
            : ListView.builder(
                shrinkWrap: true, // Ajustar la altura del ListView al contenido
                itemCount: sortedPaymentHistory.length,
                itemBuilder: (context, index) {
                  final payment = sortedPaymentHistory[index]; // Usar la lista ordenada
                  final paymentDate = (payment['date'] as Timestamp).toDate();
                  final paymentAmount = (payment['amount'] as num).toDouble();
                  final paymentNotes = payment['notes'] as String?;
                  final paymentType = payment['paymentType'] as String? ?? 'normal'; // Obtener el tipo de pago

                   // Formatear monto con símbolo de moneda
                   String formattedPaymentAmount = NumberFormat.currency(
                     locale: 'en_US', // Ajusta la localización si es necesario
                     symbol: _getCurrencySymbol(debt.currency), // Usar la moneda de la deuda
                     decimalDigits: 2,
                   ).format(paymentAmount);

                   // Encontrar el índice original del pago en la lista sin ordenar
                   // Esto es crucial para eliminar/editar el elemento correcto en Firestore
                   final originalIndex = paymentHistory.indexOf(payment);


                  return ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Colors.green), // Icono de pago exitoso
                    title: Text('Monto: $formattedPaymentAmount'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${DateFormat('yyyy-MM-dd').format(paymentDate)}'),
                        Text('Tipo: ${_getPaymentTypeText(paymentType)}'), // Mostrar tipo de pago
                        if (paymentNotes != null && paymentNotes.isNotEmpty)
                          Text('Notas: $paymentNotes'),
                      ],
                    ),
                    // Añadir trailing para acciones (Editar y Eliminar)
                    trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          // Botón/Icono para editar pago
                          IconButton(
                            icon: Icon(Icons.edit, size: 20), // Icono de edición
                            tooltip: 'Editar Pago',
                            onPressed: () {
                               // Mostrar el diálogo de edición de pago
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                        return EditDebtPaymentDialog(
                                            debt: debt, // Pasar la deuda completa
                                            paymentIndex: originalIndex, // Pasar el índice ORIGINAL del pago
                                        );
                                    },
                                );
                            },
                          ),
                           SizedBox(width: 4), // Espacio entre iconos
                          // Botón/Icono para eliminar pago
                           IconButton(
                             icon: Icon(Icons.delete, size: 20, color: Colors.redAccent), // Icono de eliminar
                             tooltip: 'Eliminar Pago',
                             onPressed: () {
                                // Confirmar y eliminar el pago
                                _confirmAndDeletePayment(context, debt.id!, originalIndex); // Pasa el ID de la deuda y el índice ORIGINAL
                             },
                           ),
                       ],
                    ),
                  );
                },
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
