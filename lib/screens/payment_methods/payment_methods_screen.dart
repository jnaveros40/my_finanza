// lib/screens/payment_methods_screen.dart

import 'package:flutter/material.dart';
import 'package:mis_finanza/models/payment_method.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';
// TODO: Import AddPaymentMethodScreen and EditPaymentMethodScreen when created
// import 'package:mis_finanza/screens/payment_methods/add_payment_method_screen.dart';
import 'package:mis_finanza/screens/payment_methods/edit_payment_method_screen.dart';


class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

   // --- Función para confirmar y eliminar método de pago ---
   Future<bool> _confirmAndDeletePaymentMethod(BuildContext context, PaymentMethod method) async {
       bool confirm = await showDialog(
         context: context,
         builder: (BuildContext context) {
           return AlertDialog(
             title: Text('Confirmar Eliminación'),
             content: Text('¿Estás seguro de que deseas eliminar el método de pago "${method.name}"? Esto no eliminará los gastos asociados, pero podría afectar reportes.'),
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
           if (method.id != null) {
             await PaymentMethodService.deletePaymentMethod(method.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Método de pago "${method.name}" eliminado.')),
              );
              return true; // Indicates successful deletion
           } else {
              //print('Error: Intentando eliminar método de pago sin ID.');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: No se pudo obtener el ID del método de pago para eliminar.')),
              );
              return false; // Indicates deletion failed due to missing ID
           }
         } catch (e) {
            //print('Error al eliminar método de pago: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar el método de pago: \\${e.toString()}')),
            );
            return false; // Indicates an error during deletion
         }
       }
       return false; // Indicates deletion was canceled
   }


  @override
  Widget build(BuildContext context) {
    // Scaffold is handled by MainAppScreen (will adjust later if needed)
    return Scaffold(
       appBar: AppBar(
         title: const Text('Métodos de Pago'), // Title for this specific screen
       ),
      body: Column(
        children: [
          // TODO: Maybe add filters later

          Expanded(
            // Listen to the stream of payment methods
            child: StreamBuilder<List<PaymentMethod>>(
              stream: PaymentMethodService.getPaymentMethods(), // Get all payment methods for the user
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                   //print('Error cargando métodos de pago: ${snapshot.error}');
                  return Center(child: Text('Error al cargar los métodos de pago: ${snapshot.error}'));
                }
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No tienes métodos de pago aún. ¡Agrega uno!'));
                }

                final methods = snapshot.data!;

                // Build the list of payment methods
                return ListView.builder(
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    final method = methods[index];

                     // --- Wrap ListTile with Dismissible for Delete ---
                    return Dismissible(
                       key: Key(method.id!), // Unique key (Firestore ID)
                       direction: DismissDirection.endToStart, // Swipe right to left
                       background: Container( // Red background with trash icon
                         color: Colors.red,
                         alignment: Alignment.centerRight,
                         padding: EdgeInsets.symmetric(horizontal: 20.0),
                         child: Icon(Icons.delete, color: Colors.white),
                       ),
                       // Confirm before dismissing (deleting)
                       confirmDismiss: (direction) async {
                          // Call the function that shows the dialog and handles deletion
                          return await _confirmAndDeletePaymentMethod(context, method);
                       },
                       // onDismissed is called if confirmDismiss returns true.
                       onDismissed: (direction) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Método de pago "${method.name}" deslizado para eliminar.')),
                           );
                           // The list updates automatically via the StreamBuilder
                       },
                       child: ListTile( // The ListTile that shows method details
                          leading: Icon(Icons.credit_card), // Example icon
                          title: Text(method.name),
                          subtitle: Text('Tipo: ${method.type}'), // Display type (e.g., cash, debit_card)
                          trailing: method.isPredefined ? Icon(Icons.lock_outline, size: 18) : null, // Optional: Show icon for predefined
                          onTap: () {
                            // Navegar a la pantalla de edición, pasando el método de pago seleccionado
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => EditPaymentMethodScreen(paymentMethod: method)), // <-- Pasar el objeto paymentMethod
                             );
                             // TODO: Navigate to EditPaymentMethodScreen
                             // Navigator.push(context, MaterialPageRoute(builder: (context) => EditPaymentMethodScreen(paymentMethod: method))); // Pass the method object or its ID
                              //print('Tap en método de pago: ${method.name}'); // Placeholder
                           },
                       ), // Fin de ListTile
                    ); // Fin de Dismissible
                  },
                ); // Fin de ListView.builder
              },
            ), // Fin de StreamBuilder
          ), // Fin de Expanded
        ],
      ), // Fin de Column
       // FloatingActionButton will be managed by MainAppScreen
    ); // Fin de Scaffold
  }
}