// lib/screens/movements/movements_screen.dart
/*
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// Importar el modelo Movement
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/category.dart';
// Eliminar importación de PaymentMethod si no se usa en la UI
// import 'package:mis_finanza/models/payment_method.dart';

import 'package:mis_finanza/services/firestore_service/index.dart';

import 'package:mis_finanza/screens/movements/add_movement_screen.dart';
// Importar la pantalla de edición de movimientos
import 'package:mis_finanza/screens/movements/edit_movement_screen.dart';
import 'package:mis_finanza/screens/movements/recurring_payments_screen.dart';

import 'package:intl/intl.dart';
// import 'package:collection/collection.dart'; // Para firstWhereOrNull
import 'package:speech_to_text/speech_to_text.dart' as stt; // Para reconocimiento de voz
import 'package:shared_preferences/shared_preferences.dart'; // Para persistencia de filtros


class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  _MovementsScreenState createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  // Instancia para reconocimiento de voz
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  // Estado para los filtros
  String _selectedMovementTypeFilter = 'all';
  String? _selectedCategoryFilter; // Nuevo: filtro de categoría
  String _searchText = ''; // Nuevo: filtro de búsqueda por descripción
  List<Category> _categories = []; // Nuevo: lista de categorías disponibles
  final List<String> _movementTypeFilters = ['all', 'expense', 'income', 'transfer', 'payment'];
  
  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();

  // Variables para el filtrado por fechas
  DateTime? _startDate;
  DateTime? _endDate;

  // Controlador para el campo de texto de fecha
  final TextEditingController _dateRangeController = TextEditingController();

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


  @override
  void initState() {
    super.initState();
    _loadFiltersFromPrefs(); // Restaurar filtros persistentes
    _loadCategories(); // Cargar categorías al iniciar
    // Inicializar el rango de fechas con los últimos 30 días por defecto
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(Duration(days: 30));
    // Actualizar el texto del controlador de fecha inicial
    _updateDateRangeText();
    // Inicializar el reconocimiento de voz
    _initSpeech();
  }
  
  // Inicializar el reconocimiento de voz
  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Estado del reconocimiento: $status'),
        onError: (error) => print('Error de reconocimiento: $error'),
      );
      if (!available) {
        //print('El reconocimiento de voz no está disponible en este dispositivo');
      }
    } catch (e) {
      //print('Error al inicializar el reconocimiento de voz: $e');
    }
  }
  @override
  void dispose() {
    // Limpiar los controladores cuando el widget se desecha
    _dateRangeController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  // Nuevo: Función para cargar categorías
  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategories().first;
      setState(() {
        _categories = categories;
      });
    } catch (e) {}
  }

  // Función para obtener las categorías filtradas según el tipo de movimiento
  List<Category> _getFilteredCategories() {
    if (_selectedMovementTypeFilter == 'all') {
      return _categories;
    } else if (_selectedMovementTypeFilter == 'transfer' || _selectedMovementTypeFilter == 'payment') {
      return []; // No mostrar categorías para transferencias y pagos
    } else {
      // Filtrar categorías que coincidan con el tipo de movimiento (expense o income)
      return _categories.where((category) => category.type == _selectedMovementTypeFilter).toList();
    }
  }

  // Helper para obtener el texto a mostrar para el tipo de movimiento
  String _getMovementTypeText(String type) {
      switch (type) {
          case 'expense': return 'Gasto';
          case 'income': return 'Ingreso';
          case 'transfer': return 'Transferencia';
          case 'payment': return 'Pago';
          case 'all': return 'Todos';
          default: return type;
      }
  }


  // --- Helper para obtener el nombre de la cuenta ---
  Future<String> _getAccountName(String accountId) async {
     Account? account = await AccountService.getAccountById(accountId);
     return account?.name ?? 'Cuenta Desconocida';
  }

   // --- Helper para obtener el nombre de la categoría ---
   Future<String> _getCategoryName(String categoryId) async {
      Category? category = await CategoryService.getCategoryById(categoryId);
      return category?.name ?? 'Categoría Desconocida';
   }

    // Eliminar helper para método de pago si no se usa en la UI
    // Future<String> _getPaymentMethodName(String methodId) async {
    //    PaymentMethod? method = await _firestoreService.getPaymentMethodById(methodId);
    //    return method?.name ?? 'Método Desconocido';
    // }

   // --- Helper para obtener el símbolo de moneda ---
   String _getCurrencySymbol(String currencyCode) {
     switch (currencyCode.toUpperCase()) { // Convertir a mayúsculas para comparación segura
       case 'COP': return '\$';
       case 'USD': return '\$';
       case 'EUR': return '€';
       case 'GBP': return '£';
       case 'JPY': return '¥';
       default: return currencyCode;
     }
   }


   // --- Función para confirmar y eliminar movimiento ---
   Future<bool> _confirmAndDeleteMovement(BuildContext context, Movement movement) async {
       bool confirm = await showDialog(
         context: context,
         builder: (BuildContext context) {
           return AlertDialog(
             title: Text('Confirmar Eliminación'),
             content: Text('¿Estás seguro de que deseas eliminar este movimiento (${_getMovementTypeText(movement.type)}: "${movement.description}")? Esta acción revertirá el monto en la cuenta(s) asociada(s).'),
             actions: <Widget>[
               TextButton(
                 onPressed: () => Navigator.of(context).pop(false),
                 child: Text('Cancelar'),
               ),
               TextButton(
                 onPressed: () => Navigator.of(context).pop(true),
                 child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
               ),
             ],
           );
         },
       ) ?? false;

       if (confirm) {
         try {
           if (movement.id != null) {
             await MovementService.deleteMovement(movement.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Movimiento (${_getMovementTypeText(movement.type)}: "${movement.description}") eliminado.')),
              );
              return true;
           } else {
              //print('Error: Intentando eliminar movimiento sin ID.');
           }
         } catch (e) {
           //print('Error al eliminar movimiento: $e');
         }
       }
       return false;
   }


  // --- Helper para filtrar movimientos por rango de fechas ---
  List<Movement> _filterMovementsByDate(List<Movement> movements) {
    if (_startDate == null && _endDate == null) return movements;
    return movements.where((m) {
      final date = m.dateTime;
      // Ajustar fechas para incluir todo el día
      final start = _startDate != null ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day) : null;
      final end = _endDate != null ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59) : null;

      if (start != null && date.isBefore(start)) return false;
      if (end != null && date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  // --- Función para actualizar el texto del controlador de fecha ---
  void _updateDateRangeText() {
    if (_startDate == null || _endDate == null) {
      _dateRangeController.text = '';
    } else {
      _dateRangeController.text = '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    }
  }
  // --- Widget moderno para el campo de búsqueda ---
  Widget _buildSearchField(BuildContext context) {
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
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
          _saveFiltersToPrefs();
        },
        decoration: InputDecoration(
          labelText: 'Buscar por descripción',
          hintText: 'Ej: mercado, gasolina, salario...',
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
              Icons.search,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          suffixIcon: _searchText.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchText = '';
                        _searchController.clear();
                      });
                      _saveFiltersToPrefs();
                    },
                    tooltip: 'Limpiar búsqueda',
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // --- Widget moderno para el selector de rango de fechas ---
  Widget _buildModernDateRangeSelector(BuildContext context) {
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
        controller: _dateRangeController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Rango de Fechas',
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
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.date_range,
              size: 20,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          suffixIcon: (_startDate != null || _endDate != null)
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    onPressed: _clearDateRange,
                    tooltip: 'Limpiar filtro de fechas',
                  ),
                )
              : null,
        ),
        onTap: () => _selectDateRange(context),
      ),
    );
  }


  // --- Función para seleccionar rango de fechas ---
   Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(Duration(days: 30)), // 30 días atrás por defecto
      end: _endDate ?? DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // Fecha mínima
      lastDate: DateTime(2101), // Fecha máxima
      initialDateRange: initialDateRange,
      // Los colores del DateRangePicker se adaptan al tema
    );
    //prueba de avance
    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) { // Verificar si el rango cambió
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _updateDateRangeText(); // Actualizar el texto del controlador
         //print('DEBUG: Rango de fechas seleccionado: \\${_startDate} a \\${_endDate}'); // DEBUG
      });
      _saveFiltersToPrefs();
    }
  }

  // --- Función para limpiar rango de fechas ---
  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _updateDateRangeText(); // Limpiar el texto del controlador
       //print('DEBUG: Rango de fechas limpiado.'); // DEBUG
    });
    _saveFiltersToPrefs();
  }


  // Función para iniciar/detener el reconocimiento de voz
  Future<void> _toggleListening() async {
    if (!_isListening) {
      _recognizedText = '';
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
              if (result.finalResult) {
                _processVoiceInput(_recognizedText);
                _isListening = false;
              }
            });
          },
          localeId: 'es_ES', // Idioma español
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Procesar el texto reconocido para extraer información del movimiento
  void _processVoiceInput(String text) {
    if (text.isEmpty) return;
    
    // Extraer información del texto reconocido
    Map<String, dynamic> extractedData = _extractMovementData(text);
    
    // Mostrar un diálogo con el texto reconocido y la información extraída
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Texto reconocido'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_recognizedText, style: TextStyle(fontWeight: FontWeight.bold)),
                Divider(),
                SizedBox(height: 10),
                Text('Información detectada:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                if (extractedData['type'] != null)
                  Text('Tipo: ${_getMovementTypeText(extractedData['type'])}'),
                if (extractedData['amount'] != null)
                  Text('Monto: ${extractedData['amount']}'),
                if (extractedData['description'] != null)
                  Text('Descripción: ${extractedData['description']}'),
                if (extractedData['category'] != null)
                  Text('Categoría: ${extractedData['category']}'),
                SizedBox(height: 20),
                Text('¿Deseas crear un movimiento con esta información?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToAddMovementWithVoiceData(extractedData);
              },
              child: Text('Crear Movimiento'),
            ),
          ],
        );
      },
    );
  }

  // Extraer información del texto reconocido
  Map<String, dynamic> _extractMovementData(String text) {
    // Convertir texto a minúsculas para facilitar la detección
    String lowerText = text.toLowerCase();
    Map<String, dynamic> data = {};
    
    // Detectar tipo de movimiento
    if (lowerText.contains('gasto') || lowerText.contains('compra') || lowerText.contains('pagué') || 
        lowerText.contains('pague') || lowerText.contains('gasté') || lowerText.contains('gaste')) {
      data['type'] = 'expense';
    } else if (lowerText.contains('ingreso') || lowerText.contains('recibí') || lowerText.contains('recibi') || 
               lowerText.contains('cobré') || lowerText.contains('cobre') || lowerText.contains('me pagaron')) {
      data['type'] = 'income';
    } else if (lowerText.contains('transferencia') || lowerText.contains('transferí') || 
               lowerText.contains('transfiri') || lowerText.contains('envié') || lowerText.contains('envie')) {
      data['type'] = 'transfer';
    } else if (lowerText.contains('pago') || lowerText.contains('pagué a') || lowerText.contains('pague a')) {
      data['type'] = 'payment';
    }
    
    // Detectar monto - Múltiples patrones para mayor precisión
    double? parsedAmount;
    
    // Patrón 1: Número seguido de moneda (más específico)
    RegExp amountRegex1 = RegExp(r'\b(\d+[.,]?\d*)\s*(pesos|dólares|euros|\$|€|£|\bUSD\b|\bEUR\b|\bCOP\b)\b', caseSensitive: false);
    Match? amountMatch1 = amountRegex1.firstMatch(text);
    
    // Patrón 2: Palabras clave de dinero seguidas de número
    RegExp amountRegex2 = RegExp(r'(valor|monto|cantidad|precio|costo|total)\s+(?:de\s+)?(\d+[.,]?\d*)', caseSensitive: false);
    Match? amountMatch2 = amountRegex2.firstMatch(text);
    
    // Patrón 3: Simplemente buscar números (menos específico, usar como último recurso)
    RegExp amountRegex3 = RegExp(r'\b(\d+[.,]?\d*)\b', caseSensitive: false);
    Match? amountMatch3 = amountRegex3.firstMatch(text);
    
    // Procesar según el patrón que haya encontrado coincidencia (en orden de prioridad)
    String amount = '';
    if (amountMatch1 != null) {
      amount = amountMatch1.group(1) ?? '';
      //print('Monto detectado con patrón 1: $amount');
    } else if (amountMatch2 != null) {
      amount = amountMatch2.group(2) ?? '';
      //print('Monto detectado con patrón 2: $amount');
    } else if (amountMatch3 != null) {
      amount = amountMatch3.group(1) ?? '';
      //print('Monto detectado con patrón 3: $amount');
    }
    
    // Procesar el monto si se encontró alguno
    if (amount.isNotEmpty) {
      // Usar el parser especial para español
      parsedAmount = parseSpanishAmount(amount);
      if (parsedAmount != null) {
        data['amount'] = parsedAmount;
        //print('Monto procesado correctamente (parser español): $parsedAmount');
      } else {
        //print('No se pudo convertir "$amount" a un número');
      }
    } else {
      //print('No se detectó ningún monto en el texto');
    }
    // Extraer descripción (después de palabras clave)
    List<String> descriptionKeywords = ['por', 'para', 'de', 'en', 'concepto'];
    for (String keyword in descriptionKeywords) {
      RegExp descRegex = RegExp('$keyword\\s+(.+?)(?=\\s+por|\\s+para|\\s+de|\\s+en|\\s+concepto|\\s+\\d)', caseSensitive: false);
      Match? descMatch = descRegex.firstMatch(text);
      if (descMatch != null) {
        String desc = descMatch.group(1)?.trim() ?? '';
        // Eliminar el monto detectado de la descripción si aparece
        if (amount.isNotEmpty && desc.contains(amount)) {
          desc = desc.replaceAll(amount, '').replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        data['description'] = desc;
        break;
      }
    }
    // Si no se encontró descripción con el método anterior, usar todo el texto como descripción
    if (data['description'] == null) {
      String desc = text;
      // Eliminar el monto detectado de la descripción si aparece
      if (amount.isNotEmpty && desc.contains(amount)) {
        desc = desc.replaceAll(amount, '').replaceAll(RegExp(r'\s+'), ' ').trim();
      }
      data['description'] = desc;
    }
    
    // Buscar categoría basada en palabras clave
    // Esto es básico, idealmente deberías buscar coincidencias con las categorías existentes
    for (Category category in _categories) {
      if (lowerText.contains(category.name.toLowerCase())) {
        data['category'] = category.name;
        data['categoryId'] = category.id;
        break;
      }
    }
    
    return data;
  }

  // Navegar a la pantalla de añadir movimiento con datos de voz
  void _navigateToAddMovementWithVoiceData(Map<String, dynamic> extractedData) {
    // Pasar los datos extraídos como argumentos a la pantalla de añadir movimiento
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMovementScreen(),
        // Pasar los datos extraídos como argumentos
        settings: RouteSettings(arguments: extractedData),
      ),
    ).then((_) {
      // Actualizar la lista de movimientos cuando regrese
      setState(() {});
    });
  }
  // --- Persistencia de filtros con SharedPreferences ---
  Future<void> _saveFiltersToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('movements_filter_type', _selectedMovementTypeFilter);
    await prefs.setString('movements_filter_category', _selectedCategoryFilter ?? '');
    await prefs.setString('movements_filter_search', _searchText);
    await prefs.setString('movements_filter_start', _startDate != null ? _startDate!.toIso8601String() : '');
    await prefs.setString('movements_filter_end', _endDate != null ? _endDate!.toIso8601String() : '');
  }

  Future<void> _loadFiltersFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('movements_filter_type');
    final category = prefs.getString('movements_filter_category');
    final search = prefs.getString('movements_filter_search');
    final start = prefs.getString('movements_filter_start');
    final end = prefs.getString('movements_filter_end');
    setState(() {
      if (type != null && _movementTypeFilters.contains(type)) {
        _selectedMovementTypeFilter = type;
      }
      _selectedCategoryFilter = (category != null && category.isNotEmpty) ? category : null;
      _searchText = search ?? '';
      _searchController.text = _searchText;
      if (start != null && start.isNotEmpty) {
        _startDate = DateTime.tryParse(start);
      }
      if (end != null && end.isNotEmpty) {
        _endDate = DateTime.tryParse(end);
      }
      _updateDateRangeText();
    });
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Obtener las categorías filtradas
    final filteredCategories = _getFilteredCategories();

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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Movimientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Historial de transacciones',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.repeat,
                color: Theme.of(context).colorScheme.secondary,
              ),
              tooltip: 'Pagos recurrentes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecurringPaymentsScreen()),
                );
              },
            ),
          ),
        ],
      ),      // Botones flotantes modernos
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón para reconocimiento de voz
          Container(
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
            child: FloatingActionButton(
              heroTag: 'btnVoice',
              onPressed: _toggleListening,
              tooltip: 'Añadir movimiento por voz',
              backgroundColor: _isListening 
                  ? Colors.red.shade400 
                  : Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            ),
          ),
          const SizedBox(height: 16),
          // Botón para añadir movimiento manualmente
          Container(
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
            child: FloatingActionButton(
              heroTag: 'btnAdd',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMovementScreen(),
                  ),
                ).then((_) {
                  // Opcional: Actualizar la lista de movimientos cuando regrese
                  setState(() {});
                });
              },
              tooltip: 'Añadir movimiento',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),      body: Column(
        children: [
          // Contenedor moderno para los filtros
          Container(
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
                // Header del contenedor de filtros
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filtros de Búsqueda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Filtro por tipo de movimiento
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
                          color: _getMovementTypeColor(_selectedMovementTypeFilter).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getMovementTypeIcon(_selectedMovementTypeFilter),
                          size: 20,
                          color: _getMovementTypeColor(_selectedMovementTypeFilter),
                        ),
                      ),
                    ),
                    value: _selectedMovementTypeFilter,
                    items: _movementTypeFilters.map((String type) {
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
                          _selectedMovementTypeFilter = newValue;
                          _selectedCategoryFilter = null;
                        });
                        _saveFiltersToPrefs();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Filtro por categoría
                if (filteredCategories.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonFormField<String?>(
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
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        helperText: _selectedMovementTypeFilter == 'all'
                            ? null
                            : 'Categorías de ${_getMovementTypeText(_selectedMovementTypeFilter)}',
                      ),
                      value: _selectedCategoryFilter,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: const Text('Todas las categorías'),
                        ),
                        ...filteredCategories.map((Category category) {
                          return DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategoryFilter = newValue;
                        });
                        _saveFiltersToPrefs();
                      },
                    ),
                  ),
                if (filteredCategories.isNotEmpty) const SizedBox(height: 16),                // Selector de rango de fechas mejorado
                _buildModernDateRangeSelector(context),
                const SizedBox(height: 16),
                // Campo de búsqueda por descripción
                _buildSearchField(context),
              ],
            ),
          ),
          Expanded(
            // Escuchar el stream de movimientos
            // No pasamos el filtro de fecha aquí, lo aplicaremos después de obtener todos los movimientos
            child: StreamBuilder<List<Movement>>(
              stream: MovementService.getMovements(typeFilter: _selectedMovementTypeFilter), // Pasar solo el filtro de tipo
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Usar color del tema para el indicador de carga
                  return _buildLoadingState();
                }
                if (snapshot.hasError) {
                   //print('Error cargando movimientos: ${snapshot.error}');
                   // Usar color de texto del tema para el mensaje de error
                  return _buildErrorState(snapshot.error.toString());
                }
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // Usar color de texto del tema para el mensaje de lista vacía
                  return _buildEmptyState('No tienes movimientos de este tipo aún.');
                }

                var movements = snapshot.data!; // Lista de Movement

                // --- Aplicar filtro de fecha ---
                movements = _filterMovementsByDate(movements);
                // -----------------------------                // Aplicar filtro de categoría si está seleccionado
                if (_selectedCategoryFilter != null) {
                  movements = movements.where((movement) =>
                    movement.categoryId == _selectedCategoryFilter
                  ).toList();
                }

                // Aplicar filtro de búsqueda por descripción
                if (_searchText.isNotEmpty) {
                  movements = movements.where((movement) =>
                    movement.description.toLowerCase().contains(_searchText.toLowerCase()) ||
                    (movement.notes != null && movement.notes!.toLowerCase().contains(_searchText.toLowerCase()))
                  ).toList();
                }if (movements.isEmpty) {
                  return _buildEmptyState('No hay movimientos con los filtros seleccionados.');
                }

                // Construir la lista de movimientos
                return _buildMovementsList(movements);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Método para construir la lista moderna de movimientos ---
  Widget _buildMovementsList(List<Movement> movements) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: movements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final movement = movements[index];
        return _buildMovementTile(movement);
      },
    );
  }

  // --- Método para construir tile moderno de movimiento ---
  Widget _buildMovementTile(Movement movement) {
    return Dismissible(
      key: Key(movement.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _confirmAndDeleteMovement(context, movement);
      },
      onDismissed: (direction) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Movimiento (${_getMovementTypeText(movement.type)}: "${movement.description}") eliminado.'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      },
      child: Container(
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: _buildMovementData(movement),
          builder: (context, relatedSnapshot) {
            if (relatedSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingMovementTile(movement);
            }
            if (relatedSnapshot.hasError) {
              return _buildErrorMovementTile(movement, relatedSnapshot.error.toString());
            }
            return _buildCompleteMovementTile(movement, relatedSnapshot.data!);
          },
        ),
      ),
    );
  }

  // --- Método para construir datos del movimiento ---
  Future<Map<String, dynamic>> _buildMovementData(Movement movement) async {
    final results = await Future.wait([
      _getAccountName(movement.accountId),
      movement.destinationAccountId != null
          ? _getAccountName(movement.destinationAccountId!)
          : Future.value(null),
      movement.type == 'expense' || movement.type == 'income'
          ? _getCategoryName(movement.categoryId)
          : Future.value(null),
      AccountService.getAccountById(movement.accountId).then((acc) => acc?.currency ?? '???'),
    ]);

    return {
      'accountName': results[0] as String,
      'destinationAccountName': results[1],
      'categoryName': results[2],
      'currencyCode': results[3] as String,
    };
  }

  // --- Estados modernos para la lista ---
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
            'Cargando movimientos...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar movimientos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin movimientos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMovementScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
              icon: const Icon(Icons.add),
              label: const Text('Añadir Movimiento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Método para tile de movimiento en carga ---
  Widget _buildLoadingMovementTile(Movement movement) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sync,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cargando detalles...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // --- Método para tile de movimiento con error ---
  Widget _buildErrorMovementTile(Movement movement, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Error loading details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            movement.amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getMovementTypeColor(movement.type),
            ),
          ),
        ],
      ),
    );
  }

  // --- Método para tile completo de movimiento ---
  Widget _buildCompleteMovementTile(Movement movement, Map<String, dynamic> data) {
    String accountName = data['accountName'] ?? 'Desconocida';
    String? destinationAccountName = data['destinationAccountName'];
    String? categoryName = data['categoryName'];
    String currencyCode = data['currencyCode'] ?? '???';

    String formattedAmount = NumberFormat.currency(
      locale: 'es_CO',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 0,
    ).format(movement.amount);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditMovementScreen(movement: movement),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono del tipo de movimiento
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMovementTypeColor(movement.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getMovementTypeColor(movement.type).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                _getMovementTypeIcon(movement.type),
                color: _getMovementTypeColor(movement.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Información del movimiento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y badge de tipo
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          movement.description,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Detalles del movimiento
                  _buildMovementDetails(movement, accountName, destinationAccountName, categoryName),
                  const SizedBox(height: 8),
                  // Fecha
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(movement.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Monto y flecha
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _getMovementTypeColor(movement.type),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Método para construir detalles del movimiento ---
  Widget _buildMovementDetails(Movement movement, String accountName, String? destinationAccountName, String? categoryName) {
    List<Widget> details = [];

    // Cuenta de origen/destino
    details.add(
      Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              movement.type == 'income' ? 'Destino: $accountName' : 'Origen: $accountName',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Cuenta de destino para transferencias y pagos
    if ((movement.type == 'transfer' || movement.type == 'payment') && 
        destinationAccountName != null && destinationAccountName.isNotEmpty) {
      details.add(
        Row(
          children: [
            Icon(
              Icons.account_balance,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Destino: $destinationAccountName',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Categoría para gastos e ingresos
    if ((movement.type == 'expense' || movement.type == 'income') && 
        categoryName != null && categoryName.isNotEmpty) {
      details.add(
        Row(
          children: [
            Icon(
              Icons.category,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                categoryName,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Notas si existen
    if (movement.notes != null && movement.notes!.isNotEmpty) {
      details.add(
        Row(
          children: [
            Icon(
              Icons.note,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                movement.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.map((detail) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: detail,
        ),
      ).toList(),
    );
  }

}

// Utilidad para convertir expresiones como "500mil", "1 millón", "534231" a double
// Soporta: 500mil, 1 millón, 2.5 millones, 534231, etc.
double? parseSpanishAmount(String input) {
  String normalized = input.toLowerCase().replaceAll('.', '').replaceAll(',', '');
  // Reemplazar palabras clave por multiplicadores
  if (normalized.contains('millón') || normalized.contains('millones')) {
    normalized = normalized.replaceAll('millones', '000000');
    normalized = normalized.replaceAll('millón', '000000');
  } else if (normalized.contains('mil')) {
    normalized = normalized.replaceAll('mil', '000');
  }
  // Eliminar espacios
  normalized = normalized.replaceAll(' ', '');
  // Extraer solo números
  RegExp numReg = RegExp(r'\d+');
  final match = numReg.stringMatch(normalized);
  if (match != null) {
    return double.tryParse(match);
  }
  // Si no se pudo, intentar parsear como double normal
  return double.tryParse(input.replaceAll('.', '').replaceAll(',', ''));
}
*/