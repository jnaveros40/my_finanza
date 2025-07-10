// lib/screens/debts/add_edit_debt_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para InputFormatters
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/debt.dart'; // Importar el modelo Debt
import 'package:mis_finanza/models/account.dart'; // Para seleccionar moneda de cuentas
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:uuid/uuid.dart'; // Necesario para generar IDs únicos
import 'package:intl/intl.dart'; // Para formatear fechas y moneda
import 'dart:math'; // Importar para cálculos matemáticos (pow)

class AddEditDebtScreen extends StatefulWidget {
  // Si se pasa una deuda, estamos editando. Si es null, estamos añadiendo.
  final Debt? debt;

  const AddEditDebtScreen({super.key, this.debt});

  @override
  _AddEditDebtScreenState createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends State<AddEditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Controladores para los campos de texto
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _creditorDebtorController = TextEditingController();
  final TextEditingController _initialAmountController = TextEditingController();
  final TextEditingController _currentAmountController = TextEditingController(); // Para editar el saldo pendiente
  final TextEditingController _insuranceValueController = TextEditingController();
  // Controladores para los nuevos campos de la calculadora
  final TextEditingController _totalInstallmentsController = TextEditingController(); // Plazo en meses
  final TextEditingController _annualInterestRateController = TextEditingController(); // Tasa Anual (%)
  // Controladores para campos existentes que ahora pueden ser calculados o para seguimiento
  final TextEditingController _paidInstallmentsController = TextEditingController(); // Cuotas Pagadas (Seguimiento real) - CORREGIDO: Añadido
  final TextEditingController _installmentValueController = TextEditingController(); // Valor Cuota (CALCULADO o ingresado)
  final TextEditingController _startDateController = TextEditingController(); // Fecha Inicio (Opcional) - CORREGIDO: Añadido
  final TextEditingController _dueDateController = TextEditingController(); // Fecha Fin/Vencimiento (Opcional) - CORREGIDO: Añadido
  final TextEditingController _interestPaidController = TextEditingController(); // Interés Pagado (Acumulado Real)
  final TextEditingController _externalIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _paymentDayController = TextEditingController(); // Día de pago

  // Variables para mostrar los resultados del cálculo
  double? _calculatedMonthlyInstallmentWithoutInsurance;
  double? _calculatedTotalMonthlyInstallment; // Cuota mensual total con seguro
  double? _calculatedTotalInterest; // Total de intereses calculado por la herramienta

  // Valores seleccionados para Dropdowns
  String _selectedDebtType = 'loan'; // Valor por defecto
  final List<String> _debtTypes = ['loan', 'credit_card_debt', 'other']; // Tipos de deuda

  String _selectedDebtStatus = 'active'; // Valor por defecto
  final List<String> _debtStatuses = ['active', 'paid', 'defaulted']; // Estados de deuda

  String _selectedCurrency = 'COP'; // Valor por defecto
  List<String> _availableCurrencies = ['COP', 'USD', 'EUR']; // Monedas disponibles (puedes cargar de cuentas si quieres)

  // Valores seleccionados para fechas
  DateTime _selectedCreationDate = DateTime.now(); // Fecha de creación del registro (no editable)
  DateTime? _selectedStartDate; // Fecha de inicio del crédito
  DateTime? _selectedDueDate; // Fecha de vencimiento

  bool _isLoading = true; // Indicador de carga inicial (si cargamos monedas de cuentas)
  bool _isSaving = false; // Indicador de carga al guardar

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales si es necesario (ej. monedas de cuentas)
    _loadInitialData();

    // Añadir listeners a los controladores para recalcular cuando cambien los valores
    _initialAmountController.addListener(_calculateLoanDetails);
    _totalInstallmentsController.addListener(_calculateLoanDetails);
    _annualInterestRateController.addListener(_calculateLoanDetails);
    _insuranceValueController.addListener(_calculateLoanDetails);

    // Si estamos editando, también pre-llenamos los campos de cálculo y seguimiento
    if (widget.debt != null) {
       // Pre-llenar los campos que ahora se usan para el cálculo
       _initialAmountController.text = widget.debt!.initialAmount.toString();
       _totalInstallmentsController.text = widget.debt!.totalInstallments?.toString() ?? '';
       _annualInterestRateController.text = widget.debt!.annualEffectiveInterestRate?.toString() ?? '';
       _insuranceValueController.text = widget.debt!.insuranceValue?.toString() ?? '';

       // Pre-llenar los campos que ahora pueden mostrar resultados calculados o datos guardados
       _installmentValueController.text = widget.debt!.installmentValue?.toString() ?? '';
       _paidInstallmentsController.text = widget.debt!.paidInstallments?.toString() ?? ''; // CORREGIDO: Pre-llenar cuotas pagadas
       _interestPaidController.text = widget.debt!.interestPaid?.toString() ?? ''; // Interés pagado real

       // Pre-llenar los controladores de fecha si existen datos
        _selectedStartDate = widget.debt!.startDate;
        if (_selectedStartDate != null) {
           _startDateController.text = DateFormat('yyyy-MM-dd').format(_selectedStartDate!); // CORREGIDO: Usar el controlador correcto
        }

        _selectedDueDate = widget.debt!.dueDate;
         if (_selectedDueDate != null) {
           _dueDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDueDate!); // CORREGIDO: Usar el controlador correcto
        }

       _paymentDayController.text = widget.debt!.paymentDay?.toString() ?? '';

       // Si existe un total calculado previo, mostrarlo
       _calculatedTotalInterest = widget.debt!.totalCalculatedInterest;

       // Calcular los detalles del préstamo con los datos cargados
       _calculateLoanDetails();
    }
  }

  @override
  void dispose() {
    // Eliminar listeners para evitar fugas de memoria
    _initialAmountController.removeListener(_calculateLoanDetails);
    _totalInstallmentsController.removeListener(_calculateLoanDetails);
    _annualInterestRateController.removeListener(_calculateLoanDetails);
    _insuranceValueController.removeListener(_calculateLoanDetails);

    _descriptionController.dispose();
    _creditorDebtorController.dispose();
    _initialAmountController.dispose();
    _currentAmountController.dispose();
    _insuranceValueController.dispose();
    _totalInstallmentsController.dispose();
    _annualInterestRateController.dispose();
    _paidInstallmentsController.dispose(); // CORREGIDO: Liberar el controlador
    _installmentValueController.dispose();
    _startDateController.dispose(); // CORREGIDO: Liberar el controlador
    _dueDateController.dispose(); // CORREGIDO: Liberar el controlador
    _interestPaidController.dispose();
    _externalIdController.dispose();
    _notesController.dispose();
    _paymentDayController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
     setState(() {
       _isLoading = true;
     });
     try {
        // Opcional: Cargar monedas únicas de las cuentas del usuario
        if (currentUser != null) {
           List<Account> accounts = await _firestoreService.getAccounts().first;
           Set<String> currencies = accounts.map((acc) => acc.currency).toSet();
           if (currencies.isNotEmpty) {
              _availableCurrencies = currencies.toList();
              // Si estamos añadiendo, seleccionar la primera moneda disponible por defecto
              if (widget.debt == null) {
                 _selectedCurrency = _availableCurrencies.first;
              }
           }
        }

        // Si estamos editando, pre-llenar los campos con los datos de la deuda
        if (widget.debt != null) {
           _descriptionController.text = widget.debt!.description;
           _creditorDebtorController.text = widget.debt!.creditorDebtor ?? '';
           // Los controladores de initialAmount, totalInstallments, annualInterestRate, insuranceValue
           // ya se pre-llenan en initState después de cargar los datos iniciales.
           _currentAmountController.text = widget.debt!.currentAmount.toString(); // Pre-llenar saldo pendiente
           _paidInstallmentsController.text = widget.debt!.paidInstallments?.toString() ?? ''; // CORREGIDO: Pre-llenar cuotas pagadas

           _selectedCreationDate = widget.debt!.creationDate; // Fecha de creación del registro (no editable)

           _selectedStartDate = widget.debt!.startDate;
           if (_selectedStartDate != null) {
              _startDateController.text = DateFormat('yyyy-MM-dd').format(_selectedStartDate!); // CORREGIDO: Usar el controlador correcto
           }

           _selectedDueDate = widget.debt!.dueDate;
            if (_selectedDueDate != null) {
              _dueDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDueDate!); // CORREGIDO: Usar el controlador correcto
           }

           _externalIdController.text = widget.debt!.externalId ?? '';
           _notesController.text = widget.debt!.notes ?? '';

           _selectedDebtType = widget.debt!.type;
           _selectedDebtStatus = widget.debt!.status;
           _selectedCurrency = widget.debt!.currency; // Pre-seleccionar moneda de la deuda

        } else {
           // Si estamos añadiendo, inicializar fecha de creación y fechas opcionales
           _selectedCreationDate = DateTime.now();
           // _selectedStartDate = null; // Ya son null por defecto
           // _selectedDueDate = null;
        }

     } catch (e) {
         //print('Error loading initial data for AddEditDebtScreen: $e');
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error al cargar datos iniciales: ${e.toString()}')),
         );
     } finally {
        setState(() {
          _isLoading = false;
        });
     }
  }

  // --- Función para calcular los detalles del préstamo ---
  void _calculateLoanDetails() {
    // Obtener los valores de los campos de texto
    final double? principal = double.tryParse(_initialAmountController.text.trim());
    final int? termInMonths = int.tryParse(_totalInstallmentsController.text.trim());
    final double? annualRate = double.tryParse(_annualInterestRateController.text.trim());
    final double? insurance = double.tryParse(_insuranceValueController.text.trim());

    // Validar que los campos necesarios para el cálculo tengan valores válidos
    if (principal != null && principal > 0 && termInMonths != null && termInMonths > 0 && annualRate != null && annualRate >= 0) {
      try {
        // Convertir la tasa anual efectiva a tasa mensual nominal
        // Fórmula: Tasa Mensual = (1 + Tasa Anual)^(1/12) - 1
        // La tasa anual debe estar en formato decimal (ej. 10% = 0.10)
        final double annualRateDecimal = annualRate / 100.0;
        final double monthlyRate = pow(1 + annualRateDecimal, 1/12).toDouble() - 1;

        // Calcular la cuota mensual fija (sin seguro) usando la fórmula de amortización
        // M = P [ i(1 + i)^n ] / [ (1 + i)^n – 1 ]
        double monthlyInstallmentWithoutInsurance;
        if (monthlyRate == 0) {
          // Si la tasa es 0, la cuota es simplemente Principal / Plazo
          monthlyInstallmentWithoutInsurance = principal / termInMonths;
        } else {
          monthlyInstallmentWithoutInsurance = principal * (monthlyRate * pow(1 + monthlyRate, termInMonths)) / (pow(1 + monthlyRate, termInMonths) - 1);
        }

        // Calcular la cuota mensual total (con seguro)
        final double totalMonthlyInstallment = monthlyInstallmentWithoutInsurance + (insurance ?? 0.0);

        // Calcular el total pagado (cuota total * plazo)
        final double totalPaidOverTerm = totalMonthlyInstallment * termInMonths;

        // Calcular el total de intereses (Total Pagado - Capital Inicial - Total Seguros)
        final double totalInsuranceCost = (insurance ?? 0.0) * termInMonths;
        final double totalInterest = totalPaidOverTerm - principal - totalInsuranceCost;

        // Actualizar el estado para mostrar los resultados
        setState(() {
          _calculatedMonthlyInstallmentWithoutInsurance = monthlyInstallmentWithoutInsurance;
          _calculatedTotalMonthlyInstallment = totalMonthlyInstallment;
          _calculatedTotalInterest = totalInterest;

          // Opcional: Pre-llenar el campo de Valor Cuota con el valor calculado total
          // Esto podría ser útil si el usuario quiere guardar este valor calculado.
          // Sin embargo, si el campo es editable, el usuario podría cambiarlo.
          // Decidimos mostrarlo como resultado separado y guardar los inputs.
          //_installmentValueController.text = totalMonthlyInstallment.toStringAsFixed(2); // Mostrar con 2 decimales
        });

      } catch (e) {
        // Manejar posibles errores en el cálculo (ej. overflow si los números son muy grandes)
        //print('Error durante el cálculo del préstamo: $e');
         setState(() {
            _calculatedMonthlyInstallmentWithoutInsurance = null;
            _calculatedTotalMonthlyInstallment = null;
            _calculatedTotalInterest = null;
         });
      }
    } else {
      // Si los campos necesarios no son válidos, limpiar los resultados
      setState(() {
        _calculatedMonthlyInstallmentWithoutInsurance = null;
        _calculatedTotalMonthlyInstallment = null;
        _calculatedTotalInterest = null;
      });
    }
  }


  // Helper para obtener el texto a mostrar para el tipo de deuda
  String _getDebtTypeText(String type) {
      switch (type) {
          case 'loan': return 'Préstamo';
          case 'credit_card_debt': return 'Deuda Tarjeta Crédito';
          case 'other': return 'Otra';
          default: return type;
      }
  }

   // Helper para obtener el texto a mostrar para el estado de la deuda
  String _getDebtStatusText(String status) {
      switch (status) {
          case 'active': return 'Activa';
          case 'paid': return 'Pagada';
          case 'defaulted': return 'Incumplida';
          default: return status;
      }
  }

  // Helper para formatear moneda (reutilizado de DebtsScreen)
   String _formatCurrency(double amount, String currencyCode) {
     final format = NumberFormat.currency(
       locale: 'en_US', // Puedes ajustar la localización si es necesario
       symbol: _getCurrencySymbol(currencyCode),
       decimalDigits: 2, // Mostrar 2 decimales
     );
     return format.format(amount);
   }

   // Helper para obtener el símbolo de moneda (reutilizado de DebtsScreen)
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


  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _selectedStartDate : _selectedDueDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
         if (isStartDate) {
            _selectedStartDate = picked;
            _startDateController.text = DateFormat('yyyy-MM-dd').format(_selectedStartDate!);
         } else {
            _selectedDueDate = picked;
            _dueDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDueDate!);
         }
      });
    }
  }


  // Función para guardar la deuda (añadir o editar)
  Future<void> _saveDebt() async {
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
        // Obtener los valores de los campos de texto para guardar
        final double? initialAmount = double.tryParse(_initialAmountController.text.trim());
        final double? insuranceValue = double.tryParse(_insuranceValueController.text.trim());
        final int? totalInstallments = int.tryParse(_totalInstallmentsController.text.trim());
        final double? annualInterestRateRaw = double.tryParse(_annualInterestRateController.text.trim());
        final double? annualInterestRate = annualInterestRateRaw != null ? annualInterestRateRaw / 100.0 : null; // <-- Guardar como decimal
        final double? currentAmount = double.tryParse(_currentAmountController.text.trim());
        final int? paymentDay = int.tryParse(_paymentDayController.text.trim());

        // Crear el objeto Debt
        final debtToSave = Debt(
          // Si estamos editando, usar el ID existente. Si no, generar uno nuevo.
          id: widget.debt?.id ?? const Uuid().v4(),
          userId: currentUser!.uid,
          description: _descriptionController.text.trim(),
          creditorDebtor: _creditorDebtorController.text.trim().isNotEmpty ? _creditorDebtorController.text.trim() : null,
          initialAmount: initialAmount ?? 0.0, // Guardar el capital inicial ingresado
          // Si estamos añadiendo, el currentAmount es igual al initialAmount.
          // Si estamos editando, usamos el valor del campo currentAmount.
          currentAmount: widget.debt == null ? (initialAmount ?? 0.0) : (currentAmount ?? 0.0),
          insuranceValue: insuranceValue, // Guardar el valor del seguro ingresado
          totalInstallments: totalInstallments, // Guardar el plazo ingresado
          paidInstallments: int.tryParse(_paidInstallmentsController.text.trim()), // Guardar cuotas pagadas (seguimiento)
          // Guardar el valor de la cuota CALCULADA si existe, de lo contrario usar el valor del campo (si se editó manualmente)
          installmentValue: _calculatedTotalMonthlyInstallment ?? double.tryParse(_installmentValueController.text.trim()),
          creationDate: widget.debt?.creationDate ?? DateTime.now(), // Mantener fecha de creación si edita, usar ahora si añade
          startDate: _selectedStartDate,
          dueDate: _selectedDueDate,
          annualEffectiveInterestRate: annualInterestRate, // Guardar la tasa como decimal
          interestPaid: double.tryParse(_interestPaidController.text.trim()), // Guardar interés pagado real (seguimiento)
          totalCalculatedInterest: _calculatedTotalInterest, // NUEVO: Guardar el total de interés calculado
          type: _selectedDebtType,
          status: _selectedDebtStatus,
          currency: _selectedCurrency,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          paymentHistory: widget.debt?.paymentHistory, // Mantener historial de pagos si edita (no se edita aquí)
          externalId: _externalIdController.text.trim().isNotEmpty ? _externalIdController.text.trim() : null,
          paymentDay: paymentDay,
        );

        // Llamar al servicio para guardar la deuda (maneja añadir o actualizar)
        await _firestoreService.saveDebt(debtToSave);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deuda guardada con éxito.')),
        );

        Navigator.pop(context); // Navegar de regreso a la pantalla anterior (DebtsScreen)

      } catch (e) {
        //print('Error al guardar deuda: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la deuda: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título dinámico según si estamos añadiendo o editando
        title: Text(widget.debt == null ? 'Añadir Deuda' : 'Editar Deuda'),
      ),
      body: _isLoading || _isSaving
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Campo Nombre / Título
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la Deuda',
                          hintText: 'Ej: Préstamo personal',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.assignment,
                              size: 20,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa un nombre para la deuda';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                    // Campo Acreedor / A quien le debo
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _creditorDebtorController,
                        decoration: InputDecoration(
                          labelText: 'Acreedor / A quién le debo',
                          hintText: 'Ej: Banco, persona, entidad',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Campo Capital Inicial (Principal)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _initialAmountController,
                        decoration: InputDecoration(
                          labelText: 'Capital Inicial',
                          hintText: 'Ej: 1000000',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el capital inicial';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Por favor, ingresa un monto válido (> 0)';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                    // Campo Plazo del Préstamo (Meses)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _totalInstallmentsController,
                        decoration: InputDecoration(
                          labelText: 'Plazo del Préstamo (Meses)',
                          hintText: 'Ej: 12',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_view_month,
                              size: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el plazo en meses';
                          }
                          if (int.tryParse(value) == null || int.parse(value) <= 0) {
                            return 'Por favor, ingresa un número entero válido (> 0)';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                    // Campo Tasa Interés Efectiva Anual (%)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _annualInterestRateController,
                        decoration: InputDecoration(
                          labelText: 'Tasa Interés Anual (%)',
                          hintText: 'Ej: 18',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.percent,
                              size: 20,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa la tasa de interés anual';
                          }
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Por favor, ingresa un valor numérico válido (>= 0)';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                    // Campo Valor Seguros (Fijo Mensual)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _insuranceValueController,
                        decoration: InputDecoration(
                          labelText: 'Valor Seguro (Fijo Mensual) (Opcional)',
                          hintText: 'Ej: 15000',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.security,
                              size: 20,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Por favor, ingresa un valor numérico válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 24), // Espacio antes de los resultados del cálculo

                    // --- Mostrar Resultados del Cálculo ---
                    if (_calculatedTotalMonthlyInstallment != null)
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(
                              'Resultados del Cálculo:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Text(
                               'Cuota Mensual Estimada (sin seguro): ${_calculatedMonthlyInstallmentWithoutInsurance != null ? _formatCurrency(_calculatedMonthlyInstallmentWithoutInsurance!, _selectedCurrency) : 'N/A'}',
                               style: Theme.of(context).textTheme.bodyMedium,
                            ),
                           Text(
                               'Cuota Mensual Estimada (con seguro): ${_calculatedTotalMonthlyInstallment != null ? _formatCurrency(_calculatedTotalMonthlyInstallment!, _selectedCurrency) : 'N/A'}',
                               style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                               'Total Intereses Estimado: ${_calculatedTotalInterest != null ? _formatCurrency(_calculatedTotalInterest!, _selectedCurrency) : 'N/A'}',
                               style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(height: 24), // Espacio después de los resultados
                         ],
                       ),

                    // Campo Monto Restante (Solo editable si estamos editando una deuda)
                    // Este campo es para el seguimiento real del saldo pendiente, no para el cálculo inicial.
                    if (widget.debt != null) // Mostrar solo en edición
                       TextFormField(
                         controller: _currentAmountController,
                         decoration: const InputDecoration(
                           labelText: 'Monto Restante (Para seguimiento)',
                           prefixIcon: Icon(Icons.account_balance_wallet),
                         ),
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))], // Permitir solo números y un punto decimal
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                             if (value == null || value.isEmpty) {
                               return 'Por favor, ingresa el monto restante';
                             }
                             if (double.tryParse(value) == null || double.parse(value) < 0) { // Puede ser 0 si está pagada
                                return 'Por favor, ingresa un monto válido (>= 0)';
                             }
                             return null;
                          },
                       ),
                    if (widget.debt != null) SizedBox(height: 12),

                    // Campo Cuotas Pagadas (Opcional) - Para seguimiento real
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _paidInstallmentsController,
                        decoration: InputDecoration(
                          labelText: 'Cuotas Pagadas (Seguimiento) (Opcional)',
                          hintText: 'Ej: 3',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Permitir solo dígitos
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                            return 'Por favor, ingresa un número entero válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),


                    // Campo Valor Cuota (Opcional)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _installmentValueController,
                        decoration: InputDecoration(
                          labelText: 'Valor Cuota (Calculado o Ingresado)',
                          hintText: 'Ej: 95000',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calculate,
                              size: 20,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Por favor, ingresa un valor numérico válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),


                    // Campo Fecha Inicio (Opcional)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: InputDecoration(
                          labelText: 'Fecha Inicio (Opcional)',
                          hintText: 'Selecciona una fecha',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              size: 20,
                              color: Colors.blue,
                            ),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, isStartDate: true),
                        validator: (value) {
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                    // Campo Fecha Fin / Vencimiento (Opcional)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _dueDateController,
                        decoration: InputDecoration(
                          labelText: 'Fecha Fin / Vencimiento (Opcional)',
                          hintText: 'Selecciona una fecha',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.event,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, isStartDate: false),
                        validator: (value) {
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                     // Campo Interés Pagado (Acumulado) (Opcional) - Para seguimiento real
                     Container(
                       decoration: BoxDecoration(
                         color: Theme.of(context).colorScheme.surface,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(
                           color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                         ),
                       ),
                       child: TextFormField(
                         controller: _interestPaidController,
                         decoration: InputDecoration(
                           labelText: 'Interés Pagado (Acumulado Real) (Opcional)',
                           hintText: 'Ej: 120000',
                           border: InputBorder.none,
                           filled: true,
                           fillColor: Colors.transparent,
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                           prefixIcon: Container(
                             margin: const EdgeInsets.all(8),
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.purple.withOpacity(0.08),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: const Icon(
                               Icons.trending_up,
                               size: 20,
                               color: Colors.purple,
                             ),
                           ),
                         ),
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                         textInputAction: TextInputAction.next,
                         validator: (value) {
                           if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                              return 'Por favor, ingresa un valor numérico válido';
                           }
                           return null;
                         },
                       ),
                     ),
                    SizedBox(height: 12),

                    // Dropdown Tipo de Deuda
                    Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    ),
  ),
  child: DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: 'Tipo de Deuda',
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.category,
          size: 20,
          color: Colors.deepPurple,
        ),
      ),
    ),
    value: _selectedDebtType,
    items: _debtTypes.map((String type) {
      return DropdownMenuItem<String>(
        value: type,
        child: Text(_getDebtTypeText(type)),
      );
    }).toList(),
    onChanged: (newValue) {
      if (newValue != null) {
        setState(() {
          _selectedDebtType = newValue;
        });
      }
    },
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Por favor, selecciona un tipo de deuda';
      }
      return null;
    },
  ),
),
SizedBox(height: 12),

                    // Dropdown Estado de la Deuda
                    Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    ),
  ),
  child: DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: 'Estado de la Deuda',
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.info,
          size: 20,
          color: Colors.blueAccent,
        ),
      ),
    ),
    value: _selectedDebtStatus,
    items: _debtStatuses.map((String status) {
      return DropdownMenuItem<String>(
        value: status,
        child: Text(_getDebtStatusText(status)),
      );
    }).toList(),
    onChanged: (newValue) {
      if (newValue != null) {
        setState(() {
          _selectedDebtStatus = newValue;
        });
      }
    },
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Por favor, selecciona el estado de la deuda';
      }
      return null;
    },
  ),
),
SizedBox(height: 12),

                    // Dropdown Moneda
                    Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    ),
  ),
  child: DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: 'Moneda',
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.attach_money,
          size: 20,
          color: Colors.amber,
        ),
      ),
    ),
    value: _selectedCurrency,
    items: _availableCurrencies.map((String currency) {
      return DropdownMenuItem<String>(
        value: currency,
        child: Text(currency),
      );
    }).toList(),
    onChanged: (newValue) {
      if (newValue != null) {
        setState(() {
          _selectedCurrency = newValue;
        });
        _calculateLoanDetails();
      }
    },
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Por favor, selecciona la moneda';
      }
      return null;
    },
  ),
),
SizedBox(height: 12),

                    // Campo ID Externo (Opcional)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _externalIdController,
                        decoration: InputDecoration(
                          labelText: 'ID Externo (Opcional)',
                          hintText: 'Ej: 123-ABC',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.link,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    SizedBox(height: 12),


                    // Campo Notas (Opcional)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notas (Opcional)',
                          hintText: 'Agrega notas adicionales',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.note_alt,
                              size: 20,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Campo Día de Pago (1-30)
                    Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    ),
  ),
  child: TextFormField(
    controller: _paymentDayController,
    decoration: InputDecoration(
      labelText: 'Día de Pago (1-30)',
      hintText: 'Ej: 15',
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.calendar_today,
          size: 20,
          color: Colors.red,
        ),
      ),
    ),
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    textInputAction: TextInputAction.next,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Por favor, ingresa el día de pago';
      }
      final intDay = int.tryParse(value);
      if (intDay == null || intDay < 1 || intDay > 30) {
        return 'El día de pago debe ser un número entre 1 y 30';
      }
      return null;
    },
  ),
),
SizedBox(height: 24),

                    // Botón Guardar Deuda
                    SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _isLoading || _isSaving ? null : _saveDebt,
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
    child: _isSaving
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : const Text('Guardar Deuda'),
  ),
),
                  ],
                ),
              ),
            ),
    );
  }
}
