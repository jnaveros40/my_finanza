// lib/screens/edit_payment_method_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/payment_method.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';

class EditPaymentMethodScreen extends StatefulWidget {
  final PaymentMethod paymentMethod; // Recibe el método a editar

  const EditPaymentMethodScreen({super.key, required this.paymentMethod});

  @override
  _EditPaymentMethodScreenState createState() => _EditPaymentMethodScreenState();
}

class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _nameController = TextEditingController();

  String _selectedType = 'Efectivo'; // Valor por defecto (efectivo)

  // Opciones para el tipo de método de pago
  final List<String> _paymentMethodTypes = [
    'Efectivo',
    'Tarjeta debito',
    'Tarjeta Credito',
    'Transferencia Bancaria',
    'other'
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // --- Pre-llenar controladores y variables con los datos de widget.paymentMethod ---
    _nameController.text = widget.paymentMethod.name;
    _selectedType = _paymentMethodTypes.contains(widget.paymentMethod.type) ? widget.paymentMethod.type : _paymentMethodTypes.first; // Ensure type exists in list

    // isPredefined doesn't need controller if not editable here
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Función para actualizar el método de pago en Firestore
  Future<void> _updatePaymentMethod() async {
    if (_formKey.currentState!.validate()) {
       if (currentUser == null || widget.paymentMethod.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se puede actualizar el método de pago (usuario o ID inválido).')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        // Crear el objeto PaymentMethod actualizado, usando el ID existente
        final updatedMethod = widget.paymentMethod.copyWith( // Use copyWith
          id: widget.paymentMethod.id, // KEEP the existing ID
          userId: currentUser!.uid, // Ensure the userId is correct
          name: _nameController.text.trim(),
          type: _selectedType,
          // isPredefined is kept with copyWith unless explicitly passed
        );

        // Call service to save (update) the payment method
        await PaymentMethodService.savePaymentMethod(updatedMethod); // savePaymentMethod handles create and update

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Método de pago actualizado con éxito.')),
        );

        // Navigate back
        Navigator.pop(context);

      } catch (e) {
        print('Error al actualizar método de pago: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el método de pago: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Por favor, ingresa un nombre y selecciona un tipo.')),
         );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Método de Pago'),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Campo Nombre del Método de Pago (pre-llenado)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Método de Pago',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),

                    // Selector de Tipo (pre-llenado)
                     DropdownButtonFormField<String>(
                       decoration: InputDecoration(
                         labelText: 'Tipo',
                         prefixIcon: Icon(Icons.category),
                       ),
                       value: _selectedType,
                       items: _paymentMethodTypes.map((String type) {
                         return DropdownMenuItem<String>(
                           value: type,
                           child: Text(type), // Display the type string
                         );
                       }).toList(),
                       onChanged: (newValue) {
                         if (newValue != null) {
                           setState(() {
                             _selectedType = newValue;
                           });
                         }
                       },
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Por favor, selecciona un tipo';
                         }
                         return null;
                       },
                     ),
                     SizedBox(height: 24),

                    // Botón Actualizar Método de Pago
                     ElevatedButton(
                      onPressed: _updatePaymentMethod, // Call update function
                      child: Text('Actualizar Método de Pago'),
                      // El estilo del botón ya está unificado en el tema global
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}*/