// lib/screens/add_category_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:mis_finanza/services/firestore_service/category_service.dart';


class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _firestoreService = CategoryService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _nameController = TextEditingController();

  // Variables para el selector de tipo de categoría
  String _selectedType = 'expense'; // Valor por defecto

  // Opciones para el tipo
  final List<String> _categoryTypes = ['expense', 'income'];

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Función para guardar la categoría en Firestore
  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Usuario no autenticado.', style: Theme.of(context).textTheme.bodyMedium)), // Usar estilo de texto del tema
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        // Crear el objeto Category
        final newCategory = Category(
          id: null, // Firestore generará el ID
          userId: currentUser!.uid,
          name: _nameController.text.trim(),
          type: _selectedType,
          //isPredefined: false, // Las creadas por el usuario no son predefinidas Falta por actualizar esta parte
          // iconName: null, // Puedes añadir esto si implementas la selección de iconos
        );

        // Llamar al servicio para guardar la categoría
        await CategoryService.saveCategory(newCategory);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría guardada con éxito.', style: Theme.of(context).textTheme.bodyMedium)), // Usar estilo de texto del tema
        );

        // Navegar de regreso
        Navigator.pop(context);

      } catch (e) {
        //print('Error al guardar categoría: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la categoría: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium)), // Usar estilo de texto del tema
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, ingresa un nombre para la categoría.', style: Theme.of(context).textTheme.bodyMedium)), // Usar estilo de texto del tema
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Nueva Categoría'),
        // El color del AppBar se adapta al tema por defecto si no se especifica
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)) // Usar color primario del tema
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Campo Nombre de la Categoría
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la Categoría',
                        border: OutlineInputBorder(),
                        // Los colores de la decoración se adaptan al tema
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa un nombre';
                        }
                        return null;
                      },
                       style: Theme.of(context).textTheme.bodyMedium, // Usar estilo de texto del tema para el texto ingresado
                    ),
                    SizedBox(height: 12),

                    // Selector de Tipo (Dropdown)
                     DropdownButtonFormField<String>(
                       decoration: InputDecoration(
                         labelText: 'Tipo',
                         border: OutlineInputBorder(),
                         // Los colores de la decoración se adaptan al tema
                       ),
                       value: _selectedType,
                       items: _categoryTypes.map((String type) {
                         return DropdownMenuItem<String>(
                           value: type,
                           child: Text(type == 'expense' ? 'Gasto' : 'Ingreso', style: Theme.of(context).textTheme.bodyMedium), // Mostrar en español y usar estilo del tema
                         );
                       }).toList(),
                       onChanged: (newValue) {
                         if (newValue != null) {
                           setState(() {
                             _selectedType = newValue;
                           });
                         }
                       },
                        // Validar que se haya seleccionado un tipo
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Por favor, selecciona un tipo';
                         }
                         return null;
                       },
                        style: Theme.of(context).textTheme.bodyMedium, // Usar estilo de texto del tema para el texto seleccionado
                     ),
                     SizedBox(height: 24),

                    // Botón Guardar Categoría
                     ElevatedButton(
                      onPressed: _isSaving ? null : _saveCategory, // Indicador de carga en el botón con color blanco
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18), // Tamaño de fuente fijo para el botón
                         // Los colores del botón se adaptan al tema por defecto
                      ), // Llama a la función para guardar
                      child: _isSaving ? CircularProgressIndicator(color: Colors.white) : Text('Guardar Categoría'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
