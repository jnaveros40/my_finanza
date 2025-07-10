// lib/screens/investments/add_edit_investment_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/investment.dart'; // Importar el modelo Investment
import 'package:mis_finanza/models/account.dart'; // Importar el modelo Account
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:uuid/uuid.dart'; // Necesario para generar IDs únicos


class AddEditInvestmentScreen extends StatefulWidget {
  // Si se pasa una inversión, estamos editando. Si es null, estamos añadiendo.
  final Investment? investment;

  const AddEditInvestmentScreen({super.key, this.investment});

  @override
  _AddEditInvestmentScreenState createState() => _AddEditInvestmentScreenState();
}

class _AddEditInvestmentScreenState extends State<AddEditInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Controladores para los campos de texto que SE MOSTRARÁN en la UI
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _isinSymbolController = TextEditingController(); // ISIN/Símbolo


  // Valores seleccionados para Dropdowns que SE MOSTRARÁN en la UI
  String _selectedInvestmentType = 'stocks'; // Valor por defecto
  final List<String> _investmentTypes = ['stocks', 'funds', 'crypto', 'real_estate', 'bonds', 'other']; // Tipos de inversión

  String? _selectedCurrency; // Moneda de la inversión
  // Lista de monedas disponibles - AMPLIADA (mantener la lista ampliada)
  List<String> _availableCurrencies = [ 'USD','COP', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'HKD', 'SGD'];


  // --- Controladores y variables para campos que NO SE MOSTRARÁN en la UI ---
  // Se mantienen para leer/guardar datos si se edita una inversión existente,
  // o se inicializan con valores por defecto si se añade una nueva.
  double? _currentAmount; // Valor actual de la inversión (opcional, manual) - Ahora usado para estimatedCurrentValue
  // ---------------------------------------------------------------------------


  bool _isLoading = true; // Indicador de carga inicial
  bool _isSaving = false; // Indicador de carga al guardar


  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Cargar datos iniciales (monedas, pre-llenar si edita)
  }

  @override
  void dispose() {
    // Disponer solo los controladores de los campos que se muestran
    _nameController.dispose();
    _platformController.dispose();
    _isinSymbolController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
     setState(() {
       _isLoading = true;
     });
     try {
        // Cargar monedas únicas de las cuentas del usuario
        if (currentUser != null) {
           List<Account> accounts = await _firestoreService.getAccounts().first;
           Set<String> currencies = accounts.map((acc) => acc.currency).toSet();
           // Combinar monedas de cuentas con la lista predefinida
           _availableCurrencies = (_availableCurrencies.toSet().union(currencies)).toList();

              // Si estamos añadiendo, seleccionar la primera moneda disponible por defecto
              if (widget.investment == null && _availableCurrencies.isNotEmpty) {
                 _selectedCurrency = _availableCurrencies.first;
              }
        }

        // Si estamos editando, pre-llenar los campos con los datos de la inversión
        if (widget.investment != null) {
           _nameController.text = widget.investment!.name;
           _selectedInvestmentType = widget.investment!.type;
           _selectedCurrency = widget.investment!.currency; // Pre-seleccionar moneda
           _platformController.text = widget.investment!.platform ?? '';
           _isinSymbolController.text = widget.investment!.isinSymbol ?? ''; // <-- Pre-llenar

           // Cargar valores de campos que NO SE MOSTRARÁN en la UI
           _currentAmount = widget.investment!.estimatedCurrentValue; // <-- Cargar estimatedCurrentValue en _currentAmount

        } else {
           // Si estamos añadiendo, inicializar fecha de creación y fecha de inicio
           _currentAmount = 0.0; // Inicializar estimatedCurrentValue a 0.0 al añadir
        }

     } catch (e) {
         //print('Error loading initial data for AddEditInvestmentScreen: $e');
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error al cargar datos iniciales: ${e.toString()}')),
         );
     } finally {
        setState(() {
          _isLoading = false;
        });
     }
  }


  // Función para guardar la inversión (añadir o editar)
  Future<void> _saveInvestment() async {
    //print('DEBUG: _saveInvestment called'); // DEBUG //print

    if (_formKey.currentState!.validate()) {
      //print('DEBUG: Form validated'); // DEBUG //print

      if (currentUser == null) {
        //print('DEBUG: currentUser is null'); // DEBUG //print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
        return;
      }
      //print('DEBUG: currentUser is not null'); // DEBUG //print


      setState(() {
        _isSaving = true;
      });

      try {
        // Crear el objeto Investment
        final investmentToSave = Investment(
          // Si estamos editando, usar el ID existente. Si no, generar uno nuevo.
          id: widget.investment?.id ?? const Uuid().v4(),
          userId: currentUser!.uid,
          name: _nameController.text.trim(),
          type: _selectedInvestmentType,
          // initialAmount y totalQuantity ya no se ingresan directamente aquí
          // Mantener valor existente si edita, o 0 si añade
          initialAmount: widget.investment?.initialAmount ?? 0.0, // Keep existing or 0
          totalQuantity: widget.investment?.totalQuantity ?? 0.0, // Keep existing or 0
          // Usar fecha seleccionada (si se cargó al editar) o hoy si añade
          startDate: DateTime.now(), // Keep existing or now
          currency: _selectedCurrency ?? 'USD', // Use selected or default
          // Mantener valor existente si edita, o null si añade
          currentAmount: widget.investment?.currentAmount, // Keep existing or null
          // Usar valor del controlador si no está vacío, si no, mantener existente o null
          platform: _platformController.text.trim().isNotEmpty ? _platformController.text.trim() : widget.investment?.platform,
          // El historial (array) se mantiene con el valor existente o null si es nuevo
          history: widget.investment?.history, // Keep existing or null

           // CAMPOS CALCULADOS:
           // currentQuantity, totalInvested, estimatedGainLoss, totalDividends
           // SON CALCULADOS Y GESTIONADOS EN INVESTMENT_MOVEMENTS_SCREEN.
           // Aquí, solo mantenemos los valores existentes del objeto widget.investment
           // si estamos editando, o los inicializamos a 0.0 si estamos añadiendo.
           currentQuantity: widget.investment?.currentQuantity ?? 0.0,
           totalInvested: widget.investment?.totalInvested ?? 0.0,
           // *** CORRECCIÓN AQUÍ: Usar el valor cargado en _currentAmount para estimatedCurrentValue ***
           estimatedCurrentValue: _currentAmount ?? 0.0, // Use the value loaded into _currentAmount or 0.0
           estimatedGainLoss: widget.investment?.estimatedGainLoss ?? 0.0, // Keep existing or 0.0
           totalDividends: widget.investment?.totalDividends ?? 0.0, // Keep existing or 0.0

           // Nuevos campos del modelo restructurado (mantener para compatibilidad)
           // Mantener fecha existente o usar actual si es nuevo
           creationDate: widget.investment?.creationDate ?? DateTime.now(), // Keep existing or now
           status: widget.investment?.status ?? 'active', // Keep existing or active
           // Usar valor del controlador si no está vacío, si no, mantener existente o null
           isinSymbol: _isinSymbolController.text.trim().isNotEmpty ? _isinSymbolController.text.trim() : widget.investment?.isinSymbol,
        );

        //print('DEBUG: Investment object created: ${investmentToSave.toFirestore()}'); // DEBUG //print

        // Llamar al servicio para guardar la inversión (maneja añadir o actualizar)
        await _firestoreService.saveInvestment(investmentToSave);

        //print('DEBUG: _firestoreService.saveInvestment completed'); // DEBUG //print


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inversión guardada con éxito.')),
        );

        Navigator.pop(context); // Navegar de regreso a la pantalla anterior (InvestmentsScreen)

      } catch (e) {
        //print('DEBUG: Error caught in _saveInvestment: $e'); // DEBUG //print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la inversión: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
          //print('DEBUG: _isSaving set to false'); // DEBUG //print
        });
      }
    } else {
       //print('DEBUG: Form validation failed'); // DEBUG //print
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, completa los campos requeridos y selecciona las opciones válidas.')),
        );
    }
  }


  // Helper para obtener el texto a mostrar para el tipo de inversión
  String _getInvestmentTypeText(String type) {
      switch (type) {
          case 'stocks': return 'Acciones';
          case 'funds': return 'Fondos de Inversión';
          case 'crypto': return 'Criptomonedas';
          case 'real_estate': return 'Bienes Raíces';
          case 'bonds': return 'Bonos';
          case 'other': return 'Otra';
          default: return type;
      }
  }
  // Helper methods for responsive design
  Widget _buildFormSection(BuildContext context, String title, List<Widget> children, {bool isMobile = true}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveFormField({
    required Widget child,
    bool isMobile = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16.0 : 20.0),
      child: child,
    );
  }

  Widget _buildResponsiveSaveButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 50 : 56,
      child: ElevatedButton(
        onPressed: _isLoading || _isSaving ? null : _saveInvestment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving 
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimary,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Guardar Inversión',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.investment == null ? 'Añadir Inversión' : 'Editar Inversión'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando datos...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Form(
                    key: _formKey,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 600,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFormSection(
                            context,
                            'Detalles de la Inversión',
                            [
                              _buildResponsiveFormField(
                                isMobile: isMobile,
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre / Descripción',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.badge,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, ingresa un nombre para la inversión';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              if (isMobile) ...[
                                _buildResponsiveFormField(
                                  isMobile: isMobile,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Tipo de Inversión',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.category,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                    value: _selectedInvestmentType,
                                    items: _investmentTypes.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(_getInvestmentTypeText(type)),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedInvestmentType = newValue;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, selecciona un tipo de inversión';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                
                                _buildResponsiveFormField(
                                  isMobile: isMobile,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Moneda de la Inversión',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.monetization_on,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
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
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildResponsiveFormField(
                                        isMobile: isMobile,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText: 'Tipo de Inversión',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.category,
                                                color: Colors.orange,
                                                size: 20,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.surface,
                                          ),
                                          value: _selectedInvestmentType,
                                          items: _investmentTypes.map((String type) {
                                            return DropdownMenuItem<String>(
                                              value: type,
                                              child: Text(_getInvestmentTypeText(type)),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                _selectedInvestmentType = newValue;
                                              });
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor, selecciona un tipo de inversión';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildResponsiveFormField(
                                        isMobile: isMobile,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText: 'Moneda',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.monetization_on,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.surface,
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
                                    ),
                                  ],
                                ),
                              ],
                              
                              if (isMobile) ...[
                                _buildResponsiveFormField(
                                  isMobile: isMobile,
                                  child: TextFormField(
                                    controller: _platformController,
                                    decoration: InputDecoration(
                                      labelText: 'Plataforma / Bróker (Opcional)',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.business,
                                          color: Colors.purple,
                                          size: 20,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                ),
                                
                                _buildResponsiveFormField(
                                  isMobile: isMobile,
                                  child: TextFormField(
                                    controller: _isinSymbolController,
                                    decoration: InputDecoration(
                                      labelText: 'ISIN / Símbolo (Opcional)',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.confirmation_number,
                                          color: Colors.indigo,
                                          size: 20,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildResponsiveFormField(
                                        isMobile: isMobile,
                                        child: TextFormField(
                                          controller: _platformController,
                                          decoration: InputDecoration(
                                            labelText: 'Plataforma / Bróker (Opcional)',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.business,
                                                color: Colors.purple,
                                                size: 20,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.surface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildResponsiveFormField(
                                        isMobile: isMobile,
                                        child: TextFormField(
                                          controller: _isinSymbolController,
                                          decoration: InputDecoration(
                                            labelText: 'ISIN / Símbolo (Opcional)',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.indigo.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.confirmation_number,
                                                color: Colors.indigo,
                                                size: 20,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.surface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                            isMobile: isMobile,
                          ),
                          
                          SizedBox(height: isMobile ? 24 : 32),
                          
                          _buildResponsiveSaveButton(isMobile),
                          
                          SizedBox(height: isMobile ? 16 : 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
*/