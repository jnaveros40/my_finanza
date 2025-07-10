// lib/screens/edit_category_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:mis_finanza/services/firestore_service/category_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final Category category; // Recibe la categoría a editar

  const EditCategoryScreen({super.key, required this.category});

  @override
  _EditCategoryScreenState createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _firestoreService = CategoryService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _nameController = TextEditingController();

  // Variables para el selector de tipo de categoría (pre-llenado)
  String _selectedType = 'expense'; // Valor por defecto, se sobrescribirá

  // Opciones para el tipo
  final List<String> _categoryTypes = ['expense', 'income'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // --- Pre-llenar controladores y variables con los datos de widget.category ---
    _nameController.text = widget.category.name;
    _selectedType = _categoryTypes.contains(widget.category.type) ? widget.category.type : _categoryTypes.first; // Asegurar que el tipo exista en la lista

    // isPredefined e iconName no necesitan controladores si no son editables aquí
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Función para actualizar la categoría en Firestore
  Future<void> _updateCategory() async {
    if (_formKey.currentState!.validate()) {
       if (currentUser == null || widget.category.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se puede actualizar la categoría (usuario o ID inválido).')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        // Crear el objeto Category actualizado, usando el ID existente
        final updatedCategory = widget.category.copyWith( // Usar copyWith
          id: widget.category.id, // MANTENER el ID existente
          userId: currentUser!.uid, // Asegurar que el userId sea el correcto
          name: _nameController.text.trim(),
          type: _selectedType,
          // isPredefined y iconName se mantienen con copyWith a menos que se pasen explícitamente
        );

        // Llamar al servicio para guardar (actualizar) la categoría
        await CategoryService.saveCategory(updatedCategory); // saveCategory maneja creación y actualización

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría actualizada con éxito.')),
        );

        // Navegar de regreso
        Navigator.pop(context);

      } catch (e) {
        //print('Error al actualizar categoría: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la categoría: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Por favor, ingresa un nombre para la categoría.')),
         );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Categoría'),
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
                    // Campo Nombre de la Categoría (pre-llenado)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nombre de la Categoría'),
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
                       decoration: InputDecoration(labelText: 'Tipo'),
                       value: _selectedType,
                       items: _categoryTypes.map((String type) {
                         return DropdownMenuItem<String>(
                           value: type,
                           child: Text(type == 'expense' ? 'Gasto' : 'Ingreso'), // Mostrar en español
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

                    // Botón Actualizar Categoría
                     ElevatedButton(
                      onPressed: _updateCategory,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18),
                      ), // Llama a la función para actualizar
                      child: Text('Actualizar Categoría'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}