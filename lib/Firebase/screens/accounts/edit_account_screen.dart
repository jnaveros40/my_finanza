// lib/screens/edit_account_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/account.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:intl/intl.dart'; // Para formatear fechas y moneda


class EditAccountScreen extends StatefulWidget {
  final Account account; // Recibe la cuenta a editar

  const EditAccountScreen({super.key, required this.account});

  @override
  _EditAccountScreenState createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Controladores pre-llenados con los datos de la cuenta que recibimos
  final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _initialBalanceController = TextEditingController(); // Ya no necesitamos este campo en edición
  final TextEditingController _displayBalanceController = TextEditingController(); // <-- NUEVO controlador para mostrar Saldo Actual / Cupo Disponible (READ-ONLY)
  final TextEditingController _yieldRateController = TextEditingController();
  final TextEditingController _savingsTargetAmountController = TextEditingController();
  final TextEditingController _savingsTargetDateController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();  // NUEVOS CONTROLADORES PARA TARJETAS DE CRÉDITO
  final TextEditingController _cutOffDayController = TextEditingController();
  final TextEditingController _paymentDueDayController = TextEditingController();
  
  // NUEVOS CONTROLADORES PARA CAMPOS PERSONALIZABLES
  final TextEditingController _customIdController = TextEditingController();
  final TextEditingController _customKeyController = TextEditingController();


  // Valores seleccionados pre-llenados (el tipo no será editable, solo se muestra)
  // String _selectedAccountType = 'Cuenta de ahorro'; // Ya no necesitamos esto si el tipo no es editable
  String _selectedCurrency = 'COP'; // Valor por defecto, se sobrescribirá

   // Lista de opciones de moneda (el tipo de cuenta no se edita aquí)
  final List<String> _currencies = ['COP', 'USD', 'EUR', 'GBP', 'JPY'];


  DateTime? _selectedSavingsTargetDate;

  bool _isLoading = false;

  // --- Helper para saber si la cuenta que editamos es Tarjeta de Crédito ---
  bool get _isCreditCard => widget.account.isCreditCard;

  // Helper methods for modern UI
  IconData _getAccountTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cuenta de ahorro':
        return Icons.savings;
      case 'tarjeta de credito':
        return Icons.credit_card;
      case 'renta fija':
        return Icons.trending_up;
      case 'renta variable':
        return Icons.show_chart;
      case 'efectivo':
        return Icons.account_balance_wallet;
      case 'inversiones':
        return Icons.business_center;
      case 'deuda':
        return Icons.money_off;
      default:
        return Icons.account_balance;
    }
  }

  Color _getAccountTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cuenta de ahorro':
        return Colors.green;
      case 'tarjeta de credito':
        return Colors.blue;
      case 'renta fija':
        return Colors.teal;
      case 'renta variable':
        return Colors.orange;
      case 'efectivo':
        return Colors.purple;
      case 'inversiones':
        return Colors.indigo;
      case 'deuda':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    // --- Pre-llenar controladores y variables con los datos de widget.account ---
    _nameController.text = widget.account.name;

    // --- Pre-llenar campos de saldo o cupo según si es Tarjeta de Crédito ---
    if (_isCreditCard) {
       // Para Tarjetas de Crédito:
       // - El campo de displayBalance muestra el Cupo Disponible (Account.currentBalance en objeto)
       _displayBalanceController.text = NumberFormat.currency(
          locale: 'en_US', // O la locale que prefieras para formato de número
          symbol: _getCurrencySymbol(widget.account.currency),
          decimalDigits: 2,
       ).format(widget.account.currentBalance); // currentBalance del objeto es Cupo Disponible

       // - El campo creditLimitController muestra el Cupo Total
       _creditLimitController.text = widget.account.creditLimit.toString();

       // Pre-llenar los nuevos campos si existen
       if (widget.account.cutOffDay != null) {
         _cutOffDayController.text = widget.account.cutOffDay.toString();
       }
       if (widget.account.paymentDueDay != null) {
         _paymentDueDayController.text = widget.account.paymentDueDay.toString();
       }

    } else {
       // Para otras cuentas:
       // - El campo de displayBalance muestra el Saldo Actual real
       _displayBalanceController.text = NumberFormat.currency(
          locale: 'en_US',
          symbol: _getCurrencySymbol(widget.account.currency),
          decimalDigits: 2,
       ).format(widget.account.currentBalance); // currentBalance del objeto es Saldo Real

       // Los campos relacionados con CC (creditLimit) no aplican y no se pre-llenan.
    }

    // Pre-llenar otros campos existentes
    // _initialBalanceController.text = widget.account.initialBalance.toString(); // Ya no editable aquí
    // _currentBalanceController.text = widget.account.currentBalance.toString(); // Reemplazado por _displayBalanceController
    _yieldRateController.text = widget.account.yieldRate?.toString() ?? '';
    _savingsTargetAmountController.text = widget.account.savingsTargetAmount?.toString() ?? '';

    // Pre-llenar tipo y moneda seleccionados (el tipo se mostrará como read-only)
    // _selectedAccountType = _accountTypes.contains(widget.account.type) ? widget.account.type : _accountTypes.first; // No es necesario si no hay Dropdown
    _selectedCurrency = _currencies.contains(widget.account.currency) ? widget.account.currency : _currencies.first;    if (widget.account.savingsTargetDate != null) {
      _selectedSavingsTargetDate = widget.account.savingsTargetDate;
      _savingsTargetDateController.text = DateFormat('yyyy-MM-dd').format(_selectedSavingsTargetDate!);
    }
    
    // --- Pre-llenar nuevos campos personalizables ---
    _customIdController.text = widget.account.customId ?? '';
    _customKeyController.text = widget.account.customKey ?? '';
    // ---------------------------------------------
  }


  @override
  void dispose() {
    _nameController.dispose();
    // _initialBalanceController.dispose(); // Ya no necesario
    // _currentBalanceController.dispose(); // Ya no necesario
    _displayBalanceController.dispose(); // <-- Disponer del nuevo controlador de display
    _yieldRateController.dispose();
    _savingsTargetAmountController.dispose();
    _savingsTargetDateController.dispose();    _creditLimitController.dispose();
    _cutOffDayController.dispose();
    _paymentDueDayController.dispose();
    _customIdController.dispose();
    _customKeyController.dispose();
    super.dispose();
  }

  // --- Helper para obtener el símbolo de moneda (copiado de AccountsScreen/ExpensesScreen) ---
   String _getCurrencySymbol(String currencyCode) {
     switch (currencyCode) {
       case 'COP': return '\$';
       case 'USD': return '\$';
       case 'EUR': return '€';
       case 'GBP': return '£';
       case 'JPY': return '¥';
       default: return currencyCode;
     }
   }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedSavingsTargetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedSavingsTargetDate) {
      setState(() {
        _selectedSavingsTargetDate = picked;
        _savingsTargetDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Función para actualizar la cuenta en Firestore
  Future<void> _updateAccount() async {
    if (_formKey.currentState!.validate()) {
       if (currentUser == null || widget.account.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se puede actualizar la cuenta (usuario o ID inválido).')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Obtener valores de los campos editables
        double? yieldRate = double.tryParse(_yieldRateController.text.trim());
        double? savingsTargetAmount = double.tryParse(_savingsTargetAmountController.text.trim());
        double editedCreditLimit = _isCreditCard ? (double.tryParse(_creditLimitController.text.trim()) ?? 0.0) : 0.0;        // NUEVOS CAMPOS PARA TARJETAS DE CRÉDITO
        int? cutOffDay = _isCreditCard ? int.tryParse(_cutOffDayController.text.trim()) : null;
        int? paymentDueDay = _isCreditCard ? int.tryParse(_paymentDueDayController.text.trim()) : null;
        
        // NUEVOS CAMPOS PERSONALIZABLES
        String? customId = _customIdController.text.trim().isNotEmpty ? _customIdController.text.trim() : null;
        String? customKey = _customKeyController.text.trim().isNotEmpty ? _customKeyController.text.trim() : null;


        // Crear el objeto Account actualizado usando copyWith para mantener otros campos
        final updatedAccount = widget.account.copyWith(
          id: widget.account.id,
          userId: currentUser!.uid,
          name: _nameController.text.trim(),
          // El tipo de cuenta NO se edita aquí
          // type: _selectedAccountType, // NO editar el tipo

          currency: _selectedCurrency,

          // Saldo Inicial no editable aquí
          // initialBalance: double.tryParse(_initialBalanceController.text.trim()) ?? 0.0,

          // --- Manejar currentBalance (Cupo Disponible) y campos de CC al actualizar ---
          // El currentBalance (saldo real o cupo disponible) NO se edita directamente aquí.
          // Si es Tarjeta de Crédito, el Cupo Disponible (currentBalance en objeto) se recalcula si se edita el Cupo Total.
          currentBalance: _isCreditCard
               ? editedCreditLimit - widget.account.currentStatementBalance // Nuevo Cupo Disponible = Nuevo Límite - Adeudado Actual
               : widget.account.currentBalance, // Mantener Saldo Actual si no es CC
          // -------------------------------------------------------------------------

          yieldRate: yieldRate,
          savingsTargetAmount: savingsTargetAmount,
          savingsTargetDate: _selectedSavingsTargetDate,
          // isArchived y order se mantienen con copyWith
          // --- Actualizar NUEVOS campos (para CC) ---
          // isCreditCard: se mantiene con copyWith
          creditLimit: editedCreditLimit, // Actualizar el Cupo Total si es CC (será 0 para no CC)          cutOffDay: cutOffDay,
          paymentDueDay: paymentDueDay,
          // currentStatementBalance: NO se edita aquí, se mantiene con copyWith
          // paymentDueDate: se mantiene con copyWith si lo añades
          // -----------------------------------------
          
          // --- Actualizar nuevos campos personalizables ---
          customId: customId,
          customKey: customKey,
          // -----------------------------------------------
        );


        // Llamar al servicio para guardar (actualizar) la cuenta
        await _firestoreService.saveAccount(updatedAccount); // saveAccount maneja creación y actualización

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cuenta actualizada con éxito.')),
        );

        // Navegar de regreso
        Navigator.pop(context);

      } catch (e) {
        //print('Error al actualizar cuenta: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la cuenta: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
       // Mostrar SnackBar si la validación falla
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Por favor, completa los campos requeridos.')),
         );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Cuenta',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Actualizando cuenta...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _getAccountTypeColor(widget.account.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _getAccountTypeIcon(widget.account.type),
                            size: 40,
                            color: _getAccountTypeColor(widget.account.type),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.account.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getAccountTypeColor(widget.account.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getAccountTypeColor(widget.account.type).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.account.type,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getAccountTypeColor(widget.account.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[                          // Enhanced name field
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nombre de la Cuenta',
                                hintText: 'Ej: Cuenta Principal Bancolombia',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingresa un nombre';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),                          // Account type display (read-only)
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Tipo de Cuenta',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getAccountTypeColor(widget.account.type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getAccountTypeIcon(widget.account.type),
                                    size: 20,
                                    color: _getAccountTypeColor(widget.account.type),
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              initialValue: widget.account.type,
                              readOnly: true,
                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                            ),
                          ),
                          const SizedBox(height: 20),                          // Current balance/available credit display (read-only)
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _displayBalanceController,
                              decoration: InputDecoration(
                                labelText: _isCreditCard ? 'Cupo Disponible' : 'Saldo Actual',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isCreditCard ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isCreditCard ? Icons.credit_card : Icons.account_balance_wallet,
                                    size: 20,
                                    color: _isCreditCard ? Colors.blue : Colors.green,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              readOnly: true,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isCreditCard ? Colors.blue : Colors.green,
                              ),
                              validator: (value) {
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),                          // Enhanced credit limit field (for credit cards only)
                          if (_isCreditCard) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _creditLimitController,
                                decoration: InputDecoration(
                                  labelText: 'Cupo Total',
                                  hintText: '0.00',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.credit_card,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (_isCreditCard && (value == null || value.isEmpty)) {
                                    return 'Por favor, ingresa el cupo total';
                                  }
                                  if (_isCreditCard && (double.tryParse(value!) == null || double.parse(value) < 0)) {
                                    return 'Por favor, ingresa un cupo válido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _cutOffDayController,
                                decoration: InputDecoration(
                                  labelText: 'Día de Corte (1-31)',
                                  hintText: 'Ej: 15',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_isCreditCard && (value == null || value.isEmpty)) {
                                    return 'Por favor, ingresa el día de corte';
                                  }
                                  final day = int.tryParse(value!);
                                  if (_isCreditCard && (day == null || day < 1 || day > 31)) {
                                    return 'Día de corte inválido';
                                  }
                                  return null;
                                },
                              ),                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _paymentDueDayController,
                                decoration: InputDecoration(
                                  labelText: 'Día de Pago (1-31)',
                                  hintText: 'Ej: 25',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.event_available,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_isCreditCard && (value == null || value.isEmpty)) {
                                    return 'Por favor, ingresa el día de pago';
                                  }
                                  final day = int.tryParse(value!);
                                  if (_isCreditCard && (day == null || day < 1 || day > 31)) {
                                    return 'Día de pago inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                     // Los campos de Saldo Inicial (initialBalance) ya no se muestran en edición.                          // Enhanced yield rate field
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _yieldRateController,
                              decoration: InputDecoration(
                                labelText: 'Tasa de Rendimiento Anual (%) (Opcional)',
                                hintText: 'Ej: 3.5',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.trending_up,
                                    size: 20,
                                    color: Colors.teal,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                  return 'Por favor, ingresa un número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),                          // Enhanced savings target amount field
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _savingsTargetAmountController,
                              decoration: InputDecoration(
                                labelText: 'Monto de Meta de Ahorro (Opcional)',
                                hintText: 'Ej: 100000.00',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.savings,
                                    size: 20,
                                    color: Colors.purple,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                  return 'Por favor, ingresa un número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),                          // Enhanced savings target date field
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _savingsTargetDateController,
                              decoration: InputDecoration(
                                labelText: 'Fecha Límite de Meta de Ahorro (Opcional)',
                                hintText: 'Selecciona una fecha',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.date_range,
                                    size: 20,
                                    color: Colors.indigo,
                                  ),
                                ),
                                suffixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              readOnly: true,                              onTap: () => _selectDate(context),
                              validator: (value) {
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // --- NUEVOS CAMPOS PERSONALIZABLES ---
                          // Campo ID personalizado
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _customIdController,
                              decoration: InputDecoration(
                                labelText: 'ID Personalizado (Opcional)',
                                hintText: 'Ej: CTA001, AHORROS-2024',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.badge_outlined,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              validator: (value) {
                                // Validación opcional - permitir alfanumérico y símbolos
                                if (value != null && value.isNotEmpty) {
                                  if (value.length > 50) {
                                    return 'El ID no puede tener más de 50 caracteres';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo Llave personalizada
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _customKeyController,
                              decoration: InputDecoration(
                                labelText: 'Llave Personalizada (Opcional)',
                                hintText: 'Ej: KEY123, BANCOLOMBIA-*4567',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.key_outlined,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              validator: (value) {
                                // Validación opcional - permitir alfanumérico y símbolos
                                if (value != null && value.isNotEmpty) {
                                  if (value.length > 50) {
                                    return 'La llave no puede tener más de 50 caracteres';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Enhanced update button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _updateAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.update,
                                    color: colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Actualizar Cuenta',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}*/