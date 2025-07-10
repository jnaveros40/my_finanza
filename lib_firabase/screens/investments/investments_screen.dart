// lib/screens/investments/investments_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/investment.dart'; // Importar el modelo Investment
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:mis_finanza/services/stock_quote_cache_service.dart';
import 'package:intl/intl.dart'; 
//import 'package:mis_finanza/screens/investments/add_edit_investment_screen.dart';

import 'package:mis_finanza/screens/investments/investment_movements_screen.dart';
import 'package:mis_finanza/screens/investments/upcoming_dividends_screen.dart';
import 'package:mis_finanza/models/stock_quote.dart'; // Importar modelo StockQuote


class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  _InvestmentsScreenState createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;  // Estado para el filtro por tipo
  String? _selectedTypeFilter; // Filtro por tipo de inversión (ej. 'stocks', 'funds', o null para "Todos")
    // Estado para el filtro por plataforma
  String? _selectedPlatformFilter; // Filtro por plataforma (ej. 'eToro', 'Binance', o null para "Todas")
    // Estado para el ordenamiento
  String _selectedSortFilter = 'valor_actual_desc'; // Ordenamiento por defecto: valor actual descendente
  
  // Estado para controlar la expansión del card de filtros en móviles
  bool _isFiltersExpanded = false;// Lista de tipos de inversión disponibles (debe coincidir con los valores guardados)
   final List<String> _investmentTypesValues = ['stocks', 'funds', 'crypto', 'real_estate', 'bonds', 'other'];

   // Lista de opciones de ordenamiento disponibles
   final List<Map<String, String>> _sortOptions = [
     {'value': 'valor_actual_desc', 'label': 'Valor Actual (Mayor a Menor)'},
     {'value': 'valor_actual_asc', 'label': 'Valor Actual (Menor a Mayor)'},
     {'value': 'total_invertido_desc', 'label': 'Total Invertido (Mayor a Menor)'},
     {'value': 'total_invertido_asc', 'label': 'Total Invertido (Menor a Mayor)'},
     {'value': 'ganancia_perdida_desc', 'label': 'Ganancia/Pérdida (Mayor a Menor)'},
     {'value': 'ganancia_perdida_asc', 'label': 'Ganancia/Pérdida (Menor a Mayor)'},
     {'value': 'dividendos_desc', 'label': 'Dividendos (Mayor a Menor)'},
     {'value': 'dividendos_asc', 'label': 'Dividendos (Menor a Mayor)'},
     {'value': 'nombre_asc', 'label': 'Nombre (A-Z)'},
     {'value': 'nombre_desc', 'label': 'Nombre (Z-A)'},
   ];


   // Helper para obtener el texto a mostrar para el tipo de inversión (usado en la lista y el filtro)
  String _getInvestmentTypeText(String type) {
      switch (type) {
          case 'stocks': return 'Acciones';
          case 'funds': return 'Fondos de Inversión';
          case 'crypto': return 'Criptomonedas';
          case 'real_estate': return 'Bienes Raíces';
          case 'bonds': return 'Bonos'; // Añadido
          case 'other': return 'Otra';
          default: return type;
      }
  }    // Helper para obtener el texto a mostrar para el filtro de tipo
   String _getInvestmentTypeFilterText(String? type) {
      if (type == null) return 'Todos los Tipos';
       return _getInvestmentTypeText(type); // Reutiliza el helper principal
   }

   // Helper para obtener el texto del filtro de ordenamiento
   String _getSortFilterText(String sortValue) {
     final option = _sortOptions.firstWhere(
       (option) => option['value'] == sortValue,
       orElse: () => {'value': '', 'label': 'Desconocido'},
     );
     return option['label'] ?? 'Desconocido';
   }


   // Helper para obtener el símbolo de moneda (reutilizado de otras pantallas)
   String _getCurrencySymbol(String? currencyCode) { // <-- Aceptar String? para manejar null
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

   // Helper para formatear moneda (reutilizado de otras pantallas)
   String _formatCurrency(double amount, String? currencyCode) { // <-- Aceptar String?
     // Puedes ajustar la localización y el símbolo según la moneda real si es necesario
     final formatter = NumberFormat.currency(
         locale: 'es_CO', // O la localización adecuada
         symbol: _getCurrencySymbol(currencyCode), // Obtener símbolo dinámicamente
         decimalDigits: 2 // Mostrar 2 decimales
     );
     return formatter.format(amount);
   }


   // --- Función para confirmar y eliminar inversión principal ---
   Future<bool> _confirmAndDeleteInvestment(BuildContext context, Investment investment) async {
       bool confirm = await showDialog(
         context: context,
         builder: (BuildContext context) {
           return AlertDialog(
             title: Text('Confirmar Eliminación'),
             content: Text('¿Estás seguro de que deseas eliminar la inversión "${investment.name}"? Esto eliminará todos sus movimientos asociados.'),
             actions: <Widget>[
               TextButton(
                 onPressed: () => Navigator.of(context).pop(false),
                 child: Text('Cancelar'),
               ),
               TextButton(
                 onPressed: () => Navigator.of(context).pop(true),
                 // Usar el color de error del tema para la acción destructiva
                 child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
               ),
             ],
           );
         },
       ) ?? false;

       if (confirm) {
         try {
           if (investment.id != null) {
             // Llama al servicio para eliminar la inversión principal
             // NOTA: Con la estructura de array history, la eliminación del documento principal
             // elimina el historial automáticamente. Si usáramos subcolecciones,
             // necesitaríamos un manejo adicional aquí o en Cloud Functions.
             await _firestoreService.deleteInvestment(investment.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Inversión "${investment.name}" eliminada.')),
              );
              return true;
           } else {
              //print('Error: Intentando eliminar inversión sin ID.');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: No se pudo obtener el ID de la inversión para eliminar.')),
              );
              return false;
           }
         } catch (e) {
            //print('Error al eliminar inversión: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar la inversión: ${e.toString()}')),
            );
            return false;
         }
       }
       return false;
   }

  // Helper methods for responsive design
  Widget _buildSummaryCardsSection(List<Investment> allInvestments, List<Investment> filteredInvestments, String displayCurrencyForTotals, String formattedTotalInvestedSum) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 20.0,
            vertical: isMobile ? 8.0 : 12.0,
          ),          child: isMobile 
            ? _buildUnifiedSummaryCardMobile(formattedTotalInvestedSum, filteredInvestments, displayCurrencyForTotals)
            : _buildUnifiedSummaryCardDesktop(formattedTotalInvestedSum, filteredInvestments, displayCurrencyForTotals),
        );
      },    );
  }

  Widget _buildFilterSection(List<Investment> investments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
          // En móviles: Card desplegable y contraíble
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            elevation: 2,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Header del card desplegable (siempre visible)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isFiltersExpanded = !_isFiltersExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: Colors.indigo.shade600,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtros de Inversión',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Indicador de filtros activos
                        if (_selectedTypeFilter != null || _selectedSortFilter != 'valor_actual_desc') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Activo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          _isFiltersExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                // Contenido desplegable
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),                        _buildTypeFilterDropdown(isMobile),
                        const SizedBox(height: 12),
                        _buildPlatformFilterDropdown(isMobile, _getAvailablePlatforms(investments)),
                        const SizedBox(height: 12),
                        _buildSortFilterDropdown(isMobile),
                      ],
                    ),
                  ),
                  crossFadeState: _isFiltersExpanded 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          );
        } else {
          // En escritorio: Diseño horizontal como antes
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 16.0 : 24.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern section header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: Colors.indigo.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filtros de Inversión',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Layout horizontal para tablets/desktop
                Row(                  children: [
                    Expanded(child: _buildTypeFilterDropdown(isMobile)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPlatformFilterDropdown(isMobile, _getAvailablePlatforms(investments))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSortFilterDropdown(isMobile)),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
  // Helper methods for investment type icons and colors
  IconData _getInvestmentTypeIcon(String type) {
    switch (type) {
      case 'stocks': return Icons.trending_up;
      case 'funds': return Icons.account_balance;
      case 'crypto': return Icons.currency_bitcoin;
      case 'real_estate': return Icons.home_work;
      case 'bonds': return Icons.receipt_long;
      case 'other': return Icons.more_horiz;
      default: return Icons.monetization_on;
    }
  }

  Color _getInvestmentTypeColor(String type) {
    switch (type) {
      case 'stocks': return Colors.blue.shade600;
      case 'funds': return Colors.green.shade600;
      case 'crypto': return Colors.orange.shade600;
      case 'real_estate': return Colors.brown.shade600;
      case 'bonds': return Colors.purple.shade600;
      case 'other': return Colors.grey.shade600;
      default: return Colors.indigo.shade600;
    }
  }


  // Enhanced type icon widget
  Widget _buildTypeIcon(String type, double radius) {
    return Container(
      width: radius * 1.3,
      height: radius * 1.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: _getInvestmentTypeColor(type).withOpacity(0.15),
        border: Border.all(
          color: _getInvestmentTypeColor(type).withOpacity(0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _getInvestmentTypeColor(type).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        _getInvestmentTypeIcon(type),
        color: _getInvestmentTypeColor(type),
        size: radius * 0.7,
      ),
    );
  }

  Widget _buildInvestmentCard(Investment investment) {
    return LayoutBuilder(
      builder: (context, constraints) {        final isMobile = constraints.maxWidth < 600;
        
        // Calcular unidades totales (compradas + dividendos)
        double totalUnits = _calculateTotalUnits(investment);
        String formattedCurrentQuantity = totalUnits.toStringAsFixed(
            totalUnits.truncateToDouble() == totalUnits ? 0 : 5);
        String formattedTotalInvested = _formatCurrency(investment.totalInvested, investment.currency);
        String formattedTotalDividends = _formatCurrency(investment.totalDividends, investment.currency);
        double initialShareValue = (investment.totalInvested > 0 && investment.currentQuantity > 0)
            ? investment.totalInvested / investment.currentQuantity
            : 0.0;
        String formattedInitialShareValue = _formatCurrency(initialShareValue, investment.currency);return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 20.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Dismissible(
            key: Key(investment.id!),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await _confirmAndDeleteInvestment(context, investment);
            },
            onDismissed: (direction) {},            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 0,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InvestmentMovementsScreen(investmentId: investment.id!)),
                  );
                },                
                child: 
                Padding(
                  padding: EdgeInsets.all(isMobile ? 10.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,                        children: [                          _buildTypeIcon(investment.type, isMobile ? 18 : 20),
                          SizedBox(width: isMobile ? 8 : 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [                                Text(
                                  investment.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 14 : 16,
                                  ),                                ),
                                const SizedBox(height: 6),
                                if (isMobile)
                                  _buildInvestmentDetailsMobile(
                                    formattedCurrentQuantity,
                                    formattedInitialShareValue,
                                    formattedTotalInvested,
                                    formattedTotalDividends,
                                    investment,
                                  )
                                else
                                  _buildInvestmentDetailsDesktop(
                                    formattedCurrentQuantity,
                                    formattedInitialShareValue,
                                    formattedTotalInvested,
                                    formattedTotalDividends,
                                    investment,
                                  ),
                              ],
                            ),
                          ),
                        ],                      ),
                      // Eliminado el espacio adicional que antes era necesario para los botones
                      //_buildActionButtons(investment, isMobile),
                      ],
                  ),
                ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }  Widget _buildInvestmentDetailsMobile(String formattedCurrentQuantity, String formattedInitialShareValue, 
      String formattedTotalInvested, String formattedTotalDividends, Investment investment) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Compact 2-column grid layout
          Row(
            children: [
              Expanded(child: _buildCompactDetailRow('Cantidad', formattedCurrentQuantity, Icons.numbers)),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactDetailRow('C. Promedio', formattedInitialShareValue, Icons.analytics)),
            ],
          ),          const SizedBox(height: 6),          Row(
            children: [
              Expanded(child: _buildCompactDetailRow('Total Inv.', formattedTotalInvested, Icons.input)),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactDetailRow('Dividendos', formattedTotalDividends, Icons.payments)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: investment.platform != null && investment.platform!.isNotEmpty 
                ? _buildCompactDetailRow('Plataforma', investment.platform!, Icons.business)
                : Container()
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactDetailRow(
                'Ratio Div.',
                investment.totalInvested > 0 ? '${((investment.totalDividends / investment.totalInvested) * 100).toStringAsFixed(2)}%' : '0.00%',
                Icons.trending_up
              )),
            ],
          ),
          const SizedBox(height: 6),
          // Gain/Loss and Total Value in a row
          Row(
            children: [
              Expanded(child: _buildGainLossWidget(investment)),
              const SizedBox(width: 8),
              Expanded(child: _buildCurrentTotalValueWidget(investment)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildInvestmentDetailsDesktop(String formattedCurrentQuantity, String formattedInitialShareValue, 
      String formattedTotalInvested, String formattedTotalDividends, Investment investment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                _buildDetailRow('Cantidad', formattedCurrentQuantity, Icons.numbers),
                const SizedBox(height: 6),
                _buildDetailRow('Costo Promedio', formattedInitialShareValue, Icons.analytics),
                const SizedBox(height: 6),
                if (investment.platform != null && investment.platform!.isNotEmpty) ...[
                  _buildDetailRow('Plataforma', investment.platform!, Icons.business),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                _buildDetailRow('Total Invertido', formattedTotalInvested, Icons.input),
                const SizedBox(height: 6),
                _buildDetailRow('Dividendos', formattedTotalDividends, Icons.payments),
                const SizedBox(height: 6),
                _buildDetailRow(
                  'Ratio Dividendos',
                  investment.totalInvested > 0 ? '${((investment.totalDividends / investment.totalInvested) * 100).toStringAsFixed(2)}%' : '0.00%',
                  Icons.trending_up
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildGainLossWidget(investment)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCurrentTotalValueWidget(investment)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for detail rows
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for compact detail rows in grid layout
  Widget _buildCompactDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildGainLossWidget(Investment investment) {
    final symbol = mapInvestmentToFinnhubSymbol(investment);
    return FutureBuilder(
      future: StockQuoteCacheService().getQuote(symbol ?? ''),
      builder: (context, snapshot) {
        double? currentPrice = snapshot.data != null && snapshot.data is StockQuote ? (snapshot.data as StockQuote).price : null;
        double? currentValue = (currentPrice != null && investment.currentQuantity > 0)
          ? currentPrice * investment.currentQuantity
          : null;
        double gainLoss = (currentValue != null)
          ? currentValue - investment.totalInvested
          : 0.0;
        Color color = gainLoss > 0 ? Colors.green : (gainLoss < 0 ? Colors.red : Colors.grey);
        String formatted = _formatCurrency(gainLoss, investment.currency);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3), width: 0.5),
          ),
          child: Text(
            'G/P: $formatted',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
        ),
        );
      },
    );
  }

  Widget _buildCurrentTotalValueWidget(Investment investment) {
    final symbol = mapInvestmentToFinnhubSymbol(investment);
    return FutureBuilder(
      future: StockQuoteCacheService().getQuote(symbol ?? ''),
      builder: (context, snapshot) {
        double? currentPrice = snapshot.data != null && snapshot.data is StockQuote ? (snapshot.data as StockQuote).price : null;
        double? totalCurrentValue = (currentPrice != null)
          ? currentPrice * investment.currentQuantity
          : null;
        String formatted = totalCurrentValue != null ? _formatCurrency(totalCurrentValue, investment.currency) : 'N/D';
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3), 
              width: 0.5,
            ),
          ),
          child: Text(
            'V. Actual: $formatted',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: Theme.of(context).colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
  /*
  Widget _buildActionButtons(Investment investment, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(Icons.edit, size: isMobile ? 18 : 20, color: Theme.of(context).colorScheme.primary),
          tooltip: 'Editar Inversión',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddEditInvestmentScreen(investment: investment)),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            minimumSize: Size(isMobile ? 32 : 36, isMobile ? 32 : 36),
          ),
        ),
        SizedBox(width: isMobile ? 6 : 10),
        IconButton(
          icon: Icon(Icons.receipt_long, size: isMobile ? 18 : 20, color: Theme.of(context).colorScheme.secondary),
          tooltip: 'Ver Movimientos',
          onPressed: () {
            if (investment.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InvestmentMovementsScreen(investmentId: investment.id!)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: No se puede acceder a los movimientos sin ID de inversión.')),
              );
            }
          },
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            minimumSize: Size(isMobile ? 32 : 36, isMobile ? 32 : 36),
          ),
        ),
      ],
    );
  }*/

  Widget _buildEmptyState(String formattedTotalInvestedSum, List<Investment> investments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Invertido:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        formattedTotalInvestedSum,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),                ),
              ),
            ),
            _buildFilterSection(investments),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron inversiones',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay inversiones que coincidan con el filtro seleccionado.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Función para verificar si hay filtros activos
  bool _hasActiveFilters() {
    return _selectedTypeFilter != null || _selectedPlatformFilter != null;
  }

  // Widget para mostrar estado cuando no hay resultados que coincidan con los filtros
  Widget _buildNoResultsForFilters(List<Investment> allInvestments, String formattedTotalInvestedSum) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Column(
          children: [
            _buildSummaryCardsSection(allInvestments, [], 'COP', formattedTotalInvestedSum),
            _buildFilterSection(allInvestments),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron resultados',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay inversiones que coincidan con los filtros seleccionados.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Intenta ajustar los filtros o agregar más inversiones.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Botón para limpiar filtros
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTypeFilter = null;
                            _selectedPlatformFilter = null;
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpiar Filtros'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: isMobile ? 12 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget dropdown para tipo de inversión
  Widget _buildTypeFilterDropdown(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16, 
        vertical: isMobile ? 10 : 12
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.category,
              color: Colors.indigo,
              size: isMobile ? 16 : 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedTypeFilter,
                hint: Text(
                  'Tipo de inversión',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: isMobile ? 13 : 16,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Todos',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 13 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._investmentTypesValues.map((String typeValue) {
                    return DropdownMenuItem<String>(
                      value: typeValue,
                      child: Row(
                        children: [
                          Icon(
                            _getInvestmentTypeIcon(typeValue),
                            size: 16,
                            color: _getInvestmentTypeColor(typeValue),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getInvestmentTypeFilterText(typeValue),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: isMobile ? 13 : 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (newValue) {
                  setState(() {
                    _selectedTypeFilter = newValue;
                  });
                },
                isExpanded: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isMobile ? 13 : 16,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget dropdown para ordenamiento
  Widget _buildSortFilterDropdown(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16, 
        vertical: isMobile ? 10 : 12
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.sort,
              color: Colors.orange.shade600,
              size: isMobile ? 16 : 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSortFilter,
                items: _sortOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(
                      option['label']!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 13 : 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedSortFilter = newValue!;
                  });
                },
                isExpanded: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isMobile ? 13 : 16,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget dropdown para plataforma
  Widget _buildPlatformFilterDropdown(bool isMobile, List<String> availablePlatforms) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16, 
        vertical: isMobile ? 10 : 12
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.business,
              color: Colors.green.shade600,
              size: isMobile ? 16 : 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedPlatformFilter,
                hint: Text(
                  'Plataforma',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: isMobile ? 13 : 16,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Todas',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 13 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...availablePlatforms.map((String platform) {
                    return DropdownMenuItem<String>(
                      value: platform,
                      child: Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            platform,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: isMobile ? 13 : 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (newValue) {
                  setState(() {
                    _selectedPlatformFilter = newValue;
                  });
                },
                isExpanded: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isMobile ? 13 : 16,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función para ordenar las inversiones según el filtro seleccionado
  List<Investment> _sortInvestments(List<Investment> investments) {
    List<Investment> sortedInvestments = List.from(investments);
    
    switch (_selectedSortFilter) {
      case 'valor_actual_desc':
        sortedInvestments.sort((a, b) {
          return _getInvestmentCurrentValue(b).compareTo(_getInvestmentCurrentValue(a));
        });
        break;
      case 'valor_actual_asc':
        sortedInvestments.sort((a, b) {
          return _getInvestmentCurrentValue(a).compareTo(_getInvestmentCurrentValue(b));
        });
        break;
      case 'total_invertido_desc':
        sortedInvestments.sort((a, b) => b.totalInvested.compareTo(a.totalInvested));
        break;
      case 'total_invertido_asc':
        sortedInvestments.sort((a, b) => a.totalInvested.compareTo(b.totalInvested));
        break;
      case 'ganancia_perdida_desc':
        sortedInvestments.sort((a, b) {
          double gainLossA = _getInvestmentGainLoss(a);
          double gainLossB = _getInvestmentGainLoss(b);
          return gainLossB.compareTo(gainLossA);
        });
        break;
      case 'ganancia_perdida_asc':
        sortedInvestments.sort((a, b) {
          double gainLossA = _getInvestmentGainLoss(a);
          double gainLossB = _getInvestmentGainLoss(b);
          return gainLossA.compareTo(gainLossB);
        });
        break;
      case 'dividendos_desc':
        sortedInvestments.sort((a, b) => b.totalDividends.compareTo(a.totalDividends));
        break;
      case 'dividendos_asc':
        sortedInvestments.sort((a, b) => a.totalDividends.compareTo(b.totalDividends));
        break;
      case 'nombre_asc':
        sortedInvestments.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'nombre_desc':
        sortedInvestments.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    
    return sortedInvestments;
  }
  
  // Helper para obtener el valor actual de una inversión (necesario para el ordenamiento)
  double _getInvestmentCurrentValue(Investment investment) {
    final symbol = mapInvestmentToFinnhubSymbol(investment);
    if (symbol == null) return 0.0;
    
    // Para ordenamiento, usamos una aproximación simple basada en el total invertido
    // En la práctica, este valor se calculará correctamente cuando se muestre cada tarjeta
    return investment.totalInvested;
  }
  
  // Helper para obtener la ganancia/pérdida de una inversión (necesario para el ordenamiento)
  double _getInvestmentGainLoss(Investment investment) {
    final symbol = mapInvestmentToFinnhubSymbol(investment);
    if (symbol == null) return 0.0;
    
    // Para ordenamiento, usamos una aproximación simple
    // En la práctica, este valor se calculará correctamente cuando se muestre cada tarjeta
    return 0.0;
  }

  // Función para obtener las plataformas disponibles de las inversiones
  List<String> _getAvailablePlatforms(List<Investment> investments) {
    Set<String> platforms = <String>{};
    for (var investment in investments) {
      if (investment.platform != null && investment.platform!.isNotEmpty) {
        platforms.add(investment.platform!);
      }
    }
    List<String> sortedPlatforms = platforms.toList();
    sortedPlatforms.sort();
    return sortedPlatforms;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Inicia sesión requerido',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, inicia sesión para ver tus inversiones.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return StreamBuilder<List<Investment>>(
            stream: _firestoreService.getInvestments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
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
                          'Error al cargar inversiones',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay inversiones',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tienes inversiones registradas aún.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }              final allInvestments = snapshot.data!;

              // Filtrar las inversiones por tipo y plataforma
              final filteredInvestments = allInvestments.where((investment) {
                if (_selectedTypeFilter != null && investment.type != _selectedTypeFilter) {
                  return false;
                }
                if (_selectedPlatformFilter != null && investment.platform != _selectedPlatformFilter) {
                  return false;
                }
                return true;
              }).toList();

              // Calcular el total invertido usando las inversiones filtradas
              final double totalInvestedSum = filteredInvestments.fold(0.0, (sum, item) => sum + item.totalInvested);
              const String displayCurrencyForTotals = 'COP';
              final String formattedTotalInvestedSum = _formatCurrency(totalInvestedSum, displayCurrencyForTotals);

              // Ordenar las inversiones filtradas
              final sortedInvestments = _sortInvestments(filteredInvestments);

              if (sortedInvestments.isEmpty) {
                // Si hay filtros activos, mostrar mensaje específico de "sin resultados"
                if (_hasActiveFilters()) {
                  return _buildNoResultsForFilters(allInvestments, formattedTotalInvestedSum);
                } else {
                  // Si no hay filtros, mostrar el estado vacío normal
                  return _buildEmptyState(formattedTotalInvestedSum, allInvestments);
                }
              }

              return Column(
                children: [
                  _buildSummaryCardsSection(allInvestments, sortedInvestments, displayCurrencyForTotals, formattedTotalInvestedSum),
                  _buildFilterSection(allInvestments),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: sortedInvestments.length,
                      itemBuilder: (context, index) {
                        return _buildInvestmentCard(sortedInvestments[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Widget unificado para resumen en móviles
  Widget _buildUnifiedSummaryCardMobile(String formattedTotalInvestedSum, List<Investment> filteredInvestments, String displayCurrencyForTotals) {
    return FutureBuilder<List<double>>(
      future: calcularValorActualYBeneficio(filteredInvestments),
      builder: (context, snapshot) {
        double valorActual = snapshot.data != null ? snapshot.data![0] : 0.0;
        double beneficio = snapshot.data != null ? snapshot.data![1] : 0.0;
        String formattedValorActual = _formatCurrency(valorActual, displayCurrencyForTotals);
        String formattedBeneficio = _formatCurrency(beneficio, displayCurrencyForTotals);
        Color gainLossColor = beneficio > 0 ? Colors.green : (beneficio < 0 ? Colors.red : Colors.grey);
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Título del card
              Text(
                'Resumen de Inversiones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Grid de 2 columnas para los valores
              Row(
                children: [
                  // Columna izquierda: Total Invertido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.input, color: Colors.blue, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Total Invertido',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formattedTotalInvestedSum,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Columna derecha: Valor Actual
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up, color: Colors.indigo, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Valor Actual',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formattedValorActual,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Ganancia/Pérdida centrada
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gainLossColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      beneficio >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: gainLossColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ganancia/Pérdida',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formattedBeneficio,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: gainLossColor,
                        ),                      ),
                    ],
                  ),                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Botón de dividendos para móvil
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpcomingDividendsScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.calendar_today,
                    size: 16,
                  ),
                  label: Text(
                    'Ver Calendario de Dividendos',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget unificado para resumen en escritorio
  Widget _buildUnifiedSummaryCardDesktop(String formattedTotalInvestedSum, List<Investment> filteredInvestments, String displayCurrencyForTotals) {
    return FutureBuilder<List<double>>(
      future: calcularValorActualYBeneficio(filteredInvestments),
      builder: (context, snapshot) {
        double valorActual = snapshot.data != null ? snapshot.data![0] : 0.0;
        double beneficio = snapshot.data != null ? snapshot.data![1] : 0.0;
        String formattedValorActual = _formatCurrency(valorActual, displayCurrencyForTotals);
        String formattedBeneficio = _formatCurrency(beneficio, displayCurrencyForTotals);
        Color gainLossColor = beneficio > 0 ? Colors.green : (beneficio < 0 ? Colors.red : Colors.grey);
          // Calcular porcentaje de ganancia/pérdida
        double totalInvested = filteredInvestments.fold(0.0, (sum, investment) => sum + investment.totalInvested);
        double percentageChange = totalInvested > 0 ? (beneficio / totalInvested) * 100 : 0.0;
        
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Título del card
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Resumen de Inversiones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Fila con las tres métricas principales
              Row(
                children: [
                  // Total Invertido
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.input, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Invertido',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            formattedTotalInvestedSum,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Valor Actual
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.trending_up, color: Colors.indigo, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Valor Actual',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          snapshot.connectionState == ConnectionState.waiting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  formattedValorActual,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Ganancia/Pérdida
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: gainLossColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: gainLossColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: gainLossColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  beneficio >= 0 ? Icons.trending_up : Icons.trending_down,
                                  color: gainLossColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Ganancia/Pérdida',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: gainLossColor.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          snapshot.connectionState == ConnectionState.waiting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Column(
                                  children: [
                                    Text(
                                      formattedBeneficio,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: gainLossColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}%',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: gainLossColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Botón de Dividendos
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpcomingDividendsScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Calendario de Dividendos',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Helper global para normalizar cualquier nombre de cripto a símbolo Finnhub (BINANCE:XXXUSDT) ---
String normalizeCryptoSymbol(String name) {
  String base = name.trim().toUpperCase();
  //print('[DEBUG] normalizeCryptoSymbol input: '      '[33m$name[0m');
  if (base.startsWith('BINANCE:')) base = base.substring(8);
  if (base.endsWith('T')) base = base.substring(0, base.length - 1); // Por si el usuario pone BTCUSDT
  if (base.endsWith('USDT')) base = base.substring(0, base.length - 4);
  //print('[DEBUG] normalizeCryptoSymbol base: '      '[36m$base[0m');
  final result = 'BINANCE:${base}USDT';
  //print('[DEBUG] normalizeCryptoSymbol result: '      '[32m$result[0m');
  return result;
}

String? mapInvestmentToFinnhubSymbol(Investment investment) {
  //print('[DEBUG] mapInvestmentToFinnhubSymbol investment: '      '[35m${investment.name} (${investment.type})[0m');
  if (investment.type == 'stocks' || investment.type == 'funds') {
    final symbol = investment.name.toUpperCase();
    //print('[DEBUG] mapInvestmentToFinnhubSymbol stock/fund symbol: '        '[36m$symbol[0m');
    return symbol;
  }
  if (investment.type == 'crypto') {
    final symbol = normalizeCryptoSymbol(investment.name);
    //print('[DEBUG] mapInvestmentToFinnhubSymbol crypto symbol: '        '[36m$symbol[0m');
    return symbol;
  }
  //print('[DEBUG] mapInvestmentToFinnhubSymbol null');
  return null;
}

Future<List<double>> calcularValorActualYBeneficio(List<Investment> inversiones) async {
  double valorActualTotal = 0.0;
  double beneficioTotal = 0.0;

  for (var inversion in inversiones) {
    final symbol = mapInvestmentToFinnhubSymbol(inversion);
    //print('[DEBUG] calcularValorActualYBeneficio symbol: '        '[36m$symbol[0m');
    if (symbol == null) continue;
    final quote = await StockQuoteCacheService().getQuote(symbol);
    //print('[DEBUG] calcularValorActualYBeneficio quote: '        '[33m${quote?.price}[0m');
    final double? currentPrice = quote?.price;
    if (currentPrice != null) {
      final double currentValue = currentPrice * inversion.currentQuantity;
      final double gainLoss = currentValue - inversion.totalInvested;
      //print('[DEBUG] calcularValorActualYBeneficio currentValue: '          '[32m$currentValue[0m, gainLoss: [31m$gainLoss[0m');
      valorActualTotal += currentValue;
      beneficioTotal += gainLoss;
    }
  }
  //print('[DEBUG] calcularValorActualYBeneficio totals: '      '[32mvalorActualTotal=$valorActualTotal[0m, [31mbeneficioTotal=$beneficioTotal[0m');
  return [valorActualTotal, beneficioTotal];
}  // Helper para calcular unidades totales (compradas + dividendos)
  double _calculateTotalUnits(Investment investment) {
    double totalQuantity = 0.0;
    double dividendUnits = 0.0;
    
    // Verificar que history no sea null
    if (investment.history == null) return investment.currentQuantity;
    
    for (var movementData in investment.history!) {
      final type = movementData['type'] as String? ?? 'other';
      final quantity = (movementData['quantity'] as num?)?.toDouble() ?? 0.0;
      
      switch (type) {
        case 'compra':
        case 'aporte':
          totalQuantity += quantity;
          break;
        case 'venta':
          totalQuantity -= quantity;
          break;
        case 'dividendo':
          dividendUnits += quantity;
          break;
      }
    }
    
    // Asegurar que la cantidad no sea negativa
    if (totalQuantity < 0) totalQuantity = 0;
    
    return totalQuantity + dividendUnits;
  }


