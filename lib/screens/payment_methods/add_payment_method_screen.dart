// lib/screens/add_payment_method_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/payment_method.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';


class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  _AddPaymentMethodScreenState createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _nameController = TextEditingController();

  // Variables para el selector de tipo de método de pago
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Función para guardar el método de pago en Firestore
  Future<void> _savePaymentMethod() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        // Crear el objeto PaymentMethod
        final newMethod = PaymentMethod(
          id: null, // Firestore generará el ID
          userId: currentUser!.uid,
          name: _nameController.text.trim(),
          type: _selectedType,
          isPredefined: false, // Los creados por el usuario no son predefinidos
        );

        // Llamar al servicio para guardar el método de pago
        await PaymentMethodService.savePaymentMethod(newMethod);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Método de pago guardado con éxito.')),
        );

        // Navegar de regreso
        Navigator.pop(context);

      } catch (e) {
        print('Error al guardar método de pago: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el método de pago: ${e.toString()}')),
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
        title: const Text('Añadir Nuevo Método de Pago'),
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
                    // Campo Nombre del Método de Pago
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

                    // Selector de Tipo (Dropdown)
                     DropdownButtonFormField<String>(
                       decoration: InputDecoration(
                         labelText: 'Tipo',
                         prefixIcon: Icon(Icons.category),
                       ),
                       value: _selectedType,
                       items: _paymentMethodTypes.map((String type) {
                         return DropdownMenuItem<String>(
                           value: type,
                           child: Text(type), // Mostrar el string del tipo
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

                    // Botón Guardar Método de Pago
                     ElevatedButton(
                      onPressed: _savePaymentMethod, // Llama a la función para guardar
                      child: Text('Guardar Método de Pago'),
                      // El estilo del botón ya está unificado en el tema global
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}