// lib/screens/movements/edit_movement_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importar los modelos
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/category.dart';
// Eliminar importación de PaymentMethod si no se usa en la UI
// import 'package:mis_finanza/models/payment_method.dart';
import 'package:mis_finanza/services/firestore_service/index.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull


class EditMovementScreen extends StatefulWidget {
  final Movement movement; // Recibe el movimiento a editar

  const EditMovementScreen({super.key, required this.movement});

  @override
  _EditMovementScreenState createState() => _EditMovementScreenState();
}

class _EditMovementScreenState extends State<EditMovementScreen> {
  final _formKey = GlobalKey<FormState>();
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
  // Eliminar lista de métodos de pago
  // List<PaymentMethod> _paymentMethods = [];

  // Valores seleccionados para Dropdowns (se pre-seleccionarán con los datos del movimiento)
  Account? _selectedAccount; // Cuenta de origen (o destino para ingresos)
  Account? _selectedDestinationAccount; // Cuenta de destino
  Category? _selectedCategory;
  // Eliminar valor seleccionado de método de pago
  // PaymentMethod? _selectedPaymentMethod;


  // Valor seleccionado para la fecha y hora
  DateTime _selectedDateTime = DateTime.now();

  bool _isLoading = true; // Indicador de carga inicial
  bool _isSaving = false; // Indicador de carga al guardar

  // --- Helpers para mostrar/ocultar campos según el tipo del movimiento ORIGINAL ---
  bool get _isExpense => widget.movement.type == 'expense';
  bool get _isIncome => widget.movement.type == 'income';
  bool get _isTransfer => widget.movement.type == 'transfer';
  bool get _isPayment => widget.movement.type == 'payment';


  @override
  void initState() {
    super.initState();
    _loadData(); // Cargar datos para los dropdowns y pre-llenar formulario
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

  // Carga las listas para los dropdowns y pre-llena el formulario con los datos del movimiento
  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: Usuario no autenticado.')),
       );
       setState(() => _isLoading = false);
       return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // Usar servicios especializados para obtener cuentas y categorías
      _accounts = await AccountService.getAccounts().first;
      _categories = await CategoryService.getCategories().first; // Cargar TODAS las categorías
      // Eliminar carga de métodos de pago
      // _paymentMethods = await _firestoreService.getPaymentMethods().first;

      // --- Pre-llenar formulario con los datos del movimiento ---
      _amountController.text = widget.movement.amount.toString();
      _descriptionController.text = widget.movement.description;
      _notesController.text = widget.movement.notes ?? '';
      _selectedDateTime = widget.movement.dateTime; // Asignar la fecha/hora del movimiento

      // Formatear y mostrar fecha y hora en los TextFields
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDateTime);
      _timeController.text = DateFormat('HH:mm').format(_selectedDateTime); // Formato 24 horas

      // --- Pre-seleccionar los valores en los Dropdowns usando firstWhereOrNull ---
      _selectedAccount = _accounts.firstWhereOrNull(
        (account) => account.id == widget.movement.accountId,
      );

       // Pre-seleccionar Cuenta de Destino si aplica
       if (_isTransfer || _isPayment) {
           _selectedDestinationAccount = _accounts.firstWhereOrNull(
             (account) => account.id == widget.movement.destinationAccountId,
           );
       }

       // Pre-seleccionar Categoría solo si aplica al tipo de movimiento y existe
       if (_isExpense || _isIncome) {
           _selectedCategory = _categories.firstWhereOrNull(
             (category) => category.id == widget.movement.categoryId,
           );
       }

       // Eliminar pre-selección de método de pago
       // if (_isExpense) { // SOLO GASTO
       //     _selectedPaymentMethod = _paymentMethods.firstWhereOrNull(
       //       (method) => method.id == widget.movement.paymentMethodId,
       //     );
       // }


        // Validar si se encontraron los elementos relacionados requeridos
        bool requiredDropdownsFound = true;
        String missing = '';

        if (_selectedAccount == null) {
          requiredDropdownsFound = false;
          missing += 'Cuenta de Origen/Destino, ';
        }
        if ((_isTransfer || _isPayment) && _selectedDestinationAccount == null) { // Cuenta de destino requerida
            requiredDropdownsFound = false;
            missing += 'Cuenta de Destino, ';
       }
        if ((_isExpense || _isIncome) && _selectedCategory == null) { // Categoría requerida
           requiredDropdownsFound = false;
           missing += 'Categoría, ';
       }
        // Eliminar validación de método de pago
        // if (_isExpense && _selectedPaymentMethod == null) { // Método de pago requerido (SOLO GASTO)
        //    requiredDropdownsFound = false;
        //    missing += 'Método de Pago, ';
       // }


        if (!requiredDropdownsFound) {
            if (missing.endsWith(', ')) missing = missing.substring(0, missing.length - 2); // Quitar coma final

             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Advertencia: No se encontraron los datos relacionados para este movimiento: $missing. Por favor, actualiza la información de las cuentas, categorías o métodos de pago si es necesario.')),
             );
             // Si no se encontraron, los Dropdowns mostrarán null y el formulario no validará para guardar.
        }
    } catch (e) {
      //print('Error loading data for EditMovementScreen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  // Función para actualizar el movimiento en Firestore
  Future<void> _updateMovement() async {
    // Validar el formulario y asegurar que los dropdowns requeridos tienen valores seleccionados
    if (_formKey.currentState!.validate()) {
       // --- CORREGIDO: Acceso a currentUser ---
       final user = FirebaseAuth.instance.currentUser;
       if (user == null || widget.movement.id == null) { // Usa widget.movement.id
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: No se puede actualizar el movimiento (usuario o ID inválido).')),
         );
         return;
       }
       // ------------------------------------


        // Validar que los dropdowns requeridos estén seleccionados según el tipo de movimiento original
       if (_selectedAccount == null) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona una Cuenta de Origen/Destino.')));
           return;
       }
        if ((_isTransfer || _isPayment) && _selectedDestinationAccount == null) { // Cuenta de destino requerida
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona una Cuenta de Destino.')));
            return;
       }
       if ((_isExpense || _isIncome) && _selectedCategory == null) { // Categoría requerida
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona una Categoría.')));
           return;
       }
        // Eliminar validación de método de pago
        // if (_isExpense && _selectedPaymentMethod == null) { // Método de pago requerido (SOLO GASTO)
        //    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, selecciona un Método de Pago.')));
        //    return;
       // }
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
        // Crear el objeto Movement actualizado
        final updatedMovement = Movement(
          id: widget.movement.id, // MANTENER el ID existente del movimiento original
          userId: user.uid, // --- CORREGIDO: Usar user.uid ---
          accountId: _selectedAccount!.id!, // Usar el ID de la cuenta de origen seleccionada
          destinationAccountId: (_isTransfer || _isPayment) ? _selectedDestinationAccount!.id : null, // Asignar destinationAccountId solo si aplica
          categoryId: (_isExpense || _isIncome) ? (_selectedCategory?.id ?? '') : '', // ID de la categoría seleccionada (vacío si no aplica)
          paymentMethodId: null, // <-- Asignar null o vacío
          amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          dateTime: _selectedDateTime, // Usar la fecha y hora seleccionadas
          type: widget.movement.type, // El tipo de movimiento NO se edita aquí, se mantiene el original
          // --- NUEVO: Proporcionar el campo currency ---
          currency: _selectedAccount!.currency, // Asumimos la moneda de la cuenta de origen
          // ------------------------------------------
        );

        // Llamar al servicio para actualizar con transacción
         await MovementService.updateMovementAndAccount(updatedMovement);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Movimiento (${widget.movement.type}) actualizado con éxito.')),
        );

        Navigator.pop(context); // Navegar de regreso

      } catch (e) {
        //print('Error al actualizar movimiento: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el movimiento: ${e.toString()}')),
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
                color: _getMovementTypeColor(widget.movement.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getMovementTypeColor(widget.movement.type).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                _getMovementTypeIcon(widget.movement.type),
                color: _getMovementTypeColor(widget.movement.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Movimiento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  _getMovementTypeText(widget.movement.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getMovementTypeColor(widget.movement.type),
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
                  // Header Section - Movement Information
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
            _isSaving ? 'Actualizando movimiento...' : 'Cargando datos...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Header section with movement information
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
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Información del Movimiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Movement Type Field (Read-only)
          Container(
            decoration: BoxDecoration(
              color: _getMovementTypeColor(widget.movement.type).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getMovementTypeColor(widget.movement.type).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Tipo de Movimiento',
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
                    color: _getMovementTypeColor(widget.movement.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMovementTypeIcon(widget.movement.type),
                    size: 20,
                    color: _getMovementTypeColor(widget.movement.type),
                  ),
                ),
              ),
              initialValue: _getMovementTypeText(widget.movement.type),
              readOnly: true,
              style: TextStyle(
                color: _getMovementTypeColor(widget.movement.type),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form section with all editable fields
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
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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

            // Botón Actualizar Movimiento
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  // Modern form field builders
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            return 'Por favor, ingresa el monto';
          }
          if (double.tryParse(value) == null || double.parse(value) <= 0) {
            return 'Por favor, ingresa un monto válido (> 0)';
          }
          return null;
        },
      ),
    );
  }

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

  Widget _buildAccountField() {
    String label = _isIncome ? 'Cuenta (Destino)' : 'Cuenta (Origen)';
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
            child: Text('${account.name} (${account.type} - ${account.currency})'),
          );
        }).toList(),
        onChanged: (newValue) {
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
          labelText: 'Cuenta (Destino)',
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
        ),        value: _selectedDestinationAccount,
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
            child: Text('${account.name} (${account.type} - ${account.currency})'),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedDestinationAccount = newValue;
          });
        },
        validator: (value) {
          if ((_isTransfer || _isPayment) && value == null) {
            return 'Por favor, selecciona una cuenta de destino';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryField() {
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
        items: _categories.where((cat) => cat.type == widget.movement.type).map((Category category) {
          return DropdownMenuItem<Category>(
            value: category,
            child: Text(category.name),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) {
          if ((_isExpense || _isIncome) && value == null) {
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

  Widget _buildUpdateButton() {
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
        onPressed: _isLoading || _isSaving ? null : _updateMovement,
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
                  const Text('Actualizando...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.update, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Actualizar Movimiento',
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
}
*/