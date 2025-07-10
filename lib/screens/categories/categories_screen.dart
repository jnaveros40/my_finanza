// lib/screens/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:mis_finanza/services/firestore_service/category_service.dart';
// Importar la pantalla para añadir/editar categorías
import 'package:mis_finanza/screens/categories/add_edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _firestoreService = CategoryService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- NUEVOS ESTADOS PARA LOS FILTROS ---
  // Null significa "Mostrar todos"
  String? _selectedTypeFilter; // Filtro por tipo ('expense', 'income', o null)
  String? _selectedBudgetFilter; // Filtro por presupuesto ('needs', 'wants', 'savings', o null)
  // --------------------------------------


  // Helper para obtener el texto a mostrar para el tipo de categoría (usado en la lista y el filtro)
  String _getCategoryTypeText(String type) {
      switch (type) {
          case 'expense': return 'Gasto';
          case 'income': return 'Ingreso';
          default: return type;
      }
  }

  // Helper para obtener el texto a mostrar para el filtro de tipo
   String _getCategoryTypeFilterText(String? type) {
      if (type == null) return 'Todos los Tipos';
       switch (type) {
          case 'expense': return 'Gasto';
          case 'income': return 'Ingreso';
          default: return type;
      }
   }


  // Helper para obtener el texto de la categoría de presupuesto (usado en la lista y el filtro)
  String _getBudgetCategoryDisplayText(String? budgetCategoryValue) {
      if (budgetCategoryValue == null) {
          return 'Presupuesto: No asociado'; // Texto para cuando no hay categoría de presupuesto
      }
      switch (budgetCategoryValue) {
          case 'needs': return 'Presupuesto: Necesidades';
          case 'wants': return 'Presupuesto: Deseos';
          case 'savings': return 'Presupuesto: Ahorros';
          default: return 'Presupuesto: Desconocido'; // En caso de un valor inesperado
      }
  }

   // Helper para obtener el texto para el filtro de presupuesto
    String _getBudgetCategoryFilterText(String? budgetCategoryValue) {
       if (budgetCategoryValue == null) {
           return 'Todos los Presupuestos';
       }
       switch (budgetCategoryValue) {
           case 'needs': return 'Necesidades';
           case 'wants': return 'Deseos';
           case 'savings': return 'Ahorros';
           default: return 'Desconocido';
       }
    }


   // Función para confirmar y eliminar categoría
   Future<bool> _confirmAndDeleteCategory(BuildContext context, Category category) async {
       // ... (tu código actual para confirmar eliminación)
        bool confirm = await showDialog(
         context: context,
         builder: (BuildContext context) {
           return AlertDialog(
             title: Text('Confirmar Eliminación'),
             content: Text('¿Estás seguro de que deseas eliminar la categoría "${category.name}" (${_getCategoryTypeText(category.type)})?'),
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
           if (category.id != null) {
             // Llama al servicio para eliminar la categoría
             await CategoryService.deleteCategory(category.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Categoría "${category.name}" eliminada.')),
              );
              return true;
           } else {
              //print('Error: Intentando eliminar categoría sin ID.');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: No se pudo obtener el ID de la categoría para eliminar.')),
              );
              return false;
           }
         } catch (e) {
            //print('Error al eliminar categoría: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar la categoría: ${e.toString()}')),
            );
            return false;
         }
       }
       return false;
   }


  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(child: Text('Por favor, inicia sesión para ver tus categorías.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'), // Título de la pantalla
      ),
      body: Column( // Usamos Column para poner los filtros arriba de la lista
        children: [          // --- SECCIÓN DE FILTROS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Filtro por Tipo
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String?>(
                      decoration: InputDecoration(
                        labelText: 'Filtrar por Tipo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getCategoryTypeColor(_selectedTypeFilter).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryTypeIcon(_selectedTypeFilter),
                            color: _getCategoryTypeColor(_selectedTypeFilter),
                            size: 20,
                          ),
                        ),
                      ),
                      value: _selectedTypeFilter,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null, // Valor para "Mostrar todos"
                          child: Text('Todos'),
                        ),
                         DropdownMenuItem<String>(
                          value: 'expense',
                          child: Text(_getCategoryTypeFilterText('expense')),
                        ),
                         DropdownMenuItem<String>(
                          value: 'income',
                          child: Text(_getCategoryTypeFilterText('income')),
                        ),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTypeFilter = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Espacio entre filtros

                // Filtro por Presupuesto
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String?>(
                       decoration: InputDecoration(
                         labelText: 'Filtrar por Categoria',
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                           borderSide: BorderSide.none,
                         ),
                         filled: true,
                         fillColor: Colors.transparent,
                         prefixIcon: Container(
                           margin: const EdgeInsets.all(8),
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: _getBudgetCategoryColor(_selectedBudgetFilter).withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Icon(
                             _getBudgetCategoryIcon(_selectedBudgetFilter),
                             color: _getBudgetCategoryColor(_selectedBudgetFilter),
                             size: 20,
                           ),
                         ),
                       ),
                       value: _selectedBudgetFilter,
                       items: [
                          const DropdownMenuItem<String?>(
                             value: null, // Valor para "Mostrar todos"
                             child: Text('Todos'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'needs',
                            child: Text(_getBudgetCategoryFilterText('needs')),
                          ),
                          DropdownMenuItem<String>(
                            value: 'wants',
                            child: Text(_getBudgetCategoryFilterText('wants')),
                          ),
                           DropdownMenuItem<String>(
                            value: 'savings',
                            child: Text(_getBudgetCategoryFilterText('savings')),
                          ),
                          // Si quieres incluir categorías que no tienen presupuesto asociado en el filtro:
                          const DropdownMenuItem<String>(
                             value: 'no_budget', // Usar un valor único para "Sin Presupuesto"
                             child: Text('Sin Presupuesto'),
                          ),
                       ],
                       onChanged: (newValue) {
                          setState(() {
                             _selectedBudgetFilter = newValue;
                          });
                       },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // -------------------------

          // --- LISTA DE CATEGORÍAS (ahora dentro de Expanded) ---
          Expanded( // Expanded es necesario porque ListView.builder necesita límites en una Column
            child: StreamBuilder<List<Category>>(
              stream: CategoryService.getCategories(), // Obtener todas las categorías
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                   //print('Error cargando categorías: ${snapshot.error}');
                  return Center(child: Text('Error al cargar las categorías: ${snapshot.error}'));
                }
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No tienes categorías aún.'));
                }

                final allCategories = snapshot.data!; // Lista completa de Category

                // --- LÓGICA DE FILTRADO ---
                final filteredCategories = allCategories.where((category) {
                  // Filtrar por tipo
                  if (_selectedTypeFilter != null && category.type != _selectedTypeFilter) {
                    return false; // No incluir si el tipo no coincide con el filtro
                  }

                  // Filtrar por presupuesto
                  if (_selectedBudgetFilter != null) {
                     if (_selectedBudgetFilter == 'no_budget') {
                        // Si el filtro es "Sin Presupuesto", solo incluir si budgetCategory es null
                        if (category.budgetCategory != null) {
                           return false;
                        }
                     } else {
                        // Si el filtro es un tipo de presupuesto (needs, wants, savings), incluir solo si coincide
                        if (category.budgetCategory != _selectedBudgetFilter) {
                           return false;
                        }
                     }
                  }

                  // Si pasa todos los filtros, incluir la categoría
                  return true;
                }).toList();
                // ---------------------------


                 if (filteredCategories.isEmpty) {
                    return Center(child: Text('No se encontraron categorías con los filtros seleccionados.'));
                 }                // Construir la lista de categorías filtradas
                return ListView.builder(
                  itemCount: filteredCategories.length, // Usar la lista FILTRADA
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index]; // Cada elemento es una Category
                    
                    return Dismissible( // Permitir deslizar para eliminar
                       key: Key(category.id!), // Clave única para cada categoría
                       direction: DismissDirection.endToStart,
                       background: Container(
                         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                         decoration: BoxDecoration(
                           color: Colors.red,
                           borderRadius: BorderRadius.circular(16),
                         ),
                         alignment: Alignment.centerRight,
                         padding: const EdgeInsets.symmetric(horizontal: 20.0),
                         child: const Icon(Icons.delete, color: Colors.white, size: 28),
                       ),
                       confirmDismiss: (direction) async {
                          return await _confirmAndDeleteCategory(context, category);
                       },
                       onDismissed: (direction) {
                           // La lista se actualiza automáticamente por el StreamBuilder después de la eliminación
                       },
                       child: Container(
                         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                         decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.surface,
                           borderRadius: BorderRadius.circular(16),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.1),
                               blurRadius: 8,
                               offset: const Offset(0, 2),
                             ),
                           ],
                         ),
                         child: ListTile(
                           contentPadding: const EdgeInsets.all(16),
                           leading: Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: _getCategoryTypeColor(category.type).withOpacity(0.1),
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Icon(
                               _getCategoryTypeIcon(category.type),
                               color: _getCategoryTypeColor(category.type),
                               size: 24,
                             ),
                           ),
                           title: Text(
                             category.name,
                             style: Theme.of(context).textTheme.titleMedium?.copyWith(
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                           subtitle: Padding(
                             padding: const EdgeInsets.only(top: 8),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   children: [
                                     Container(
                                       padding: const EdgeInsets.all(4),
                                       decoration: BoxDecoration(
                                         color: _getCategoryTypeColor(category.type).withOpacity(0.1),
                                         borderRadius: BorderRadius.circular(6),
                                       ),
                                       child: Icon(
                                         _getCategoryTypeIcon(category.type),
                                         color: _getCategoryTypeColor(category.type),
                                         size: 16,
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                     Text(
                                       'Tipo: ${_getCategoryTypeText(category.type)}',
                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                         color: Theme.of(context).colorScheme.onSurfaceVariant,
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 4),
                                 Row(
                                   children: [
                                     Container(
                                       padding: const EdgeInsets.all(4),
                                       decoration: BoxDecoration(
                                         color: _getBudgetCategoryColor(category.budgetCategory).withOpacity(0.1),
                                         borderRadius: BorderRadius.circular(6),
                                       ),
                                       child: Icon(
                                         _getBudgetCategoryIcon(category.budgetCategory),
                                         color: _getBudgetCategoryColor(category.budgetCategory),
                                         size: 16,
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                     Expanded(
                                       child: Text(
                                         _getBudgetCategoryDisplayText(category.budgetCategory),
                                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                           color: Theme.of(context).colorScheme.onSurfaceVariant,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),                           ),
                           trailing: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Icon(
                               Icons.edit,
                               color: Theme.of(context).colorScheme.primary,
                               size: 20,
                             ),
                           ),
                           onTap: () {
                              // Navegar a pantalla de edición, pasando la categoría seleccionada
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => AddEditCategoryScreen(category: category)), // Pasar la categoría para editar
                             );
                           },
                         ),
                       ),
                    );
                  },
                );
              },
            ),
          ),
          // -------------------------------------------------
        ],
      ),
      // FloatingActionButton para añadir nueva categoría
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // Navegar a pantalla para añadir nueva categoría
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddEditCategoryScreen()), // Sin pasar categoría para añadir
            );
        },        tooltip: 'Añadir Nueva Categoría',
        child: Icon(Icons.add),
      ),
    );
  }

  // Helper methods for category type icons and colors
  IconData _getCategoryTypeIcon(String? type) {
    if (type == null || type.isEmpty) return Icons.category;
    switch (type) {
      case 'expense':
        return Icons.arrow_downward;
      case 'income':
        return Icons.arrow_upward;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryTypeColor(String? type) {
    if (type == null || type.isEmpty) return Colors.grey;
    switch (type) {
      case 'expense':
        return Colors.red;
      case 'income':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper methods for budget category icons and colors
  IconData _getBudgetCategoryIcon(String? budgetCategory) {
    if (budgetCategory == null || budgetCategory.isEmpty) return Icons.category;
    switch (budgetCategory) {
      case 'needs':
        return Icons.home;
      case 'wants':
        return Icons.favorite;
      case 'savings':
        return Icons.savings;
      case 'no_budget':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  Color _getBudgetCategoryColor(String? budgetCategory) {
    if (budgetCategory == null || budgetCategory.isEmpty) return Colors.grey;
    switch (budgetCategory) {
      case 'needs':
        return Colors.blue;
      case 'wants':
        return Colors.orange;
      case 'savings':
        return Colors.green;
      case 'no_budget':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}