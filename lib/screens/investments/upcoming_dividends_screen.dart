// lib/screens/investments/upcoming_dividends_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/investment.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:mis_finanza/services/dividend_service.dart';
import 'package:mis_finanza/services/finnhub_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpcomingDividendsScreen extends StatefulWidget {
  const UpcomingDividendsScreen({super.key});

  @override
  _UpcomingDividendsScreenState createState() => _UpcomingDividendsScreenState();
}

class _UpcomingDividendsScreenState extends State<UpcomingDividendsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<Investment> _investments = [];
  List<DividendInfo> _upcomingDividends = [];
  bool _isLoading = true;
  String? _error;  // Filtros
  String _selectedFilter = 'all'; // all, this_month, next_month, this_quarter
  String _selectedSortBy = 'date_asc'; // date_asc, date_desc, amount_desc, alphabetical
  String _selectedTypeFilter = 'all'; // all, stocks, funds, crypto, etc.
  String _selectedTimeView = 'future'; // both, past, future, today

  @override
  void initState() {
    super.initState();
    _loadDividends();
  }

  Future<void> _loadDividends() async {
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Usuario no autenticado';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final investments = await _firestoreService.getInvestments().first;
      await _processDividends(investments);

      setState(() {
        _investments = investments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar dividendos: $e';
      });
    }
  }  Future<void> _processDividends(List<Investment> investments) async {
    try {
      print('🔄 Procesando dividendos con API real de Finnhub...');
      
      // Filtrar las criptomonedas antes de procesar dividendos
      final nonCryptoInvestments = investments.where((investment) => 
        investment.type != 'crypto'
      ).toList();
      
      print('📊 Filtrando ${investments.length - nonCryptoInvestments.length} criptomonedas');
      
      // Usar el nuevo servicio de dividendos que integra Finnhub (solo para no-crypto)
      final dividendInfos = await DividendService.getUpcomingDividends(nonCryptoInvestments);
      
      setState(() {
        _upcomingDividends = dividendInfos;
      });
      
      print('✅ Procesados ${dividendInfos.length} dividendos (sin criptos)');
      
      // Mostrar información sobre dividendos reales vs simulados
      final realDividends = dividendInfos.where((d) => d.isReal).length;
      final simulatedDividends = dividendInfos.where((d) => !d.isReal).length;
      
      print('📊 Dividendos reales: $realDividends, Simulados: $simulatedDividends');
      
    } catch (e) {
      print('❌ Error procesando dividendos: $e');
      
      // Fallback al método anterior si falla la integración
      await _processDividendsLegacy(investments);
    }
  }
  // Método legacy como fallback
  Future<void> _processDividendsLegacy(List<Investment> investments) async {
    List<DividendInfo> legacyDividends = [];
    
    // Filtrar las criptomonedas también en el método legacy
    final nonCryptoInvestments = investments.where((investment) => 
      investment.type != 'crypto'
    ).toList();
    
    for (var investment in nonCryptoInvestments) {
      if (investment.history != null) {
        for (var movement in investment.history!) {
          final type = movement['type'] as String? ?? '';
          if (type == 'dividendo') {
            final date = (movement['date'] as Timestamp?)?.toDate();
            final amount = (movement['amount'] as num?)?.toDouble() ?? 0.0;
            final notes = movement['notes'] as String? ?? '';

            if (date != null) {
              legacyDividends.add(DividendInfo(
                investment: investment,
                date: date,
                amount: amount,
                currency: investment.currency ?? 'USD',
                frequency: 'Historical',
                isReal: false,
                symbol: investment.name.toUpperCase(),
                notes: notes.isNotEmpty ? notes : 'Dividendo histórico',
              ));
            }
          }
        }
      }
    }

    setState(() {
      _upcomingDividends = legacyDividends;
    });
  }  List<DividendInfo> _getFilteredDividends() {
    // Primero aplicar filtro de tiempo (pasado/futuro/hoy)
    List<DividendInfo> filtered = _getFilteredDividendsByTime();
    
    // Filtrar criptomonedas como medida de seguridad adicional
    filtered = filtered.where((dividend) => 
      dividend.investment.type != 'crypto'
    ).toList();
    
    final now = DateTime.now();
    
    // Aplicar filtro de período adicional
    switch (_selectedFilter) {
      case 'this_month':
        filtered = filtered.where((dividend) {
          final date = dividend.date;
          return date.year == now.year && date.month == now.month;
        }).toList();
        break;
      case 'next_month':
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        filtered = filtered.where((dividend) {
          final date = dividend.date;
          return date.year == nextMonth.year && date.month == nextMonth.month;
        }).toList();
        break;
      case 'this_quarter':
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        final quarterEnd = DateTime(quarterStart.year, quarterStart.month + 3, 0);
        filtered = filtered.where((dividend) {
          final date = dividend.date;
          return date.isAfter(quarterStart.subtract(Duration(days: 1))) && 
                 date.isBefore(quarterEnd.add(Duration(days: 1)));
        }).toList();
        break;
    }

    // Aplicar filtro por tipo de inversión
    if (_selectedTypeFilter != 'all') {
      filtered = filtered.where((dividend) {
        return dividend.investment.type == _selectedTypeFilter;
      }).toList();
    }

    // Aplicar ordenamiento
    switch (_selectedSortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'alphabetical':
        filtered.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
    }

    return filtered;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 2
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  // Colores mejorados con Material 3
  Color _getTypeColor(String type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case 'stocks':
        return colorScheme.primary;
      case 'crypto':
        return Colors.orange.shade700;
      case 'funds':
        return Colors.green.shade700;
      case 'bonds':
        return Colors.purple.shade700;
      case 'real_estate':
        return Colors.brown.shade700;
      default:
        return colorScheme.secondary;
    }
  }

  // Iconos mejorados con mejor semántica
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'stocks':
        return Icons.trending_up_rounded;
      case 'crypto':
        return Icons.currency_bitcoin_rounded;
      case 'funds':
        return Icons.account_balance_rounded;
      case 'bonds':
        return Icons.receipt_long_rounded;
      case 'real_estate':
        return Icons.business_rounded;
      default:
        return Icons.paid_rounded;
    }
  }

  // Función para obtener nombres amigables de tipos
  String _getTypeName(String type) {
    switch (type) {
      case 'stocks':
        return 'Acciones';
      case 'crypto':
        return 'Criptomonedas';
      case 'funds':
        return 'Fondos';
      case 'bonds':
        return 'Bonos';
      case 'real_estate':
        return 'Bienes Raíces';
      default:
        return 'Otros';
    }
  }
  // Función para obtener tipos únicos de inversiones (excluyendo crypto)
  List<String> _getAvailableTypes() {
    Set<String> types = _investments.map((inv) => inv.type).toSet();
    types.remove(''); // Remover tipos vacíos si los hay
    types.remove('crypto'); // Remover criptomonedas ya que no generan dividendos
    return types.toList()..sort();
  }
  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Calendario de Dividendos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Inicia sesión para ver los dividendos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredDividends = _getFilteredDividends();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Calendario de Dividendos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              onPressed: _loadDividends,
              tooltip: 'Actualizar dividendos',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando dividendos...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Container(
                    margin: EdgeInsets.all(24),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _loadDividends,
                          icon: Icon(Icons.refresh_rounded),
                          label: Text('Reintentar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Filtros y resumen
                    _buildHeaderSection(filteredDividends),
                    
                    // Lista de dividendos
                    Expanded(
                      child: filteredDividends.isEmpty
                          ? _buildEmptyState()
                          : _buildDividendsList(filteredDividends),
                    ),
                  ],
                ),
    );
  }  Widget _buildHeaderSection(List<DividendInfo> filteredDividends) {
    final totalAmount = filteredDividends.fold<double>(
      0.0, 
      (sum, dividend) => sum + dividend.amount
    );

    final realDividends = filteredDividends.where((d) => d.isReal).length;
    final simulatedDividends = filteredDividends.where((d) => !d.isReal).length;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // Card de resumen mejorado
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,                    children: [
                      Text(
                        'Dividendos Registrados',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${filteredDividends.length} ${filteredDividends.length == 1 ? 'pago' : 'pagos'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                          if (realDividends > 0) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    '$realDividends reales',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (simulatedDividends > 0) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    '$simulatedDividends estimados',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Histórico',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalAmount),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Filtros mejorados
          _buildFiltersSection(),
        ],
      ),
    );
  }  Widget _buildFiltersSection() {
    final availableTypes = _getAvailableTypes();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
            // Responsive layout para filtros
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final isMedium = constraints.maxWidth > 600;
              
              if (isWide) {
                // Layout horizontal para pantallas anchas (4 columnas)
                return Column(
                  children: [
                    // Primera fila: Filtro de tiempo (más importante)
                    _buildTimeViewFilter(),
                    SizedBox(height: 16),
                    // Segunda fila: Otros filtros
                    Row(
                      children: [
                        Expanded(child: _buildPeriodFilter()),
                        SizedBox(width: 16),
                        Expanded(child: _buildTypeFilter(availableTypes)),
                        SizedBox(width: 16),
                        Expanded(child: _buildSortFilter()),
                      ],
                    ),
                  ],
                );
              } else if (isMedium) {
                // Layout para pantallas medianas (2x2)
                return Column(
                  children: [
                    _buildTimeViewFilter(),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildPeriodFilter()),
                        SizedBox(width: 16),
                        Expanded(child: _buildTypeFilter(availableTypes)),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSortFilter(),
                  ],
                );
              } else {
                // Layout vertical para pantallas pequeñas
                return Column(
                  children: [
                    _buildTimeViewFilter(),
                    SizedBox(height: 16),
                    _buildPeriodFilter(),
                    SizedBox(height: 16),
                    _buildTypeFilter(availableTypes),
                    SizedBox(height: 16),
                    _buildSortFilter(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Período',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedFilter,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
            ),
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Todos los períodos'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'this_month',
                child: Row(
                  children: [
                    Icon(Icons.today_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Este mes'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'next_month',
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Próximo mes'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'this_quarter',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Este trimestre'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter(List<String> availableTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Tipo de Inversión',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedTypeFilter,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
            ),
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Todos los tipos'),
                  ],
                ),
              ),
              ...availableTypes.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type), size: 16, color: _getTypeColor(type)),
                      SizedBox(width: 8),
                      Text(_getTypeName(type)),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTypeFilter = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sort_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Ordenar por',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedSortBy,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
            ),
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(
                value: 'date_asc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Fecha (Antiguos primero)'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'date_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Fecha (Recientes primero)'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'amount_desc',
                child: Row(
                  children: [
                    Icon(Icons.attach_money_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Monto (Mayor a menor)'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'alphabetical',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Alfabético'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSortBy = value!;
              });
            },
          ),
        ),      ],
    );
  }

  Widget _buildTimeViewFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Vista de Tiempo',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Chips de selección para filtro de tiempo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTimeViewChip(
                value: 'future',
                label: 'Próximos',
                icon: Icons.arrow_forward_rounded,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              _buildTimeViewChip(
                value: 'today',
                label: 'Hoy',
                icon: Icons.today_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8),
              _buildTimeViewChip(
                value: 'past',
                label: 'Pasados',
                icon: Icons.history_rounded,
                color: Colors.grey,
              ),
              SizedBox(width: 8),
              _buildTimeViewChip(
                value: 'both',
                label: 'Todos',
                icon: Icons.all_inclusive_rounded,
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeViewChip({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTimeView == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeView = value;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
            ? color.withOpacity(0.15)
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
              ? color
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividendsList(List<DividendInfo> filteredDividends) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: filteredDividends.length,
      itemBuilder: (context, index) {
        final dividendInfo = filteredDividends[index];
        final investment = dividendInfo.investment;
        final date = dividendInfo.date;
        final amount = dividendInfo.amount;
        final notes = dividendInfo.notes;
        final isReal = dividendInfo.isReal;
        final color = _getTypeColor(investment.type);
          final isToday = DateTime.now().difference(date).inDays == 0;
        final isPast = date.isBefore(DateTime.now().subtract(Duration(days: 1)));
        final isFuture = date.isAfter(DateTime.now().add(Duration(days: 1)));
        
        // Colores y estilos basados en el estado temporal
        Color cardBorderColor;
        Color cardBackgroundColor;
        Color statusColor;
        IconData statusIcon;
        String statusLabel;
        
        if (isToday) {
          cardBorderColor = Theme.of(context).colorScheme.primary;
          cardBackgroundColor = Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1);
          statusColor = Theme.of(context).colorScheme.primary;
          statusIcon = Icons.today_rounded;
          statusLabel = 'HOY';
        } else if (isPast) {
          cardBorderColor = Colors.grey.shade400;
          cardBackgroundColor = Colors.grey.shade50.withOpacity(0.5);
          statusColor = Colors.grey.shade600;
          statusIcon = Icons.history_rounded;
          statusLabel = 'PASADO';
        } else {
          cardBorderColor = Colors.blue.shade300;
          cardBackgroundColor = Colors.blue.shade50.withOpacity(0.3);
          statusColor = Colors.blue.shade700;
          statusIcon = Icons.schedule_rounded;
          statusLabel = 'PRÓXIMO';
        }        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardBorderColor.withOpacity(0.6),
              width: isToday ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: isToday ? 12 : 8,
                offset: Offset(0, isToday ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Aquí se podría agregar navegación a detalles del dividendo
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar con icono del tipo de inversión
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _getTypeIcon(investment.type),
                          color: color,
                          size: 24,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isReal ? Colors.green : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              isReal ? Icons.verified_rounded : Icons.auto_awesome_rounded,
                              color: isReal ? Colors.green : Colors.orange,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de la inversión con badge de tipo
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                investment.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isReal 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isReal ? 'REAL' : 'EST.',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isReal ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 6),
                        
                        // Fecha con estado
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isToday 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : isPast 
                                    ? Theme.of(context).colorScheme.outline.withOpacity(0.1)
                                    : Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isToday 
                                      ? Icons.today_rounded
                                      : isPast 
                                        ? Icons.history_rounded
                                        : Icons.schedule_rounded,
                                    size: 14,
                                    color: isToday 
                                      ? Theme.of(context).colorScheme.primary
                                      : isPast 
                                        ? Theme.of(context).colorScheme.outline
                                        : Theme.of(context).colorScheme.tertiary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatDate(date),
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: isToday 
                                        ? Theme.of(context).colorScheme.primary
                                        : isPast 
                                          ? Theme.of(context).colorScheme.outline
                                          : Theme.of(context).colorScheme.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isToday) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'HOY',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        SizedBox(height: 6),
                        
                        // Plataforma, símbolo y notas
                        Row(
                          children: [
                            if (investment.platform != null) ...[
                              Icon(
                                Icons.business_rounded,
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              SizedBox(width: 4),
                              Text(
                                investment.platform!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('•', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                              SizedBox(width: 8),
                            ],
                            Text(
                              dividendInfo.symbol,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (notes.isNotEmpty) ...[
                              SizedBox(width: 8),
                              Text('•', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  notes,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Monto con currency
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatCurrency(amount),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (dividendInfo.currency != 'USD' && dividendInfo.currency.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            dividendInfo.currency,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No hay dividendos registrados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Los dividendos aparecerán aquí cuando los registres en el historial de tus inversiones',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tip: Ve a Inversiones para registrar dividendos',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Separar dividendos por tiempo
  List<DividendInfo> _getPastDividends() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    return _upcomingDividends.where((dividend) => 
      dividend.date.isBefore(startOfToday)
    ).toList()..sort((a, b) => b.date.compareTo(a.date)); // Más recientes primero
  }

  List<DividendInfo> _getFutureDividends() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    return _upcomingDividends.where((dividend) => 
      dividend.date.isAfter(startOfToday.subtract(Duration(milliseconds: 1)))
    ).toList()..sort((a, b) => a.date.compareTo(b.date)); // Más próximos primero
  }

  List<DividendInfo> _getTodayDividends() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(Duration(days: 1));
    
    return _upcomingDividends.where((dividend) => 
      dividend.date.isAfter(startOfToday.subtract(Duration(milliseconds: 1))) &&
      dividend.date.isBefore(endOfToday)
    ).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // Obtener dividendos según el filtro seleccionado
  List<DividendInfo> _getFilteredDividendsByTime() {
    switch (_selectedTimeView) {
      case 'past':
        return _getPastDividends();
      case 'future':
        return _getFutureDividends();
      case 'today':
        return _getTodayDividends();
      case 'both':
      default:
        return _upcomingDividends..sort((a, b) => a.date.compareTo(b.date));
    }
  }

  // Banner informativo sobre la API
  Widget _buildApiInfoBanner() {
    final apiStatus = FinnhubService.getApiStatus();
    final hasValidKey = apiStatus['hasValidKey'] as bool;
    final apiKeyType = apiStatus['apiKeyType'] as String;
    
    final realDividends = _upcomingDividends.where((d) => d.isReal).length;
    final totalDividends = _upcomingDividends.length;
    
    if (hasValidKey && realDividends > 0) {
      // API funcionando bien
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'API Finnhub activa: $realDividends dividendos reales obtenidos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // API no configurada o no funcionando
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.amber.shade700, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    apiKeyType == 'sandbox' 
                      ? 'Usando API de prueba - Dividendos simulados'
                      : 'Dividendos simulados - Configura Finnhub para datos reales',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (!hasValidKey || apiKeyType == 'sandbox') ...[
              SizedBox(height: 8),
              Text(
                '💡 Para datos reales: Regístrate gratis en finnhub.io y configura tu API key',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
}
