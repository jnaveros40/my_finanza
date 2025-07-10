// lib/screens/debts/widgets/edit_debt_payment_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore para Timestamp
import 'package:mis_finanza/models/debt.dart'; // Importar el modelo Debt
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'dart:math'; // Para cálculos matemáticos

class EditDebtPaymentDialog extends StatefulWidget {
  final Debt debt; // La deuda a la que pertenece el pago
  final int paymentIndex; // El índice del pago a editar en la lista paymentHistory

  const EditDebtPaymentDialog({super.key, required this.debt, required this.paymentIndex});

  @override
  _EditDebtPaymentDialogState createState() => _EditDebtPaymentDialogState();
}

class _EditDebtPaymentDialogState extends State<EditDebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Controladores para los campos del formulario
  final TextEditingController _capitalController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _insuranceController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Valores seleccionados para Dropdowns
  String _selectedPaymentType = 'normal'; // Valor por defecto

   // Mapa para mostrar nombres en español en la UI pero usar valores en inglés internamente
  final Map<String, String> _paymentTypeOptions = {
    'normal': 'Cuota Normal',
    'extra_term': 'Abono a Capital (Reducir Plazo)',
    'extra_installment': 'Abono a Capital (Reducir Cuota)',
    'abono_capital': 'Abono a Capital (Manual)',
  };

  // Valor seleccionado para la fecha del pago
  DateTime _selectedPaymentDate = DateTime.now();

  bool _isSaving = false; // Indicador de carga al guardar

  // Datos originales del pago (para calcular la diferencia al actualizar)
  late double _originalPaymentAmount;
  late DateTime _originalPaymentDate;
  late String _originalPaymentType;

  @override
  void initState() {
    super.initState();
    // Pre-llenar el formulario con los datos del pago a editar
    final paymentToEdit = widget.debt.paymentHistory![widget.paymentIndex];

    _originalPaymentAmount = (paymentToEdit['amount'] as num).toDouble();
    _originalPaymentDate = (paymentToEdit['date'] as Timestamp).toDate();
    _originalPaymentType = paymentToEdit['paymentType'] as String? ?? 'normal'; // Usar valor por defecto si no existe

    _selectedPaymentDate = _originalPaymentDate;
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedPaymentDate);
    _notesController.text = paymentToEdit['notes'] as String? ?? '';
    _selectedPaymentType = _originalPaymentType;

    // Pre-llenar campos de desglose si existen
    _capitalController.text = ((paymentToEdit['capital_paid'] as num?)?.toDouble() ?? 0.0).toString();
    _interestController.text = ((paymentToEdit['interest_paid'] as num?)?.toDouble() ?? 0.0).toString();
    _insuranceController.text = ((paymentToEdit['insurance_paid'] as num?)?.toDouble() ?? 0.0).toString();
    _totalController.text = _originalPaymentAmount.toString();

    // Si no hay desglose disponible, intentar calcularlo
    if ((paymentToEdit['capital_paid'] == null || paymentToEdit['capital_paid'] == 0.0) &&
        _selectedPaymentType == 'normal') {
      _fillPaymentAmounts();
    }
  }

  @override
  void dispose() {
    _capitalController.dispose();
    _interestController.dispose();
    _insuranceController.dispose();
    _totalController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Función para auto-llenar los campos de pago basado en el tipo
  void _fillPaymentAmounts() {
    if (_selectedPaymentType == 'normal' && widget.debt.installmentValue != null) {
      // Para pagos normales, calcular el desglose de amortización
      _calculateAndFillAmortization();
    } else {
      // Para otros tipos de pago, inicializar en cero o mantener valores existentes
      if (_selectedPaymentType == 'abono_capital') {
        _capitalController.text = _originalPaymentAmount.toString();
        _interestController.text = '0.00';
        _insuranceController.text = '0.00';
      }
      _updateTotal();
    }
  }

  // Función para calcular y llenar el desglose de amortización
  void _calculateAndFillAmortization() {
    if (widget.debt.annualEffectiveInterestRate != null && 
        widget.debt.installmentValue != null &&
        widget.debt.insuranceValue != null) {
      
      double currentBalance = widget.debt.currentAmount;
      double annualRate = widget.debt.annualEffectiveInterestRate!;
      if (annualRate > 1.0) annualRate = annualRate / 100.0; // Convertir si está en porcentaje
      
      double installmentValue = widget.debt.installmentValue!;
      double insuranceValue = widget.debt.insuranceValue!;
      
      // Calcular desglose usando la misma lógica del servicio
      Map<String, double> portions = _calculateAmortizationPortions(
        currentBalance,
        annualRate,
        installmentValue,
        insuranceValue,
      );
      
      _capitalController.text = portions['capital']!.toStringAsFixed(2);
      _interestController.text = portions['interest']!.toStringAsFixed(2);
      _insuranceController.text = portions['insurance']!.toStringAsFixed(2);
      _updateTotal();
    }
  }

  // Función auxiliar para calcular porciones de amortización (misma lógica del servicio)
  Map<String, double> _calculateAmortizationPortions(
    double outstandingBalance,
    double annualEffectiveRate,
    double installmentValue,
    double insuranceValue,
  ) {
    // Convertir tasa efectiva anual a tasa efectiva mensual
    double monthlyEffectiveRate = annualEffectiveRate > 0
        ? (pow(1 + annualEffectiveRate, 1 / 12) - 1)
        : 0.0;

    // Calcular el interés sobre el saldo pendiente
    double interestPortion = outstandingBalance * monthlyEffectiveRate;

    // Asegurarse de que el interés calculado no sea mayor que el valor de la cuota menos seguros
    double maxInterestPortion = installmentValue - insuranceValue;
    if (interestPortion > maxInterestPortion) {
      interestPortion = maxInterestPortion > 0 ? maxInterestPortion : 0;
    }
    if (interestPortion < 0) interestPortion = 0;

    // Calcular la porción de capital
    double capitalPortion = installmentValue - interestPortion - insuranceValue;

    // Asegurar que la porción de capital no sea negativa
    if (capitalPortion < 0) capitalPortion = 0;

    // Asegurar que la porción de capital no exceda el saldo pendiente
    if (capitalPortion > outstandingBalance) {
      capitalPortion = outstandingBalance;
      // Ajustar interés si el capital pagado se limitó al saldo pendiente
      interestPortion = installmentValue - capitalPortion - insuranceValue;
      if (interestPortion < 0) interestPortion = 0;
      insuranceValue = installmentValue - capitalPortion - interestPortion;
      if (insuranceValue < 0) insuranceValue = 0;
    }

    return {
      'capital': capitalPortion,
      'interest': interestPortion,
      'insurance': insuranceValue,
    };
  }

  // Función para actualizar el total automáticamente
  void _updateTotal() {
    double capital = double.tryParse(_capitalController.text) ?? 0.0;
    double interest = double.tryParse(_interestController.text) ?? 0.0;
    double insurance = double.tryParse(_insuranceController.text) ?? 0.0;
    double total = capital + interest + insurance;
    _totalController.text = total.toStringAsFixed(2);
  }

  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPaymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedPaymentDate) {
      setState(() {
        _selectedPaymentDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedPaymentDate);
      });
    }
  }

  // Función para guardar los cambios del pago
  Future<void> _savePaymentChanges() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null || widget.debt.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se puede actualizar el pago (usuario o deuda inválida).')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final updatedPaymentAmount = double.tryParse(_totalController.text.trim()) ?? 0.0;
        final updatedPaymentNotes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
        
        // Obtener valores de los campos separados
        final capitalAmount = double.tryParse(_capitalController.text.trim()) ?? 0.0;
        final interestAmount = double.tryParse(_interestController.text.trim()) ?? 0.0;
        final insuranceAmount = double.tryParse(_insuranceController.text.trim()) ?? 0.0;

        // Crear el objeto de pago actualizado con desglose
        final updatedPaymentData = {
          'date': Timestamp.fromDate(_selectedPaymentDate),
          'amount': updatedPaymentAmount,
          'notes': updatedPaymentNotes,
          'paymentType': _selectedPaymentType,
          // Agregar el desglose detallado
          'capital_paid': capitalAmount,
          'interest_paid': interestAmount,
          'insurance_paid': insuranceAmount,
        };

        // Llama al servicio para actualizar el pago y la deuda
        await _firestoreService.updateDebtPayment(
          widget.debt.id!,
          widget.paymentIndex, // Pasar el índice del pago
          _originalPaymentAmount, // Pasar el monto original para el cálculo
          updatedPaymentData, // Pasar los datos actualizados del pago
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago de deuda actualizado con éxito.')),
        );

        // Cerrar ambos diálogos: el de edición y el de historial
        Navigator.of(context).pop(); // Cierra EditDebtPaymentDialog
        Navigator.of(context).pop(); // Cierra DebtPaymentHistoryDialog

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el pago: ${e.toString()}')),
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
    return AlertDialog(
      title: Text('Editar Pago'), // Título del diálogo de edición
      content: _isSaving
          ? SizedBox( // Mostrar indicador de carga en el diálogo
              height: 150, // Ajustar altura
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Ajustar al contenido
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Dropdown para seleccionar el Tipo de Pago
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tipo de Pago',
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: _selectedPaymentType,
                        items: _paymentTypeOptions.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPaymentType = newValue;
                              _fillPaymentAmounts(); // Recalcular campos al cambiar tipo
                            });
                          }
                        },
                         validator: (value) {
                           if (value == null || value.isEmpty) {
                             return 'Por favor, selecciona un tipo de pago';
                           }
                           return null;
                         },
                      ),
                      SizedBox(height: 16),

                      // Sección de Desglose del Pago
                      Text(
                        'Desglose del Pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Campo Capital
                      TextFormField(
                        controller: _capitalController,
                        decoration: InputDecoration(
                          labelText: 'Capital',
                          prefixIcon: Icon(Icons.account_balance),
                          suffixText: widget.debt.currency,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        onChanged: (value) => _updateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el monto de capital';
                          }
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Por favor, ingresa un monto válido (≥ 0)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Campo Intereses
                      TextFormField(
                        controller: _interestController,
                        decoration: InputDecoration(
                          labelText: 'Intereses',
                          prefixIcon: Icon(Icons.percent),
                          suffixText: widget.debt.currency,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        onChanged: (value) => _updateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el monto de intereses';
                          }
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Por favor, ingresa un monto válido (≥ 0)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Campo Seguros
                      TextFormField(
                        controller: _insuranceController,
                        decoration: InputDecoration(
                          labelText: 'Seguros',
                          prefixIcon: Icon(Icons.security),
                          suffixText: widget.debt.currency,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        onChanged: (value) => _updateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el monto de seguros';
                          }
                          if (double.tryParse(value) == null || double.parse(value) < 0) {
                            return 'Por favor, ingresa un monto válido (≥ 0)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Campo Total (Solo lectura)
                      TextFormField(
                        controller: _totalController,
                        decoration: InputDecoration(
                          labelText: 'Total del Pago',
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: widget.debt.currency,
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        readOnly: true,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El total del pago no puede estar vacío';
                          }
                          double total = double.tryParse(value) ?? 0.0;
                          if (total <= 0) {
                            return 'El total del pago debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Campo Fecha del Pago
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Fecha del Pago',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecciona la fecha del pago';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Campo Notas del Pago (Opcional)
                       TextFormField(
                         controller: _notesController,
                         decoration: InputDecoration(
                           labelText: 'Notas del Pago (Opcional)',
                           prefixIcon: Icon(Icons.note),
                         ),
                         maxLines: 2,
                       ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
      actions: <Widget>[
        // Botón Cancelar
        TextButton(
          onPressed: _isSaving ? null : () {
            Navigator.of(context).pop(); // Cerrar el diálogo
          },
          child: const Text('Cancelar'),
        ),
        // Botón Guardar Cambios
        ElevatedButton(
          onPressed: _isSaving ? null : _savePaymentChanges,
          child: _isSaving ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}
