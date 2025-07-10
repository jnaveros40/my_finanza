// lib/screens/add_edit_category_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/category.dart'; // Importar el modelo Category
import 'package:mis_finanza/services/firestore_service/category_service.dart';
import 'package:uuid/uuid.dart'; // Necesario para generar IDs únicos


class AddEditCategoryScreen extends StatefulWidget {
  // Si se pasa una categoría, estamos editando. Si es null, estamos añadiendo.
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  _AddEditCategoryScreenState createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _firestoreService = CategoryService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController();

  // Valor seleccionado para el tipo de categoría ('expense' o 'income')
  String _selectedType = 'expense'; // Valor por defecto

  // --- NUEVO: Valor seleccionado para la categoría de presupuesto (50/30/20) ---
  String? _selectedBudgetCategory; // Puede ser null inicialmente

  // Opciones para el tipo de categoría
  final List<String> _categoryTypes = ['expense', 'income'];

  // --- NUEVO: Opciones para la categoría de presupuesto ---
  // Usamos un mapa para mostrar texto amigable en la UI pero guardar el valor clave
  final Map<String, String> _budgetCategoryOptions = {
      'needs': 'Necesidades',
      'wants': 'Deseos',
      'savings': 'Ahorros',
      // Puedes añadir más si es necesario, o dejar que algunas categorías no tengan asociación (null)
  };


  bool _isSaving = false; // Indicador de carga al guardar


  @override
  void initState() {
    super.initState();
    // Si estamos editando, pre-llenar el formulario con los datos de la categoría
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedType = widget.category!.type;
      // --- Pre-seleccionar la categoría de presupuesto si existe ---
      _selectedBudgetCategory = widget.category!.budgetCategory;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Función para guardar la categoría
  Future<void> _saveCategory() async {
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
        // Crear el objeto Category
        final categoryToSave = Category(
          // Si estamos editando, usar el ID existente. Si no, generar uno nuevo.
          id: widget.category?.id ?? const Uuid().v4(),
          userId: currentUser!.uid,
          name: _nameController.text.trim(),
          type: _selectedType,
          // --- Guardar la categoría de presupuesto seleccionada ---
          budgetCategory: _selectedBudgetCategory, // Será null si no se selecciona nada
        );

        // Llamar al servicio para guardar la categoría (maneja añadir o actualizar)
        await CategoryService.saveCategory(categoryToSave);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría guardada con éxito.')),
        );

        Navigator.pop(context); // Navegar de regreso a la pantalla anterior (CategoriesScreen)

      } catch (e) {
        //print('Error al guardar categoría: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la categoría: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, completa los campos requeridos y selecciona las opciones válidas.')),
        );
    }
  }
  // Helper methods for responsive design
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  
  double _getResponsivePadding(BuildContext context) => _isMobile(context) ? 16.0 : 24.0;
  
  double _getResponsiveSpacing(BuildContext context) => _isMobile(context) ? 20.0 : 24.0;
  
  double _getMaxWidth(BuildContext context) => _isMobile(context) ? double.infinity : 600.0;

  // Build header with icon and title
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            widget.category == null ? Icons.add_circle_outline : Icons.edit_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.category == null ? 'Nueva Categoría' : 'Editar Categoría',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.category == null 
              ? 'Crea una nueva categoría para organizar tus movimientos'
              : 'Modifica los detalles de tu categoría',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Añadir Categoría' : 'Editar Categoría'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isSaving
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(_getResponsivePadding(context)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: _getMaxWidth(context)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(_getResponsivePadding(context)),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                // Header with icon
                                _buildHeader(context),
                                SizedBox(height: _getResponsiveSpacing(context)),                                // Campo Nombre con diseño moderno
                                _buildNameField(context),
                                SizedBox(height: _getResponsiveSpacing(context)),

                                // Dropdown Tipo de Categoría con diseño moderno
                                _buildTypeField(context),
                                SizedBox(height: _getResponsiveSpacing(context)),

                                // Dropdown Categoría de Presupuesto con diseño moderno
                                if (_selectedType == 'expense') 
                                  _buildBudgetCategoryField(context),
                                if (_selectedType == 'expense') 
                                  SizedBox(height: _getResponsiveSpacing(context)),                                // Botón Guardar con diseño moderno
                                _buildSaveButton(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Build modern name field
  Widget _buildNameField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Nombre de la Categoría',
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.label_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, ingresa el nombre de la categoría';
          }
          return null;
        },
      ),
    );
  }

  // Build modern type field
  Widget _buildTypeField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Tipo de Categoría',
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _selectedType == 'expense' ? Icons.remove_circle_outline : Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        value: _selectedType,
        items: _categoryTypes.map((String type) {
          String displayText = type == 'expense' ? 'Gasto' : 'Ingreso';
          return DropdownMenuItem<String>(
            value: type,
            child: Text(displayText),
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
    );
  }

  // Build modern budget category field
  Widget _buildBudgetCategoryField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonFormField<String?>(
        decoration: InputDecoration(
          labelText: 'Asociar a Presupuesto (50/30/20)',
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.donut_small,
              color: Theme.of(context).colorScheme.tertiary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        value: _selectedBudgetCategory,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Ninguna (No aplica)'),
          ),
          ..._budgetCategoryOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }),
        ],
        onChanged: (newValue) {
          setState(() {
            _selectedBudgetCategory = newValue;
          });
        },
      ),
    );
  }

  // Build modern save button
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.category == null ? Icons.add : Icons.save,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.category == null ? 'Crear Categoría' : 'Guardar Cambios',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
*/