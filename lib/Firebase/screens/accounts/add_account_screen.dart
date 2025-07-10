// lib/screens/add_account_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/account.dart';
import '../../services/firestore_service/index.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Controladores para los campos del formulario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _initialBalanceController = TextEditingController(); // Usado para Saldo Inicial (no CC)
  final TextEditingController _yieldRateController = TextEditingController();
  final TextEditingController _savingsTargetAmountController = TextEditingController();
  final TextEditingController _savingsTargetDateController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController(); // <-- NUEVO controlador para Cupo Inicial  // NUEVOS CONTROLADORES PARA TARJETAS DE CRÉDITO
  final TextEditingController _cutOffDayController = TextEditingController();
  final TextEditingController _paymentDueDayController = TextEditingController();
  
  // NUEVOS CONTROLADORES PARA CAMPOS PERSONALIZABLES
  final TextEditingController _customIdController = TextEditingController();
  final TextEditingController _customKeyController = TextEditingController();


  // Valores seleccionados para Dropdowns
  String _selectedAccountType = 'Cuenta de ahorro'; // Valor por defecto
  String _selectedCurrency = 'COP'; // Valor por defecto

  // Lista de opciones para los Dropdowns
  final List<String> _accountTypes = [
    'Cuenta de ahorro',
    //'Renta Fija',
    //'Renta Variable',
    'Efectivo',
    'Tarjeta de credito', // <-- Aseguramos que este tipo esté aquí
    //'Inversiones',
    //'Deuda', // Añadido el tipo 'Deuda' según el modelo actualizado
  ];
  final List<String> _currencies = ['COP', 'USD', 'EUR', 'GBP', 'JPY'];

  DateTime? _selectedSavingsTargetDate; // Para guardar el valor DateTime seleccionado

  bool _isLoading = false; // Indicador de carga al guardar

  // --- Helper para saber si el tipo seleccionado es Tarjeta de Crédito ---
  bool get _isCreditCardSelected => _selectedAccountType == 'Tarjeta de credito';


  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _yieldRateController.dispose();
    _savingsTargetAmountController.dispose();
    _savingsTargetDateController.dispose();    _creditLimitController.dispose();
    _cutOffDayController.dispose();
    _paymentDueDayController.dispose();
    _customIdController.dispose();
    _customKeyController.dispose();
    super.dispose();
  }

  // Función para mostrar el selector de fecha
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


  // Función para guardar la cuenta en Firestore
  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try {
        double initialBalance = double.tryParse(_initialBalanceController.text.trim()) ?? 0.0;
        double yieldRate = double.tryParse(_yieldRateController.text.trim()) ?? 0.0;
        double savingsTargetAmount = double.tryParse(_savingsTargetAmountController.text.trim()) ?? 0.0;
        double creditLimit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;        // NUEVOS CAMPOS PARA TARJETAS DE CRÉDITO
        int? cutOffDay = _isCreditCardSelected ? int.tryParse(_cutOffDayController.text.trim()) : null;
        int? paymentDueDay = _isCreditCardSelected ? int.tryParse(_paymentDueDayController.text.trim()) : null;
        
        // NUEVOS CAMPOS PERSONALIZABLES
        String? customId = _customIdController.text.trim().isNotEmpty ? _customIdController.text.trim() : null;
        String? customKey = _customKeyController.text.trim().isNotEmpty ? _customKeyController.text.trim() : null;
        
        bool isCreditCard = _isCreditCardSelected;        final newAccount = Account(
          id: null,
          userId: currentUser!.uid,
          name: _nameController.text.trim(),
          type: _selectedAccountType,
          currency: _selectedCurrency,
          initialBalance: isCreditCard ? 0.0 : initialBalance,
          currentBalance: isCreditCard ? creditLimit : initialBalance,
          yieldRate: yieldRate > 0 ? yieldRate : null,
          savingsTargetAmount: savingsTargetAmount > 0 ? savingsTargetAmount : null,
          savingsTargetDate: _selectedSavingsTargetDate,
          isArchived: false,
          order: DateTime.now().millisecondsSinceEpoch,
          isCreditCard: isCreditCard,
          creditLimit: isCreditCard ? creditLimit : 0.0,
          currentStatementBalance: 0.0,
          cutOffDay: cutOffDay,
          paymentDueDay: paymentDueDay,
          customId: customId,
          customKey: customKey,
        );

        // Llamar al servicio para guardar la cuenta
        await AccountService.saveAccount(newAccount);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cuenta guardada con éxito.')),
        );

        // Navegar de regreso
        Navigator.pop(context);
      } catch (e) {
        //print('Error al guardar cuenta: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la cuenta: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Mostrar SnackBar si la validación falla
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, completa todos los campos obligatorios.')),
        );
    }
  }
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
          'Añadir Nueva Cuenta',
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
                    'Guardando cuenta...',
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
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.add_card,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nueva Cuenta Financiera',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completa la información para crear tu nueva cuenta',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
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
                        children: <Widget>[                          // Enhanced text field with modern styling
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
                                    Icons.account_balance,
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
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingresa un nombre';
                                }
                                return null;
                              },
                              autofillHints: const [AutofillHints.name],
                            ),
                          ),
                          const SizedBox(height: 20),                          // Enhanced account type dropdown
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
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Tipo de Cuenta',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getAccountTypeColor(_selectedAccountType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getAccountTypeIcon(_selectedAccountType),
                                    size: 20,
                                    color: _getAccountTypeColor(_selectedAccountType),
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              value: _selectedAccountType,
                              dropdownColor: colorScheme.surface,
                              items: _accountTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _getAccountTypeColor(type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          _getAccountTypeIcon(type),
                                          size: 16,
                                          color: _getAccountTypeColor(type),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        type,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedAccountType = newValue;
                                    if (_isCreditCardSelected) {
                                      _initialBalanceController.clear();
                                      _yieldRateController.clear();
                                      _savingsTargetAmountController.clear();
                                      _savingsTargetDateController.clear();
                                      _selectedSavingsTargetDate = null;
                                    } else {
                                      _creditLimitController.clear();
                                    }
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
                          ),
                          const SizedBox(height: 20),                          // Enhanced currency dropdown
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
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Moneda',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.attach_money,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              value: _selectedCurrency,
                              dropdownColor: colorScheme.surface,
                              items: _currencies.map((String currency) {
                                return DropdownMenuItem<String>(
                                  value: currency,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          currency,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        currency,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCurrency = newValue;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, selecciona una moneda';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),                          // Enhanced initial balance field (for non-credit cards)
                          if (!_isCreditCardSelected)
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
                                controller: _initialBalanceController,
                                decoration: InputDecoration(
                                  labelText: 'Saldo Inicial',
                                  hintText: '0.00',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.savings,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (!_isCreditCardSelected && (value == null || value.isEmpty)) {
                                    return 'Por favor, ingresa un saldo inicial';
                                  }
                                  if (!_isCreditCardSelected && (double.tryParse(value!) == null)) {
                                    return 'Por favor, ingresa un número válido';
                                  }
                                  return null;
                                },
                                autofillHints: const [AutofillHints.transactionAmount],
                              ),
                            ),

                          // Enhanced credit limit field (for credit cards only)
                          if (_isCreditCardSelected)
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
                                  labelText: 'Cupo Inicial',
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
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (_isCreditCardSelected && (value == null || value.isEmpty)) {
                                    return 'Por favor, ingresa el cupo inicial';
                                  }
                                  if (_isCreditCardSelected && (double.tryParse(value!) == null || double.parse(value) < 0)) {
                                    return 'Por favor, ingresa un cupo válido';
                                  }
                                  return null;
                                },
                                autofillHints: const [AutofillHints.transactionAmount],
                              ),
                            ),
                          const SizedBox(height: 20),                          // Enhanced credit card specific fields
                          if (_isCreditCardSelected) ...[
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
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (_isCreditCardSelected && (value == null || value.isEmpty)) {
                                    return 'Por favor, ingresa el día de corte';
                                  }
                                  final day = int.tryParse(value!);
                                  if (_isCreditCardSelected && (day == null || day < 1 || day > 31)) {
                                    return 'Día de corte inválido';
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
                                      Icons.event,
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
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (_isCreditCardSelected && (value == null || value.isEmpty)) {
                                    return 'Por favor, ingresa el día de pago';
                                  }
                                  final day = int.tryParse(value!);
                                  if (_isCreditCardSelected && (day == null || day < 1 || day > 31)) {
                                    return 'Día de pago inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],                          // Enhanced yield rate field
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
                                    Icons.percent,
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
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                  return 'Por favor, ingresa un número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Enhanced savings target amount field
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
                                    Icons.flag,
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
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                  return 'Por favor, ingresa un número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Enhanced savings target date field
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
                                    Icons.calendar_month,
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
                              readOnly: true,
                              onTap: () => _selectDate(context),                              validator: (value) {
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
                          
                          // Enhanced save button
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
                              onPressed: _saveAccount,
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
                                    Icons.save,
                                    color: colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Guardar Cuenta',
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
}