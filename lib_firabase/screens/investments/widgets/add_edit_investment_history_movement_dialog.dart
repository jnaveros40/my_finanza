// lib/screens/investments/widgets/add_edit_investment_history_movement_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp
import 'package:intl/intl.dart'; // Para formatear fechas


class AddEditInvestmentHistoryMovementDialog extends StatefulWidget {
  // Si se pasa un mapa de movimiento, estamos editando. Si es null, estamos añadiendo.
  final Map<String, dynamic>? movementData;
  final String? investmentCurrency; // <-- NUEVO: Moneda de la inversión principal

  const AddEditInvestmentHistoryMovementDialog({
    super.key,
    this.movementData,
    this.investmentCurrency, // <-- Añadir al constructor
  });

  @override
  _AddEditInvestmentHistoryMovementDialogState createState() => _AddEditInvestmentHistoryMovementDialogState();
}

class _AddEditInvestmentHistoryMovementDialogState extends State<AddEditInvestmentHistoryMovementDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto del movimiento
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _brokerCommissionController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController(); // Para aportes
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();


  // Valores seleccionados para Dropdowns
  String _selectedMovementType = 'compra'; // Valor por defecto
  final List<String> _movementTypes = ['compra', 'venta', 'dividendo', 'ajuste', 'aporte', 'retiro', 'other']; // Tipos de movimiento

  // Mapa para mostrar nombres en español en la UI pero usar valores en inglés internamente
  final Map<String, String> _movementTypeOptions = {
    'compra': 'Compra',
    'venta': 'Venta',
    'dividendo': 'Dividendo',
    'ajuste': 'Ajuste',
    'aporte': 'Aporte',
    'retiro': 'Retiro',
    'other': 'Otro',
  };

  // Valor seleccionado para la fecha del movimiento
  DateTime _selectedMovementDate = DateTime.now();

  final bool _isSaving = false; // Indicador de carga (aunque el guardado real es en la pantalla principal)


  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Pre-llenar si estamos editando
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _brokerCommissionController.dispose();
    _exchangeRateController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.movementData != null) {
      // Estamos editando un movimiento existente (mapa)
      final data = widget.movementData!;
      _selectedMovementType = data['type'] as String? ?? 'compra'; // Usar valor existente o 'compra'
      _selectedMovementDate = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedMovementDate);
      _amountController.text = (data['amount'] as num?)?.toDouble().toString() ?? '';
      _quantityController.text = (data['quantity'] as num?)?.toDouble().toString() ?? '';
      _unitPriceController.text = (data['unitPrice'] as num?)?.toDouble().toString() ?? '';
      _brokerCommissionController.text = (data['brokerCommission'] as num?)?.toDouble().toString() ?? '';
      _exchangeRateController.text = (data['exchangeRate'] as num?)?.toDouble().toString() ?? '';
      _notesController.text = data['notes'] as String? ?? '';
      // TODO: Cargar otros campos si se añaden al mapa
    } else {
      // Estamos añadiendo un nuevo movimiento
      _selectedMovementDate = DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedMovementDate);
      // Los otros campos se inicializan con valores por defecto o vacíos
    }
  }


  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMovementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedMovementDate) {
      setState(() {
        _selectedMovementDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedMovementDate);
      });
    }
  }

  // Función para "guardar" el movimiento (en realidad, retornar los datos a la pantalla principal)
  void _saveMovement() {
    if (_formKey.currentState!.validate()) {
      // Crear un mapa con los datos del movimiento
      final Map<String, dynamic> movementData = {
        'type': _selectedMovementType,
        'date': Timestamp.fromDate(_selectedMovementDate), // Guardar como Timestamp
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'quantity': double.tryParse(_quantityController.text.trim()) ?? 0.0,
        'unitPrice': double.tryParse(_unitPriceController.text.trim()),
        'brokerCommission': double.tryParse(_brokerCommissionController.text.trim()),
        'exchangeRate': (_selectedMovementType == 'aporte' && _exchangeRateController.text.trim().isNotEmpty)
                           ? double.tryParse(_exchangeRateController.text.trim()) : null, // Solo guardar si es aporte y no está vacío
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        // TODO: Añadir otros campos como currency, result, totalCost (calcular aquí o en pantalla principal)
        // Calcular totalCost aquí para simplificar la lógica en la pantalla principal
        'totalCost': (_selectedMovementType == 'compra' || _selectedMovementType == 'aporte')
                       ? (double.tryParse(_amountController.text.trim()) ?? 0.0) + (double.tryParse(_brokerCommissionController.text.trim()) ?? 0.0)
                       : (double.tryParse(_amountController.text.trim()) ?? 0.0), // Monto + comisión para compra/aporte, solo monto para otros
        // Calcular amountInLocalCurrency aquí para aportes
         'amountInLocalCurrency': (_selectedMovementType == 'aporte' && _exchangeRateController.text.trim().isNotEmpty)
                                   ? (double.tryParse(_amountController.text.trim()) ?? 0.0) * (double.tryParse(_exchangeRateController.text.trim()) ?? 0.0)
                                   : null,
      };

      // Retornar el mapa de datos a la pantalla principal
      Navigator.of(context).pop(movementData);
    }
  }

   // Helper para obtener el símbolo de moneda (reutilizado de otras pantallas)
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


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.movementData == null ? 'Añadir Movimiento' : 'Editar Movimiento'), // Título dinámico
      content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ajustar al contenido
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Dropdown Tipo de Movimiento
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Tipo de Movimiento'),
                      value: _selectedMovementType,
                      items: _movementTypeOptions.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key, // Valor interno (inglés)
                          child: Text(entry.value), // Texto mostrado (español)
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMovementType = newValue;
                            // Opcional: Limpiar campos específicos si el tipo cambia
                            if (newValue != 'aporte') {
                               _exchangeRateController.clear();
                            }
                            // if (newValue != 'venta') {
                            //    _resultController.clear();
                            // }
                          });
                        }
                      },
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Por favor, selecciona un tipo de movimiento';
                         }
                         return null;
                       },
                    ),
                    SizedBox(height: 12),

                    // Campo Fecha del Movimiento
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Fecha del Movimiento',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecciona la fecha del movimiento';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),

                    // Campo Monto (Valor invertido o recibido)
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(labelText: 'Monto en (${widget.investmentCurrency ?? 'divisa de inversión'})'), // Mostrar moneda de la inversión
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa el monto';
                        }
                        if (double.tryParse(value) == null) { // Permitir 0 o negativos para ventas/retiros
                          return 'Por favor, ingresa un monto válido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),

                    // Campo Cantidad (Unidades)
                     TextFormField(
                       controller: _quantityController,
                       decoration: InputDecoration(labelText: 'Cantidad (Unidades)'),
                       keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                           if (value == null || value.isEmpty) {
                             return 'Por favor, ingresa la cantidad';
                           }
                           if (double.tryParse(value) == null) { // Cantidad puede ser positiva o negativa (ventas)
                              return 'Por favor, ingresa una cantidad válida';
                           }
                           return null;
                        },
                     ),
                    SizedBox(height: 12),

                    // Campo Precio Unitario (Opcional - se puede calcular)
                     TextFormField(
                       controller: _unitPriceController,
                       decoration: InputDecoration(labelText: 'Precio Unitario (Opcional)'),
                       keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                           if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                              return 'Por favor, ingresa un valor numérico válido';
                           }
                           return null;
                        },
                     ),
                    SizedBox(height: 12),


                    // Campo Comisión Broker (Opcional)
                     TextFormField(
                       controller: _brokerCommissionController,
                       decoration: InputDecoration(labelText: 'Comisión Broker (Opcional)'),
                       keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                           if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                              return 'Por favor, ingresa un valor numérico válido';
                           }
                           return null;
                        },
                     ),
                    SizedBox(height: 12),

                    // Campo Tasa de Cambio (Solo para Aportes - Opcional)
                     if (_selectedMovementType == 'aporte') // Solo mostrar si el tipo es 'aporte'
                       TextFormField(
                         controller: _exchangeRateController,
                         decoration: InputDecoration(labelText: 'Tasa de Cambio (ej. COP/USD) (Opcional)'),
                         keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                             if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                return 'Por favor, ingresa un valor numérico válido';
                             }
                             return null;
                          },
                       ),
                    if (_selectedMovementType == 'aporte') SizedBox(height: 12),


                    // Campo Notas (Opcional)
                     TextFormField(
                       controller: _notesController,
                       decoration: InputDecoration(labelText: 'Notas (Opcional)'),
                       maxLines: 2,
                     ),
                    SizedBox(height: 24),

                    // TODO: Campo Moneda del Movimiento (si es diferente de la inversión principal)
                    // TODO: Campo Resultado (para ventas)

                  ],
                ),
              ),
            ),
      actions: <Widget>[
        // Botón Cancelar
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo sin retornar datos
          },
          child: const Text('Cancelar'),
        ),
        // Botón Guardar Movimiento
        ElevatedButton(
          onPressed: _saveMovement, // Llama a la función que retorna los datos
          child: const Text('Guardar Movimiento'),
        ),
      ],
    );
  }
}
