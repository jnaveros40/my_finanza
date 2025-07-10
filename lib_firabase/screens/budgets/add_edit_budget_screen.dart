// lib/screens/add_edit_budget_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/budget.dart'; // Importar el modelo Budget
import 'package:mis_finanza/models/category.dart'; // Importar el modelo Category
import 'package:mis_finanza/services/firestore_service/index.dart';
import 'package:uuid/uuid.dart'; // Necesario para generar IDs únicos
import 'package:intl/intl.dart'; // Para formatear moneda
//import 'package:collection/collection.dart'; // Para firstWhereOrNull
import 'package:month_picker_dialog/month_picker_dialog.dart'; // Para seleccionar mes/año

class AddEditBudgetScreen extends StatefulWidget {
  // Si se pasa un presupuesto, estamos editando. Si es null, estamos añadiendo.
  final Budget? budget;

  const AddEditBudgetScreen({super.key, this.budget});

  @override
  _AddEditBudgetScreenState createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  // final FirestoreService _firestoreService = FirestoreService(); // Eliminar instancia
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _uuid = Uuid(); // Para generar IDs

  // Controladores para los campos de texto
  final TextEditingController _monthYearController = TextEditingController();
  final TextEditingController _totalBudgetController = TextEditingController();

  // NUEVOS: Controladores para los porcentajes editables
  final TextEditingController _needsPercentageController = TextEditingController();
  final TextEditingController _wantsPercentageController = TextEditingController();
  final TextEditingController _savingsPercentageController = TextEditingController();

  // Mapa para controladores de presupuesto por categoría (si aún quieres la opción de detallar)
  // Mantendremos esto por si quieres usarlo para visualización o para un cálculo secundario
  // Map<String, TextEditingController> _categoryBudgetControllers = {};

  // Lista de categorías de gasto para el desglose del presupuesto
  List<Category> _expenseCategories = []; // Solo categorías de gasto
  bool _isLoadingCategories = true; // Indicador de carga para categorías

  bool _isSaving = false; // Indicador de carga al guardar

  // Fecha seleccionada para el mes y año
  DateTime _selectedMonthYear = DateTime.now();

  // Monto total presupuestado (para cálculos en tiempo real)
  double _currentTotalBudget = 0.0;

  // Porcentajes actuales (editables por el usuario)
  double _currentNeedsPercentage = 50.0;
  double _currentWantsPercentage = 30.0;
  double _currentSavingsPercentage = 20.0;

  // --- NUEVO: Variable para almacenar la moneda seleccionada o existente ---
  String _selectedCurrency = 'COP'; // Valor por defecto. Puedes cambiarlo si tu moneda principal es otra.
  // ------------------------------------------------------------------------


  @override
  void initState() {
    super.initState();
    _loadCategories(); // Cargar categorías al iniciar

    if (widget.budget != null) {
      // Estamos editando un presupuesto existente
      _selectedMonthYear = DateFormat('yyyy-MM').parse(widget.budget!.monthYear);
      _monthYearController.text = widget.budget!.monthYear;
      // Cargar el monto total presupuestado existente
      _totalBudgetController.text = widget.budget!.totalBudgeted.toString();
      _currentTotalBudget = widget.budget!.totalBudgeted; // Inicializar el monto actual

      // Cargar los porcentajes existentes del presupuesto
      _currentNeedsPercentage = widget.budget!.needsPercentage;
      _currentWantsPercentage = widget.budget!.wantsPercentage;
      _currentSavingsPercentage = widget.budget!.savingsPercentage;

      // Inicializar controladores de porcentaje con los valores cargados
      _needsPercentageController.text = _currentNeedsPercentage.toString();
      _wantsPercentageController.text = _currentWantsPercentage.toString();
      _savingsPercentageController.text = _currentSavingsPercentage.toString();

      // --- Cargar la moneda existente del presupuesto ---
      _selectedCurrency = widget.budget!.currency;
      // -------------------------------------------------


      // // Cargar los montos por categoría si existen (opcional, si quieres mostrarlos/editarlos)
      // widget.budget!.categoryBudgets.forEach((categoryId, amount) {
      //    _categoryBudgetControllers[categoryId] = TextEditingController(text: amount.toString());
      // });

    } else {
      // Estamos añadiendo un nuevo presupuesto
      _selectedMonthYear = DateTime.now();
      _monthYearController.text = DateFormat('yyyy-MM').format(_selectedMonthYear);
      _totalBudgetController.text = '0.0'; // Inicializar con 0.0 para nuevo presupuesto
      _currentTotalBudget = 0.0; // Inicializar el monto actual

      // Inicializar controladores de porcentaje con valores por defecto
      _needsPercentageController.text = _currentNeedsPercentage.toString();
      _wantsPercentageController.text = _currentWantsPercentage.toString();
      _savingsPercentageController.text = _currentSavingsPercentage.toString();

      // --- Para un nuevo presupuesto, la moneda ya está inicializada en _selectedCurrency ---
      // Si quisieras permitir seleccionar la moneda, añadirías aquí la lógica para ello.
      // Por ahora, usamos el valor por defecto 'COP'.
      // ----------------------------------------------------------------------------------

    }

    // Añadir listeners a los controladores para actualizar el desglose 50/30/20
    _totalBudgetController.addListener(_updateCalculatedAmounts);
    _needsPercentageController.addListener(_updateCalculatedAmounts);
    _wantsPercentageController.addListener(_updateCalculatedAmounts);
    _savingsPercentageController.addListener(_updateCalculatedAmounts);
  }

  @override
  void dispose() {
    _monthYearController.dispose();
    _totalBudgetController.removeListener(_updateCalculatedAmounts); // Remover listener
    _totalBudgetController.dispose();
    // Remover listeners y dispose de los controladores de porcentaje
    _needsPercentageController.removeListener(_updateCalculatedAmounts);
    _needsPercentageController.dispose();
    _wantsPercentageController.removeListener(_updateCalculatedAmounts);
    _wantsPercentageController.dispose();
    _savingsPercentageController.removeListener(_updateCalculatedAmounts);
    _savingsPercentageController.dispose();

    // Dispose de los controladores de categoría si se usan
    // _categoryBudgetControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Método para actualizar el monto total actual y recalcular el desglose 50/30/20
  void _updateCalculatedAmounts() {
     // Actualizar el monto total
    final double? parsedTotalAmount = double.tryParse(_totalBudgetController.text.trim());
    if (parsedTotalAmount != null && parsedTotalAmount >= 0) {
      _currentTotalBudget = parsedTotalAmount;
    } else {
       _currentTotalBudget = 0.0;
    }

    // Actualizar los porcentajes (solo si son números válidos)
    final double? parsedNeeds = double.tryParse(_needsPercentageController.text.trim());
    final double? parsedWants = double.tryParse(_wantsPercentageController.text.trim());
    final double? parsedSavings = double.tryParse(_savingsPercentageController.text.trim());

    if (parsedNeeds != null && parsedNeeds >= 0) {
      _currentNeedsPercentage = parsedNeeds;
    } else {
       _currentNeedsPercentage = 0.0;
    }

     if (parsedWants != null && parsedWants >= 0) {
      _currentWantsPercentage = parsedWants;
    } else {
       _currentWantsPercentage = 0.0;
    }

     if (parsedSavings != null && parsedSavings >= 0) {
      _currentSavingsPercentage = parsedSavings;
    } else {
       _currentSavingsPercentage = 0.0;
    }

    // Llamar a setState para redibujar la UI con los nuevos valores
    setState(() {});
  }


  // Cargar categorías de gasto desde Firestore
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      // Solo obtenemos categorías de tipo 'expense' para el presupuesto de gastos
      CategoryService.getCategoriesByType('expense').listen((categories) {
        setState(() {
          _expenseCategories = categories;
          _isLoadingCategories = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar categorías: \\${e.toString()}')),
      );
    }
  }


  // Función para mostrar el selector de mes y año
  Future<void> _selectMonthYear(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonthYear,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedMonthYear) {
      setState(() {
        _selectedMonthYear = picked;
        _monthYearController.text = DateFormat('yyyy-MM').format(_selectedMonthYear);
      });
    }
  }

  // Función para guardar o actualizar el presupuesto
  Future<void> _saveBudget() async {
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
        // Obtener el monto total presupuestado del campo de texto manual
        final totalBudgeted = double.tryParse(_totalBudgetController.text.trim()) ?? 0.0;

        // Obtener los porcentajes de los campos de texto editables
        final needsPercentage = double.tryParse(_needsPercentageController.text.trim()) ?? 0.0;
        final wantsPercentage = double.tryParse(_wantsPercentageController.text.trim()) ?? 0.0;
        final savingsPercentage = double.tryParse(_savingsPercentageController.text.trim()) ?? 0.0;

        // Validar que la suma de los porcentajes sea 100 (o muy cercano)
        if ((needsPercentage + wantsPercentage + savingsPercentage).round() != 100) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('La suma de los porcentajes debe ser 100%.')),
             );
             setState(() { _isSaving = false; });
             return;
        }

        // Crear el objeto Budget
        final budget = Budget(
          id: widget.budget?.id ?? _uuid.v4(), // Usar ID existente si edita, si no generar uno nuevo
          userId: currentUser!.uid,
          monthYear: _monthYearController.text,
          totalBudgeted: totalBudgeted, // Usar el monto total manual
          needsPercentage: needsPercentage, // Guardar el porcentaje editable
          wantsPercentage: wantsPercentage, // Guardar el porcentaje editable
          savingsPercentage: savingsPercentage, // Guardar el porcentaje editable
          currency: _selectedCurrency, // Usar la moneda almacenada en el estado
          categoryBudgets: widget.budget?.categoryBudgets ?? {},
        );

        // Guardar el presupuesto usando BudgetService
        await BudgetService.saveBudget(budget);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presupuesto guardado con éxito.')),
        );

        Navigator.of(context).pop(); // Cerrar la pantalla

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el presupuesto: \\${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Helper para formatear moneda (puedes ajustarlo según tus necesidades)
  String _formatCurrency(double amount) {
    // --- Usar la moneda seleccionada para formatear ---
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: _selectedCurrency == 'COP' ? '\$' : _selectedCurrency); // Ejemplo básico
    // Puedes mejorar esto para manejar diferentes símbolos y formatos según la moneda
    // ---------------------------------------------------
    return formatter.format(amount);
  }
  // Helper para construir secciones del formulario con diseño responsivo
  Widget _buildFormSection({
    required BuildContext context,
    required bool isMobile,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
          SizedBox(height: isMobile ? 16 : 20),
          ...children,
        ],
      ),
    );
  }

  // Helper para construir el campo de porcentaje responsivo
  Widget _buildResponsivePercentageField({
    required bool isMobile,
    required String labelText,
    required TextEditingController controller,
    required double calculatedAmount,
    required IconData icon,
    required Color color,
  }) {
    if (isMobile) {
      // Layout vertical para móviles
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  labelText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Porcentaje',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un porcentaje';
                      }
                      final double? parsedValue = double.tryParse(value);
                      if (parsedValue == null || parsedValue < 0) {
                        return 'Valor inválido (>= 0)';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatCurrency(calculatedAmount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Layout horizontal para pantallas más grandes
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text(
                labelText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Porcentaje',
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un porcentaje';
                  }
                  final double? parsedValue = double.tryParse(value);
                  if (parsedValue == null || parsedValue < 0) {
                    return 'Valor inválido (>= 0)';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatCurrency(calculatedAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper para construir el botón de guardar responsivo
  Widget _buildResponsiveSaveButton({
    required BuildContext context,
    required bool isMobile,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 50 : 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveBudget,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save,
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Guardar Presupuesto',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      )
    );
  }

  // Helper para construir el campo de porcentaje editable (método original mantenido por compatibilidad)
  Widget _buildPercentageField({
    required String labelText,
    required TextEditingController controller,
    required double calculatedAmount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: labelText,
                suffixText: '%', // Añadir el símbolo de porcentaje
                border: OutlineInputBorder(), // Añadir borde para que se vea como campo editable
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Ajustar padding
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un porcentaje';
                }
                final double? parsedValue = double.tryParse(value);
                if (parsedValue == null || parsedValue < 0) {
                  return 'Valor inválido (>= 0)';
                }
                // La validación de la suma total se hace al guardar
                return null;
              },
            ),
          ),
          SizedBox(width: 16), // Espacio entre el campo de porcentaje y el monto calculado
          Expanded(
             flex: 3, // Dar más espacio al monto calculado si es necesario
             child: Text(
                _formatCurrency(calculatedAmount), // Usar el helper de formato
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.end, // Alinear a la derecha
             ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Añadir Presupuesto' : 'Editar Presupuesto'),
      ),
      body: _isLoadingCategories
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 600;
                final double horizontalPadding = isMobile ? 16.0 : 24.0;
                final double verticalSpacing = isMobile ? 16.0 : 20.0;
                
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 600,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Detalles del Presupuesto',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: isMobile ? 20 : 24,
                              ),
                              textAlign: isMobile ? TextAlign.center : TextAlign.start,
                            ),
                            SizedBox(height: verticalSpacing),

                            // Basic Details Section
                            _buildFormSection(
                              context: context,
                              isMobile: isMobile,
                              title: 'Información Básica',
                              children: [
                                // Campo Mes y Año
                                TextFormField(
                                  controller: _monthYearController,
                                  decoration: InputDecoration(
                                    labelText: 'Mes y Año (YYYY-MM)',
                                    prefixIcon: Icon(Icons.calendar_month),
                                    suffixIcon: Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isMobile ? 16 : 20,
                                    ),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectMonthYear(context),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, selecciona el mes y año';
                                    }
                                    try {
                                      DateFormat('yyyy-MM').parseStrict(value);
                                      return null;
                                    } catch (e) {
                                      return 'Formato incorrecto. Usa YYYY-MM';
                                    }
                                  },
                                ),
                                SizedBox(height: verticalSpacing),

                                // Campo Monto Total Presupuestado (Manual)
                                TextFormField(
                                  controller: _totalBudgetController,
                                  decoration: InputDecoration(
                                    labelText: 'Monto Total Presupuestado',
                                    prefixIcon: Icon(Icons.attach_money),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isMobile ? 16 : 20,
                                    ),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, ingresa el monto total presupuestado';
                                    }
                                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                                      return 'Por favor, ingresa un monto válido (>= 0)';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: verticalSpacing * 1.5),

                            // Budget Breakdown Section
                            _buildFormSection(
                              context: context,
                              isMobile: isMobile,
                              title: 'Ajustar Proporciones',
                              subtitle: 'La suma debe ser 100%',
                              children: [
                                // Campo editable para Necesidades (50%)
                                _buildResponsivePercentageField(
                                  isMobile: isMobile,
                                  labelText: 'Necesidades',
                                  controller: _needsPercentageController,
                                  calculatedAmount: _currentTotalBudget * (_currentNeedsPercentage / 100.0),
                                  icon: Icons.home,
                                  color: Colors.blue,
                                ),

                                SizedBox(height: isMobile ? 12 : 16),

                                // Campo editable para Deseos (30%)
                                _buildResponsivePercentageField(
                                  isMobile: isMobile,
                                  labelText: 'Deseos',
                                  controller: _wantsPercentageController,
                                  calculatedAmount: _currentTotalBudget * (_currentWantsPercentage / 100.0),
                                  icon: Icons.shopping_bag,
                                  color: Colors.orange,
                                ),

                                SizedBox(height: isMobile ? 12 : 16),

                                // Campo editable para Ahorros (20%)
                                _buildResponsivePercentageField(
                                  isMobile: isMobile,
                                  labelText: 'Ahorros',
                                  controller: _savingsPercentageController,
                                  calculatedAmount: _currentTotalBudget * (_currentSavingsPercentage / 100.0),
                                  icon: Icons.savings,
                                  color: Colors.green,
                                ),
                              ],
                            ),

                            SizedBox(height: verticalSpacing * 2),

                            // Botón Guardar Presupuesto
                            _buildResponsiveSaveButton(
                              context: context,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    ); // <- Cierre de Scaffold
  }
}
