// lib/screens/movements/add_movement_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importar los modelos
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/category.dart';
import 'package:mis_finanza/models/debt.dart';
import '../../models/recurring_payment.dart';
// Eliminar importación de PaymentMethod si no se usa en la UI
// import 'package:mis_finanza/models/payment_method.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull
import '../../services/recurring_payment_service.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';

// Clase helper para unificar cuentas y deudas en el dropdown de destino de pagos
class PaymentDestination {
  final String id;
  final String name;
  final String type;
  final bool isAccount;
  final Account? account;
  final Debt? debt;

  PaymentDestination.fromAccount(Account account)
      : id = account.id!,
        name = account.name,
        type = 'Tarjeta de Crédito',
        isAccount = true,
        account = account,
        debt = null;

  PaymentDestination.fromDebt(Debt debt)
      : id = debt.id!,
        name = debt.description,
        type = 'Deuda',
        isAccount = false,
        account = null,
        debt = debt;

  @override
  String toString() => '$name ($type)';
}

class AddMovementScreen extends StatefulWidget {
  const AddMovementScreen({super.key});

  @override
  _AddMovementScreenState createState() => _AddMovementScreenState();
}

class _AddMovementScreenState extends State<AddMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Controladores para los campos del formulario
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  // Listas para los Dropdowns (se cargarán desde Firestore)
  List<Account> _accounts = [];
  List<Category> _categories = []; // Ahora cargamos todas las categorías
  List<Debt> _debts = [];
  // Eliminar lista de métodos de pago
  // List<PaymentMethod> _paymentMethods = [];

  // Valores seleccionados para Dropdowns
  Account? _selectedAccount; // Cuenta de origen (o destino para ingresos)
  Account? _selectedDestinationAccount; // Cuenta de destino para transferencias/pagos
  PaymentDestination? _selectedPaymentDestination; // Destino para pagos (puede ser cuenta o deuda)
  Category? _selectedCategory;
  // Eliminar valor seleccionado de método de pago
  // PaymentMethod? _selectedPaymentMethod;
  // Estado para el tipo de movimiento seleccionado
  String _selectedMovementType = 'expense'; // Valor por defecto
  final List<String> _movementTypes = ['expense', 'income', 'transfer', 'payment'];

  // Helper methods for modern UI consistency
  IconData _getMovementTypeIcon(String type) {
    switch (type) {
      case 'expense':
        return Icons.remove_circle_outline;
      case 'income':
        return Icons.add_circle_outline;
      case 'transfer':
        return Icons.swap_horiz;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.sync;
    }
  }

  Color _getMovementTypeColor(String type) {
    switch (type) {
      case 'expense':
        return Colors.red.shade400;
      case 'income':
        return Colors.green.shade500;
      case 'transfer':
        return Colors.blue.shade400;
      case 'payment':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // Para pagos recurrentes
  final RecurringPaymentService _recurringPaymentService = RecurringPaymentService();
  List<RecurringPayment> _recurringPayments = [];
  RecurringPayment? _selectedRecurringPayment;

  // Valor seleccionado para la fecha y hora
  DateTime _selectedDateTime = DateTime.now();

  bool _isLoading = true; // Indicador de carga inicial
  bool _isSaving = false; // Indicador de carga al guardar

  // --- Helpers para mostrar/ocultar campos según el tipo de movimiento ---
  bool get _isExpense => _selectedMovementType == 'expense';
  bool get _isIncome => _selectedMovementType == 'income';
  bool get _isTransfer => _selectedMovementType == 'transfer';
  bool get _isPayment => _selectedMovementType == 'payment';

  @override
  void initState() {
    super.initState();
    _loadData(); // Cargar datos para los dropdowns
    _loadRecurringPayments();
    
    // Ejecutar después de que el widget esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar si hay argumentos de voz y procesarlos
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _processVoiceData(args);
      }
    });
  }
  
  // Variable para almacenar los datos de voz hasta que se carguen las categorías
  Map<String, dynamic>? _pendingVoiceData;
  
  // Procesar los datos de voz recibidos como argumentos
  void _processVoiceData(Map<String, dynamic> voiceData) {
    // Si todavía estamos cargando datos, guardar los datos de voz para procesarlos después
    if (_isLoading) {
      _pendingVoiceData = voiceData;
      return;
    }
    
    // Establecer el tipo de movimiento si está disponible
    if (voiceData['type'] != null) {
      setState(() {
        _selectedMovementType = voiceData['type'];
      });
    }
    
    // Establecer el monto si está disponible
    if (voiceData['amount'] != null) {
      // Asegurarse de que el monto sea un número válido
      var amount = voiceData['amount'];
      if (amount is double) {
        // Si ya es un double, usarlo directamente
        _amountController.text = amount.toString();
        //print('Monto procesado como double: $amount');
      } else if (amount is int) {
        // Si es un entero, convertirlo a double
        _amountController.text = amount.toDouble().toString();
        //print('Monto procesado como int: $amount');
      } else if (amount is String) {
        // Si es una cadena, intentar convertirla a double
        double? parsedAmount = double.tryParse(amount);
        if (parsedAmount != null) {
          _amountController.text = parsedAmount.toString();
          //print('Monto procesado desde string: $parsedAmount');
        } else {
          //print('No se pudo convertir el monto "$amount" a número');
        }
      } else {
        // Para cualquier otro tipo, intentar convertir a string y luego a double
        String amountStr = amount.toString();
        double? parsedAmount = double.tryParse(amountStr);
        if (parsedAmount != null) {
          _amountController.text = parsedAmount.toString();
          //print('Monto procesado desde otro tipo: $parsedAmount');
        } else {
          //print('No se pudo procesar el monto: $amount (${amount.runtimeType})');
        }
      }
    }
    
    // Establecer la descripción si está disponible
    if (voiceData['description'] != null) {
      _descriptionController.text = voiceData['description'];
    }
    
    // Establecer la categoría si está disponible y existe en la lista
    if (voiceData['categoryId'] != null && _categories.isNotEmpty) {
      final categoryId = voiceData['categoryId'];
      final category = _categories.firstWhereOrNull((cat) => cat.id == categoryId);
      if (category != null) {
        setState(() {
          _selectedCategory = category;
        });
      }
    } else if (voiceData['category'] != null && _categories.isNotEmpty) {
      // Intentar encontrar la categoría por nombre si no tenemos el ID
      final categoryName = voiceData['category'];
      final category = _categories.firstWhereOrNull(
        (cat) => cat.name.toLowerCase() == categoryName.toString().toLowerCase()
      );
      if (category != null) {
        setState(() {
          _selectedCategory = category;
        });
      }
    }
    
    // Mostrar un mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Datos de voz cargados correctamente')),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Carga las listas para los dropdowns
  Future<void> _loadData() async {
    // --- CORREGIDO: Acceso a currentUser ---
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: Usuario no autenticado.')),
       );
       setState(() => _isLoading = false);
       return;
    }
    // ------------------------------------

    setState(() {
      _isLoading = true;
    });    try {
      // Cargar listas para Dropdowns
      _accounts = await AccountService.getAccounts().first;
      _categories = await CategoryService.getCategories().first;
      _debts = await DebtService.getDebts().first; // Cargar deudas
      // Eliminar carga de métodos de pago
      // _paymentMethods = await _firestoreService.getPaymentMethods().first;

      // Seleccionar automáticamente la primera cuenta disponible como valor predeterminado
      if (_accounts.isNotEmpty) {
        setState(() {
          _selectedAccount = _accounts.first;
        });
      }

      // Inicializar fecha y hora actuales
      _selectedDateTime = DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDateTime);
      _timeController.text = DateFormat('HH:mm').format(_selectedDateTime);


    } catch (e) {
      //print('Error loading data for AddMovementScreen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      // Procesar datos de voz pendientes después de cargar los datos
      if (_pendingVoiceData != null) {
        _processVoiceData(_pendingVoiceData!);
        _pendingVoiceData = null; // Limpiar los datos pendientes
      }
    }
  }

  Future<void> _loadRecurringPayments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _recurringPaymentService.getRecurringPayments().first.then((payments) {
      setState(() {
        _recurringPayments = payments;
      });
    });
  }

  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final newDateTime = DateTime(picked.year, picked.month, picked.day, _selectedDateTime.hour, _selectedDateTime.minute);
      setState(() {
        _selectedDateTime = newDateTime;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDateTime);
      });
    }
  }

  // Función para mostrar el selector de hora
   Future<void> _selectTime(BuildContext context) async {
     final TimeOfDay? picked = await showTimePicker(
       context: context,
       initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
     );
     if (picked != null) {
       final newDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, picked.hour, picked.minute);
       setState(() {
         _selectedDateTime = newDateTime;
         _timeController.text = DateFormat('HH:mm').format(_selectedDateTime);
       });
     }
   }

  // Función para guardar el movimiento en Firestore
  Future<void> _saveMovement() async {
    // Validar el formulario
    if (_formKey.currentState!.validate()) {
       // --- CORREGIDO: Acceso a currentUser ---
       final user = FirebaseAuth.instance.currentUser;
       if (user == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: Usuario no autenticado.')),
         );
         return;
       }
       // ------------------------------------


       // Validar que los dropdowns requeridos estén seleccionados según el tipo de movimiento
       if (_selectedAccount == null) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona una Cuenta de Origen/Destino.')));
           return;
       }
       if ((_isExpense || _isIncome) && _selectedCategory == null) { // Categoría requerida para gasto e ingreso
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona una Categoría.')));
           return;
       }
       // Eliminar validación de método de pago
        // if (_isExpense && _selectedPaymentMethod == null) { // Método de pago requerido SOLO para gasto
        //    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona un Método de Pago.')));
        //    return;
       // }
       if ((_isTransfer || _isPayment) && _selectedDestinationAccount == null) { // Cuenta de destino requerida para transferencia y pago
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona una Cuenta de Destino.')));
            return;
       }
        if (_isTransfer && _selectedAccount?.id == _selectedDestinationAccount?.id) { // Cuentas diferentes para transferencia
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La Cuenta de Origen y Destino no pueden ser la misma para una transferencia.')));
            return;
       }
       if (_isPayment && (_selectedDestinationAccount == null || !_selectedDestinationAccount!.isCreditCard)) { // Cuenta de destino para pago debe ser CC
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La Cuenta de Destino para un pago debe ser una Tarjeta de Crédito.')));
            return;
       }
        if (_isPayment && _selectedAccount?.isCreditCard == true) { // Cuenta de origen para pago NO debe ser CC
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La Cuenta de Origen para un pago no puede ser una Tarjeta de Crédito.')));
            return;
       }


      setState(() {
        _isSaving = true;
      });

      try {
        // Crear el objeto Movement a partir de los datos del formulario
        final newMovement = Movement(
          id: null, // Firestore generará el ID
          userId: user.uid, // --- CORREGIDO: Usar user.uid ---
          accountId: _selectedAccount!.id!, // ID de la cuenta de origen (o destino para ingresos)
          destinationAccountId: (_isTransfer || _isPayment) ? _selectedDestinationAccount!.id : null, // Asignar destinationAccountId solo si aplica
          categoryId: (_isExpense || _isIncome) ? (_selectedCategory?.id ?? '') : '', // ID de la categoría (vacío si no aplica)
          paymentMethodId: null, // <-- Asignar null o vacío, ya no se selecciona en la UI
          amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          dateTime: _selectedDateTime,
          type: _selectedMovementType, // Asignar el tipo de movimiento seleccionado
          // --- NUEVO: Proporcionar el campo currency ---
          currency: _selectedAccount!.currency, // Asumimos la moneda de la cuenta de origen
          // ------------------------------------------
        );

        // Llamar al servicio para guardar el movimiento
         await _firestoreService.addMovementAndUpdateAccount(newMovement);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Movimiento ($_selectedMovementType) guardado con éxito.')),
        );

        Navigator.pop(context); // Navegar de regreso

      } catch (e) {
        //print('Error al guardar movimiento: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el movimiento: ${e.toString()}')),
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

  // Helper para obtener el texto a mostrar para el tipo de movimiento
  String _getMovementTypeText(String type) {
      switch (type) {
          case 'expense': return 'Gasto';
          case 'income': return 'Ingreso';
          case 'transfer': return 'Transferencia';
          case 'payment': return 'Pago';
          default: return type;
      }
  }

  void _onRecurringPaymentSelected(RecurringPayment? payment) {
    if (payment == null) return;
    setState(() {
      _selectedRecurringPayment = payment;
      _amountController.text = payment.amount.toString();
      _descriptionController.text = payment.description;
      // Buscar y seleccionar la categoría y cuenta asociada
      _selectedCategory = _categories.firstWhereOrNull((cat) => cat.id == payment.categoryId);
      _selectedAccount = _accounts.firstWhereOrNull((acc) => acc.id == payment.accountId);
      // Notas
      _notesController.text = payment.notes ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Datos del pago recurrente cargados')),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getMovementTypeColor(_selectedMovementType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getMovementTypeColor(_selectedMovementType).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                _getMovementTypeIcon(_selectedMovementType),
                color: _getMovementTypeColor(_selectedMovementType),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo Movimiento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  _getMovementTypeText(_selectedMovementType),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getMovementTypeColor(_selectedMovementType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading || _isSaving
          ? _buildLoadingState()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  _buildHeaderSection(),
                  // Form Section
                  _buildFormSection(),
                ],
              ),
            ),
    );
  }

  // Modern loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isSaving ? 'Guardando movimiento...' : 'Cargando datos...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Header section with movement type selector
  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tipo de Movimiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tipo de Movimiento con diseño mejorado
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Seleccionar Tipo',
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
                    color: _getMovementTypeColor(_selectedMovementType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMovementTypeIcon(_selectedMovementType),
                    size: 20,
                    color: _getMovementTypeColor(_selectedMovementType),
                  ),
                ),
              ),
              value: _selectedMovementType,
              items: _movementTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getMovementTypeColor(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getMovementTypeIcon(type),
                          size: 16,
                          color: _getMovementTypeColor(type),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getMovementTypeText(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMovementType = newValue;
                    _selectedCategory = null;
                    _selectedAccount = null;
                    _selectedDestinationAccount = null;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Form section with all fields
  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Selección de Pago Recurrente
            if (_recurringPayments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonFormField<RecurringPayment>(
                      decoration: InputDecoration(
                        labelText: 'Usar pago recurrente',
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
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.repeat,
                            size: 20,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ),
                      value: _selectedRecurringPayment,
                      items: [
                        DropdownMenuItem<RecurringPayment>(
                          value: null,
                          child: Text('Ninguno'),
                        ),
                        ..._recurringPayments.map((p) => DropdownMenuItem<RecurringPayment>(
                          value: p,
                          child: Text(p.description),
                        )),
                      ],
                      onChanged: (value) {
                        _onRecurringPaymentSelected(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Campo Monto
            _buildAmountField(),
            const SizedBox(height: 16),

            // Campo Descripción
            _buildDescriptionField(),
            const SizedBox(height: 16),

            // Cuenta de Origen/Destino
            _buildAccountField(),
            const SizedBox(height: 16),

            // Cuenta de Destino (solo para Transferencia y Pago)
            if (_isTransfer || _isPayment) ...[
              _buildDestinationAccountField(),
              const SizedBox(height: 16),
            ],

            // Categoría (solo para Gasto e Ingreso)
            if (_isExpense || _isIncome) ...[
              _buildCategoryField(),
              const SizedBox(height: 16),
            ],

            // Campo Fecha
            _buildDateField(),
            const SizedBox(height: 16),

            // Campo Hora
            _buildTimeField(),
            const SizedBox(height: 16),

            // Campo Notas (Opcional)
            _buildNotesField(),
            const SizedBox(height: 24),

            // Botón Guardar Movimiento
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // Campos de formulario modernos
  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: 'Descripción',
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, ingresa una descripción';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Monto',
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.attach_money,
              size: 20,
              color: Colors.green.shade600,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, ingresa un monto';
          }
          if (double.tryParse(value) == null || double.parse(value) <= 0) {
            return 'Por favor, ingresa un monto válido mayor a 0';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAccountField() {
    String label = _selectedMovementType == 'income' ? 'Cuenta Destino' : 'Cuenta Origen';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<Account>(
        decoration: InputDecoration(
          labelText: label,
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
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        value: _selectedAccount,
        items: _accounts.map((Account account) {
          return DropdownMenuItem<Account>(
            value: account,
            child: Text('${account.name} (${account.type})'),
          );
        }).toList(),
        onChanged: (Account? newValue) {
          setState(() {
            _selectedAccount = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Por favor, selecciona una cuenta';
          }
          return null;
        },
      ),
    );
  }
  Widget _buildDestinationAccountField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<Account>(
        decoration: InputDecoration(
          labelText: 'Cuenta Destino',
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance,
              size: 20,
              color: Colors.blue.shade600,
            ),
          ),
        ),
        value: _selectedDestinationAccount,
        items: _accounts
            .where((account) {
              // Excluir la cuenta seleccionada como origen
              if (account.id == _selectedAccount?.id) return false;
              
              // Si es un pago, solo mostrar tarjetas de crédito
              if (_isPayment) {
                return account.isCreditCard;
              }
              
              // Para transferencias, mostrar todas las otras cuentas
              return true;
            })
            .map((Account account) {
          return DropdownMenuItem<Account>(
            value: account,
            child: Text('${account.name} (${account.type})'),
          );
        }).toList(),
        onChanged: (Account? newValue) {
          setState(() {
            _selectedDestinationAccount = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Por favor, selecciona una cuenta destino';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    final filteredCategories = _categories.where((category) => 
        category.type == _selectedMovementType).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<Category>(
        decoration: InputDecoration(
          labelText: 'Categoría',
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
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              size: 20,
              color: Colors.purple.shade600,
            ),
          ),
        ),
        value: _selectedCategory,
        items: filteredCategories.map((Category category) {
          return DropdownMenuItem<Category>(
            value: category,
            child: Text(category.name),
          );
        }).toList(),
        onChanged: (Category? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Por favor, selecciona una categoría';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Fecha',
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
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.orange.shade600,
            ),
          ),
        ),
        onTap: () => _selectDate(context),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, selecciona una fecha';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTimeField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _timeController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Hora',
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
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              size: 20,
              color: Colors.indigo.shade600,
            ),
          ),
        ),
        onTap: () => _selectTime(context),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, selecciona una hora';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Notas (Opcional)',
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.note_alt,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading || _isSaving ? null : _saveMovement,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Guardando...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Guardar Movimiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}*/