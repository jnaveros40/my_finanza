// lib/screens/investments/investment_movements_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/investment.dart'; // Importar el modelo Investment
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:intl/intl.dart'; // Para formatear fechas y moneda
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp
// Importar el diálogo para añadir/editar movimientos del historial
import 'package:mis_finanza/screens/investments/widgets/add_edit_investment_history_movement_dialog.dart'; // <-- Importar el diálogo de movimiento
// Importar pantalla para editar inversión
import 'package:mis_finanza/screens/investments/add_edit_investment_screen.dart';


class InvestmentMovementsScreen extends StatefulWidget {
  final String investmentId; // ID de la inversión cuyos movimientos vamos a gestionar

  const InvestmentMovementsScreen({super.key, required this.investmentId});

  @override
  _InvestmentMovementsScreenState createState() => _InvestmentMovementsScreenState();
}

class _InvestmentMovementsScreenState extends State<InvestmentMovementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Investment? _investment; // Para almacenar la inversión principal
  bool _isLoading = true; // Indicador de carga inicial
  bool _isSaving = false; // Indicador de carga al guardar cambios en la inversión principal

  // Lista mutable para gestionar el historial de movimientos (copia local del array history)
  List<Map<String, dynamic>> _investmentHistory = [];
  // Campos calculados para mostrar en esta pantalla
  double _currentQuantity = 0.0;
  double _totalInvested = 0.0;
  double _estimatedCurrentValue = 0.0;
  double _estimatedGainLoss = 0.0;
  double _totalDividends = 0.0;
  double _dividendUnits = 0.0; // Unidades específicas de dividendos


  @override
  void initState() {
    super.initState();
    _loadInvestment(); // Cargar la inversión principal y su historial
  }

  // Carga la inversión principal y su historial
  Future<void> _loadInvestment() async {
    if (currentUser == null) {
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
      _investment = await _firestoreService.getInvestmentById(widget.investmentId);

      if (_investment != null) {
        // Cargar el historial de movimientos del array
        _investmentHistory = List.from(_investment!.history ?? []);
        // Inicializar campos calculados con los valores del documento (si existen)
        _currentQuantity = _investment!.currentQuantity;
        _totalInvested = _investment!.totalInvested;
        _estimatedCurrentValue = _investment!.estimatedCurrentValue;
        _estimatedGainLoss = _investment!.estimatedGainLoss;
        _totalDividends = _investment!.totalDividends;

        // Recalcular campos calculados al cargar para asegurar consistencia
        _recalculateInvestmentFields();

      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: No se encontró la inversión.')),
         );
         Navigator.pop(context); // Regresar si la inversión no existe
      }

    } catch (e) {
      print('Error loading investment movements: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar movimientos: ${e.toString()}')),
      );
       Navigator.pop(context); // Regresar en caso de error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }  }

  // --- Lógica para recalcular los campos principales de la inversión ---
  void _recalculateInvestmentFields() {
      double totalQuantity = 0.0;
      double totalInvested = 0.0;
      double totalDividends = 0.0;
      double dividendUnits = 0.0; // Unidades específicas de dividendos
      // estimatedCurrentValue y estimatedGainLoss requieren precio actual (manual o API)

      for (var movementData in _investmentHistory) {
          final type = movementData['type'] as String? ?? 'other';
          final amount = (movementData['amount'] as num?)?.toDouble() ?? 0.0;
          final quantity = (movementData['quantity'] as num?)?.toDouble() ?? 0.0;
          final totalCost = (movementData['totalCost'] as num?)?.toDouble() ?? amount; // Usar totalCost si existe, si no, amount

          switch (type) {
              case 'compra':
              case 'aporte':
                  totalQuantity += quantity;
                  totalInvested += totalCost; // Sumar el costo total (monto + comisión)
                  break;
              case 'venta':
                  totalQuantity -= quantity;
                  // Las ventas no suman al total invertido en el sentido de capital aportado.
                  // El 'result' de la venta se usaría para ganancias/pérdidas realizadas.
                  break;
              case 'dividendo':
                  totalDividends += amount; // Los dividendos suman al total recibido
                  dividendUnits += quantity; // Sumar unidades específicas de dividendos
                  break;
              case 'retiro':
                 // Lógica para retiros (cantidad o valor)
                 // if (es retiro de activos) totalQuantity -= quantity;
                 break;
              // 'ajuste' y 'other' pueden requerir lógica específica
          }
      }

      // Asegurar que la cantidad no sea negativa
      if (totalQuantity < 0) totalQuantity = 0;

      // Actualizar el estado local con los campos recalculados
      setState(() {
          _currentQuantity = totalQuantity;
          _totalInvested = totalInvested;
          _totalDividends = totalDividends;
          _dividendUnits = dividendUnits;
          _estimatedGainLoss =_estimatedCurrentValue - _totalInvested;
          
      });
  }


   // Función para guardar la inversión principal con el historial y campos calculados actualizados
   Future<void> _saveInvestment() async {
       if (_investment == null || currentUser == null) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: No se puede guardar la inversión (datos incompletos).')),
           );
           return;
       }

       setState(() {
         _isSaving = true;
       });

       try {
            // Recalcular campos antes de guardar para asegurar los valores más recientes
           _recalculateInvestmentFields();

           // Crear una copia de la inversión principal con los campos actualizados
           final updatedInvestment = _investment!.copyWith(
               history: _investmentHistory, // Guardar el array local actualizado
               currentQuantity: _currentQuantity, // Guardar campos calculados
               totalInvested: _totalInvested,
               estimatedCurrentValue: _estimatedCurrentValue, // Este campo viene de la UI de edición principal o manual
               estimatedGainLoss: _estimatedGainLoss, // Recalculado
               totalDividends: _totalDividends, // Recalculado
               // Otros campos como name, type, currency, etc., no se editan aquí, se mantienen los originales
           );

           // Llamar al servicio para guardar la inversión principal
           await _firestoreService.saveInvestment(updatedInvestment);

           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Inversión actualizada con éxito.')),
           );

           // No navegamos de regreso, nos quedamos en la pantalla de movimientos

       } catch (e) {
           print('Error al guardar inversión desde movimientos: $e');
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al guardar la inversión: ${e.toString()}')),
           );
       } finally {
           setState(() {
             _isSaving = false;
           });
       }
   }



   // --- Función para mostrar el diálogo para añadir un nuevo movimiento al ARRAY ---
   void _showAddHistoryMovementDialog() {
       // Asegurarse de que tenemos la inversión cargada para pasar la moneda
       if (_investment == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: Inversión no cargada.')),
            );
            return;
       }

       showDialog( // <-- Mostrar el diálogo
           context: context,
           builder: (BuildContext context) {
               // Pasar la moneda seleccionada de la inversión al diálogo del movimiento
               return AddEditInvestmentHistoryMovementDialog(investmentCurrency: _investment!.currency); // <-- Pasar investmentCurrency
           },
       ).then((newMovementData) {
           // Cuando el diálogo se cierra con datos (un mapa), añadirlo al historial local
           if (newMovementData != null && newMovementData is Map<String, dynamic>) {
               setState(() {
                   _investmentHistory.add(newMovementData);
                   _recalculateInvestmentFields(); // Recalcular campos al añadir
                   _saveInvestment(); // Guardar la inversión principal con el historial actualizado
               });
           }
       });
   }

    // --- Función para mostrar el diálogo para editar un movimiento del ARRAY ---
   void _showEditHistoryMovementDialog(int index, Map<String, dynamic> movementData) {
       // Asegurarse de que tenemos la inversión cargada para pasar la moneda
        if (_investment == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: Inversión no cargada.')),
            );
            return;
       }

       showDialog( // <-- Mostrar el diálogo
           context: context,
           builder: (BuildContext context) {
               // Pasar la moneda seleccionada de la inversión al diálogo del movimiento
               return AddEditInvestmentHistoryMovementDialog(
                   movementData: movementData, // Pasamos el mapa del movimiento
                   investmentCurrency: _investment!.currency, // <-- Pasar investmentCurrency
               );
           },
       ).then((updatedMovementData) {
           // Cuando el diálogo se cierra con datos actualizados, reemplazar en el historial local
           if (updatedMovementData != null && updatedMovementData is Map<String, dynamic>) {
               setState(() {
                   _investmentHistory[index] = updatedMovementData;
                   _recalculateInvestmentFields(); // Recalcular campos al editar
                   _saveInvestment(); // Guardar la inversión principal con el historial actualizado
               });
           }
       });
   }

    // --- Función para confirmar y eliminar un movimiento del ARRAY ---
   Future<void> _confirmAndDeleteHistoryMovement(int index) async {
       bool confirm = await showDialog(
         context: context,
         builder: (BuildContext context) {
           return AlertDialog(
             title: Text('Confirmar Eliminación de Movimiento'),
             content: Text('¿Estás seguro de que deseas eliminar este movimiento del historial?'),
             actions: <Widget>[
               TextButton(
                 onPressed: () => Navigator.of(context).pop(false),
                 child: Text('Cancelar'),
               ),
               TextButton(
                 onPressed: () => Navigator.of(context).pop(true),
                 child: Text('Eliminar', style: TextStyle(color: Colors.red)),
               ),
             ],
           );
         },
       ) ?? false;

       if (confirm) {
         setState(() {
           _investmentHistory.removeAt(index);
           _recalculateInvestmentFields(); // Recalcular campos al eliminar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Movimiento eliminado del historial.')),
            );
            _saveInvestment(); // Guardar la inversión principal con el historial actualizado
         });
       }
   }


   // Helper para formatear un movimiento de historial (mapa) para mostrar en la lista
   String _formatHistoryMovement(Map<String, dynamic> movementData) {
       // Asegurarse de que los datos existen y tienen el tipo correcto
       final date = (movementData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
       final type = movementData['type'] as String? ?? 'other';
       final amount = (movementData['amount'] as num?)?.toDouble() ?? 0.0;
       final quantity = (movementData['quantity'] as num?)?.toDouble() ?? 0.0;
       final exchangeRate = (movementData['exchangeRate'] as num?)?.toDouble();
       final notes = movementData['notes'] as String?;
       final totalCost = (movementData['totalCost'] as num?)?.toDouble(); // Leer totalCost del mapa

       final formattedAmount = NumberFormat.currency(
         locale: 'en_US', // Ajusta la localización si es necesario
         // Usar la moneda seleccionada para la inversión principal (manejando null)
         symbol: _getCurrencySymbol(_investment?.currency ?? 'USD'), // <-- Manejar null
         decimalDigits: 2,
       ).format(amount);

        final formattedQuantity = quantity.toStringAsFixed(
           quantity.truncateToDouble() == quantity ? 0 : 2); // Mostrar decimales solo si los hay

       final formattedDate = DateFormat('yyyy-MM-dd').format(date);

       String details = '$formattedDate - ${_getMovementTypeText(type)}: $formattedAmount';

       if (quantity != 0) { // Mostrar cantidad si no es cero
           details += ' (${quantity > 0 ? '+' : ''}$formattedQuantity unidades)';
       }

       if (type == 'aporte' && exchangeRate != null) {
            final amountInLocalCurrency = (movementData['amountInLocalCurrency'] as num?)?.toDouble(); // Leer monto en moneda local del mapa
            final formattedLocalAmount = NumberFormat.currency(
              locale: 'en_US',
              // TODO: Usar la moneda local del usuario, no asumir COP
              symbol: _getCurrencySymbol('COP'), // Asumimos COP como moneda local para este ejemplo
              decimalDigits: 2,
            ).format(amountInLocalCurrency ?? 0.0);
           details += ' | COP: $formattedLocalAmount (@ $exchangeRate)'; // Mostrar monto y tasa de cambio
       }

        // Mostrar totalCost si es diferente del monto (ej. si hay comisión)
         if (totalCost != null && totalCost != amount) {
             final formattedTotalCost = NumberFormat.currency(
              locale: 'en_US',
               symbol: _getCurrencySymbol(_investment?.currency ?? 'USD'), // <-- Manejar null
              decimalDigits: 2,
            ).format(totalCost);
            details += ' | Costo Total: $formattedTotalCost';
         }


       if (notes != null && notes.isNotEmpty) {
           details += ' - $notes';
       }

       return details;
   }

    // Helper para obtener el texto a mostrar para el tipo de movimiento de inversión
    String _getMovementTypeText(String type) {
        switch (type) {
            case 'compra': return 'Compra';
            case 'venta': return 'Venta';
            case 'dividendo': return 'Dividendo';
            case 'ajuste': return 'Ajuste';
            case 'aporte': return 'Aporte';
            case 'retiro': return 'Retiro';
            case 'other': return 'Otro';
            default: return type;
        }
    }
     // Helper para obtener el símbolo de moneda (reutilizado de otras pantallas)
    String _getCurrencySymbol(String? currencyCode) { // <-- Aceptar String?
      if (currencyCode == null) return ''; // <-- Manejar null
      switch (currencyCode) {
        case 'COP': return '\$';
        case 'USD': return '\$';
        case 'EUR': return '€';
        case 'GBP': return '£';
        case 'JPY': return '¥';
        default: return currencyCode;
      }
    }

  // Helper methods for responsive design
  Widget _buildSummarySection(bool isMobile) {
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
              'Resumen de la Inversión',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: isMobile ? 16 : 20),
              if (isMobile) ...[
              _buildSummaryItemMobile(
                'Cantidad Actual',
                _currentQuantity.toStringAsFixed(_currentQuantity.truncateToDouble() == _currentQuantity ? 0 : 5),
                Icons.receipt_long,
                Colors.blue,
              ),
              const SizedBox(height: 10),
              _buildSummaryItemMobile(
                'Total Invertido',
                NumberFormat.currency(locale: 'en_US', symbol: _getCurrencySymbol(_investment!.currency), decimalDigits: 2).format(_totalInvested),
                Icons.input,
                Colors.orange,
              ),
              const SizedBox(height: 10),
              _buildSummaryItemMobile(
                'Unidades de Dividendos',
                _dividendUnits.toStringAsFixed(_dividendUnits.truncateToDouble() == _dividendUnits ? 0 : 5),
                Icons.receipt_long,
                Colors.purple,
              ),
              const SizedBox(height: 10),
              _buildSummaryItemMobile(
                'Total Dividendos',
                NumberFormat.currency(locale: 'en_US', symbol: _getCurrencySymbol(_investment!.currency), decimalDigits: 2).format(_totalDividends),
                Icons.paid,
                Colors.green,
              ),
              const SizedBox(height: 10),              _buildSummaryItemMobile(
                'Unidades Totales',
                (_currentQuantity + _dividendUnits).toStringAsFixed((_currentQuantity + _dividendUnits).truncateToDouble() == (_currentQuantity + _dividendUnits) ? 0 : 5),
                Icons.receipt_long,
                Colors.indigo,
              ),
              const SizedBox(height: 10),
              _buildSummaryItemMobile(
                'Ratio Dividendos',
                _totalInvested > 0 ? '${((_totalDividends / _totalInvested) * 100).toStringAsFixed(2)}%' : '0.00%',
                Icons.trending_up,
                Colors.teal,
              ),] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Cantidad Actual',
                      _currentQuantity.toStringAsFixed(_currentQuantity.truncateToDouble() == _currentQuantity ? 0 : 5),
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Invertido',
                      NumberFormat.currency(locale: 'en_US', symbol: _getCurrencySymbol(_investment!.currency), decimalDigits: 2).format(_totalInvested),
                      Icons.input,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Unidades de Dividendos',
                      _dividendUnits.toStringAsFixed(_dividendUnits.truncateToDouble() == _dividendUnits ? 0 : 5),
                      Icons.receipt_long,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(                    child: _buildSummaryItem(
                      'Total Dividendos',
                      NumberFormat.currency(locale: 'en_US', symbol: _getCurrencySymbol(_investment!.currency), decimalDigits: 2).format(_totalDividends),
                      Icons.paid,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Unidades Totales',
                      (_currentQuantity + _dividendUnits).toStringAsFixed((_currentQuantity + _dividendUnits).truncateToDouble() == (_currentQuantity + _dividendUnits) ? 0 : 5),
                      Icons.receipt_long,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      'Ratio Dividendos',
                      _totalInvested > 0 ? '${((_totalDividends / _totalInvested) * 100).toStringAsFixed(2)}%' : '0.00%',
                      Icons.trending_up,
                      Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Versión más pequeña de _buildSummaryItem para vista móvil
  Widget _buildSummaryItemMobile(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8), // Más pequeño que el original
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8), // Más pequeño
          ),
          child: Icon(icon, color: color, size: 16), // Icono más pequeño
        ),
        const SizedBox(width: 10), // Espacio más compacto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Texto más pequeño
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Más pequeño que titleMedium
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14, // Texto más pequeño
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovementsSection(bool isMobile) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de Movimientos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _showAddHistoryMovementDialog,
                    tooltip: 'Añadir Movimiento',
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            
            if (_investmentHistory.isEmpty)
              _buildEmptyMovements(isMobile)
            else
              _buildMovementsList(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMovements(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: isMobile ? 48 : 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'No hay movimientos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay movimientos registrados para esta inversión.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 16 : 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Añadir Primer Movimiento'),
              onPressed: _showAddHistoryMovementDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 12 : 16,
                ),
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

  Widget _buildMovementsList(bool isMobile) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _investmentHistory.length,
      separatorBuilder: (context, index) => SizedBox(height: isMobile ? 8 : 12),
      itemBuilder: (context, index) {
        final movementData = _investmentHistory[index];
        return _buildMovementCard(movementData, index, isMobile);
      },
    );
  }

  Widget _buildMovementCard(Map<String, dynamic> movementData, int index, bool isMobile) {
    final date = (movementData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final type = movementData['type'] as String? ?? 'other';
    final amount = (movementData['amount'] as num?)?.toDouble() ?? 0.0;
    final quantity = (movementData['quantity'] as num?)?.toDouble() ?? 0.0;
    final notes = movementData['notes'] as String?;
    
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final formattedAmount = NumberFormat.currency(
      locale: 'en_US',
      symbol: _getCurrencySymbol(_investment?.currency ?? 'USD'),
      decimalDigits: 2,
    ).format(amount);
    
    Color typeColor = _getMovementTypeColor(type);
    IconData typeIcon = _getMovementTypeIcon(type);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditHistoryMovementDialog(index, movementData),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getMovementTypeText(type),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedAmount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (quantity != 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${quantity > 0 ? '+' : ''}${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 5)} unidades',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _showEditHistoryMovementDialog(index, movementData),
                    tooltip: 'Editar',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      minimumSize: const Size(32, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () => _confirmAndDeleteHistoryMovement(index),
                    tooltip: 'Eliminar',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      minimumSize: const Size(32, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMovementTypeColor(String type) {
    switch (type) {
      case 'compra':
      case 'aporte':
        return Colors.blue;
      case 'venta':
      case 'retiro':
        return Colors.orange;
      case 'dividendo':
        return Colors.green;
      case 'ajuste':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMovementTypeIcon(String type) {
    switch (type) {
      case 'compra':
        return Icons.shopping_cart;
      case 'venta':
        return Icons.sell;
      case 'dividendo':
        return Icons.paid;
      case 'aporte':
        return Icons.input;
      case 'retiro':
        return Icons.output;
      case 'ajuste':
        return Icons.tune;
      default:
        return Icons.receipt;
    }
  }

  @override  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading || _isSaving) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_investment?.name ?? 'Cargando Movimientos'),
          backgroundColor: isDarkTheme ? Theme.of(context).colorScheme.surface : Colors.black,
          foregroundColor: isDarkTheme ? null : Colors.white,
          iconTheme: IconThemeData(
            color: isDarkTheme ? null : Colors.white,
          ),
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _isSaving ? 'Guardando...' : 'Cargando datos...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }    if (_investment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: isDarkTheme ? Theme.of(context).colorScheme.surface : Colors.black,
          foregroundColor: isDarkTheme ? null : Colors.white,
          iconTheme: IconThemeData(
            color: isDarkTheme ? null : Colors.white,
          ),
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'No se pudo cargar la inversión.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }    return Scaffold(
      appBar: AppBar(
        title: Text('Movimientos de ${_investment!.name}'),
        backgroundColor: isDarkTheme ? Theme.of(context).colorScheme.surface : Colors.black,
        foregroundColor: isDarkTheme ? null : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkTheme ? null : Colors.white,
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isDarkTheme ? Theme.of(context).colorScheme.primary : Colors.white,
            ),
            tooltip: 'Editar Inversión',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditInvestmentScreen(investment: _investment),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummarySection(isMobile),
                SizedBox(height: isMobile ? 20 : 24),
                _buildMovementsSection(isMobile),
                SizedBox(height: isMobile ? 20 : 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
