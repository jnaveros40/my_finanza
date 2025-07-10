import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mis_finanza/models/investment.dart';
import 'package:mis_finanza/screens/investments/investments_screen.dart'; // Para calcularValorActualYBeneficio, mapInvestmentToFinnhubSymbol, normalizeCryptoSymbol
import 'package:mis_finanza/services/stock_quote_cache_service.dart'; // Para el servicio de cotizaciones en tiempo real
import 'package:intl/intl.dart';

class DashboardWalletInvestment extends StatefulWidget {
  final List<Investment> investments;
  final String displayCurrency;

  const DashboardWalletInvestment({
    super.key,
    required this.investments,
    required this.displayCurrency,
  });

  @override
  _DashboardWalletInvestmentState createState() => _DashboardWalletInvestmentState();
}

class _DashboardWalletInvestmentState extends State<DashboardWalletInvestment> {
  String _selectedFilterMode = 'type'; // 'type' para filtrar por tipos, 'asset' para filtrar por activos
  String _selectedTypeFilter = 'all';
  String _selectedAssetFilter = 'all';
  String _selectedPlatformFilter = 'all'; // Filtro por plataforma
  bool _showOnlyAboveFivePercent = false;
  String _selectedValueMode = 'purchase'; // 'purchase' para valor de compra, 'current' para valor actual

  // Mapa de colores para diferentes inversiones
  static const List<Color> _chartColors = [
    Colors.teal,
    Colors.indigo,
    Colors.purple,
    Colors.amber,
    Colors.cyan,
    Colors.orange,
    Colors.pink,
    Colors.green,
    Colors.red,
    Colors.brown,
    Colors.grey,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.lime,
    Colors.deepPurple,
  ];

  @override
  Widget build(BuildContext context) {
    final filteredInvestments = _getFilteredInvestments();
    final investmentCount = filteredInvestments.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Icon(
          Icons.account_balance_wallet,
          color: Colors.green,
          size: 24,
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text('Wallet de Inversiones', style: Theme.of(context).textTheme.titleLarge),
        subtitle: investmentCount > 0 
          ? FutureBuilder<List<double>>(
              future: calcularValorActualYBeneficio(filteredInvestments),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      Text(
                        '$investmentCount ${investmentCount == 1 ? 'inversión' : 'inversiones'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ],
                  );
                }

                double totalCurrentValue = snapshot.data != null ? snapshot.data![0] : 0.0;
                double totalGainLoss = snapshot.data != null ? snapshot.data![1] : 0.0;
                double totalInvested = filteredInvestments.fold(0.0, (sum, investment) => sum + investment.totalInvested);
                double gainLossPercentage = totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$investmentCount ${investmentCount == 1 ? 'inversión' : 'inversiones'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 14,
                          color: totalCurrentValue > 0 ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Valor: ${_formatCurrency(totalCurrentValue, widget.displayCurrency)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: totalCurrentValue > 0 
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade300
                                    : Colors.green.shade700)
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          totalGainLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: totalGainLoss >= 0 ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${totalGainLoss >= 0 ? '+' : ''}${_formatCurrency(totalGainLoss, widget.displayCurrency)} (${totalGainLoss >= 0 ? '+' : ''}${gainLossPercentage.toStringAsFixed(1)}%)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: totalGainLoss >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            )
          : Text(
              'Sin inversiones activas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        children: [
          FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: _calculateInvestmentData(filteredInvestments),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Error al calcular datos de inversión: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              
              final investmentData = snapshot.data ?? {};
              final totalInvested = investmentData.values.fold(0.0, (sum, data) => sum + (data['value'] as double));

              return _buildInvestmentContent(filteredInvestments, investmentData, totalInvested);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentContent(List<Investment> filteredInvestments, Map<String, Map<String, dynamic>> investmentData, double totalInvested) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y tooltip
          Row(
            children: [
              Icon(Icons.pie_chart, size: 20, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Portafolio de Inversiones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Tooltip(
                message: 'Visualización de la distribución porcentual de tu portafolio de inversiones',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          Divider(height: 24),

          // Resumen financiero con métricas principales
          FutureBuilder<List<double>>(
            future: calcularValorActualYBeneficio(filteredInvestments),
            builder: (context, snapshot) {
              double totalCurrentValue = snapshot.data != null ? snapshot.data![0] : 0.0;
              double totalGainLoss = snapshot.data != null ? snapshot.data![1] : 0.0;
              double gainLossPercentage = totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;
              
              return Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).primaryColor.withOpacity(0.15)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    // Total dinámico según el modo seleccionado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                                Icons.input,
                                size: 18,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade300
                                    : Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                                'Total Invertido:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            ),
                          ],
                        ),                        Text(
                          _formatCurrency(
                            filteredInvestments.fold(0.0, (sum, investment) => sum + investment.totalInvested),
                            widget.displayCurrency
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade300
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Valor actual
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 18,
                              color: totalCurrentValue > 0 
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.green.shade300
                                      : Colors.green)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Valor Actual:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        snapshot.connectionState == ConnectionState.waiting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _formatCurrency(totalCurrentValue, widget.displayCurrency),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: totalCurrentValue > 0 
                                      ? (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.green.shade300
                                          : Colors.green.shade700)
                                      : Theme.of(context).disabledColor,
                                ),
                              ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Beneficio/Pérdida
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: totalGainLoss >= 0 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: totalGainLoss >= 0 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                totalGainLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                                size: 18,
                                color: totalGainLoss >= 0 ? Colors.green : Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                totalGainLoss >= 0 ? 'Beneficio:' : 'Pérdida:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          snapshot.connectionState == ConnectionState.waiting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${totalGainLoss >= 0 ? '+' : ''}${_formatCurrency(totalGainLoss, widget.displayCurrency)}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: totalGainLoss >= 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      '${totalGainLoss >= 0 ? '+' : ''}${gainLossPercentage.toStringAsFixed(2)}%',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: totalGainLoss >= 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Sección de filtros
          _buildFiltersSection(),

          // Gráfico de pastel
          if (totalInvested > 0)
            _buildChartSection(investmentData, totalInvested)
          else
            _buildEmptyState(),

          // Leyenda con detalles
          if (totalInvested > 0) 
            _buildLegendSection(investmentData, totalInvested),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Filtros de Visualización',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildChartSection(Map<String, Map<String, dynamic>> investmentData, double totalInvested) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.donut_large, size: 18, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Gráfico de Distribución',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildPieChart(investmentData, totalInvested),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: 12),
            Text(
              'No hay inversiones para mostrar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).disabledColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Agrega inversiones para ver la distribución',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendSection(Map<String, Map<String, dynamic>> investmentData, double totalInvested) {
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.legend_toggle, size: 18, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Detalle de Inversiones',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildLegend(investmentData, totalInvested),
        ],
      ),
    );
  }
  Widget _buildFilters() {
    return Column(
      children: [
        // Selector de modo de filtro (tipo vs activo)
        Row(
          children: [
            Icon(Icons.filter_alt, size: 16, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Filtrar por:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFilterMode,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'type',
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Tipo de inversión'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'asset',
                    child: Row(
                      children: [
                        Icon(Icons.show_chart, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Activos'),
                      ],
                    ),
                  ),
                ],                onChanged: (value) {
                  setState(() {
                    _selectedFilterMode = value!;
                    // Resetear filtros cuando cambie el modo
                    _selectedTypeFilter = 'all';
                    _selectedAssetFilter = 'all';
                    _selectedPlatformFilter = 'all';
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Filtro dinámico según el modo seleccionado
        if (_selectedFilterMode == 'asset') ...[
          // Filtro de tipo de inversión
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Tipo de inversión:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTypeFilter,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', 
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive, size: 16),
                                SizedBox(width: 8),
                                Text('Todas'),
                              ],
                            ),
                          ),
                    DropdownMenuItem(value: 'stocks', 
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Acciones'),
                              ],
                            ),
                          ),
                    DropdownMenuItem(
                            value: 'funds', 
                            child: Row(
                              children: [
                                Icon(Icons.account_balance, size: 16, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Fondos'),
                              ],
                            ),
                          ),
                    DropdownMenuItem(
                            value: 'crypto', 
                            child: Row(
                              children: [
                                Icon(Icons.currency_bitcoin, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Criptomonedas'),
                              ],
                            ),
                          ),
                    DropdownMenuItem(
                            value: 'real_estate', 
                            child: Row(
                              children: [
                                Icon(Icons.home, size: 16, color: Colors.brown),
                                SizedBox(width: 8),
                                Text('Bienes Raíces'),
                              ],
                            ),
                          ),
                    DropdownMenuItem(
                            value: 'bonds', 
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long, size: 16, color: Colors.purple),
                                SizedBox(width: 8),
                                Text('Bonos'),
                              ],
                            ),
                          ),
                    DropdownMenuItem(
                            value: 'other', 
                            child: Row(
                              children: [
                                Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Otros'),
                              ],
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
          ),
        ], /*else if (_selectedFilterMode == 'asset') ...[
          // Filtro de activo específico
          Row(
            children: [
              Icon(Icons.show_chart, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                'Activo específico:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAssetFilter,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive, size: 16),
                          SizedBox(width: 8),
                          Text('Todos los activos'),
                        ],
                      ),
                    ),
                    ..._getUniqueAssets().map((asset) => DropdownMenuItem(
                      value: asset,
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(asset.toUpperCase()),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAssetFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],*/
        SizedBox(height: 12),
        
        // Filtro de modo de valor
        Row(
          children: [
            Icon(Icons.attach_money, size: 16, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Mostrar valores:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedValueMode,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'purchase',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('V. compra'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'current',
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('V. Actual'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedValueMode = value!;
                  });
                },
              ),
            ),
          ],        ),
        SizedBox(height: 12),

        // Filtro por plataforma
        Row(
          children: [
            Icon(Icons.business, size: 16, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'Plataforma:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPlatformFilter,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                ),
                items: _getUniquePlatforms().map<DropdownMenuItem<String>>((String platform) {
                  return DropdownMenuItem<String>(
                    value: platform,
                    child: Row(
                      children: [
                        Icon(
                          platform == 'all' 
                            ? Icons.all_inclusive 
                            : platform == 'sin_plataforma'
                              ? Icons.help_outline
                              : Icons.business,
                          size: 16,
                          color: platform == 'all' 
                            ? Colors.grey 
                            : platform == 'sin_plataforma'
                              ? Colors.orange
                              : Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          platform == 'all' 
                            ? 'Todas las plataformas'
                            : platform == 'sin_plataforma'
                              ? 'Sin plataforma'
                              : platform,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlatformFilter = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Filtro de >5%
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blue.shade900.withOpacity(0.2)
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _showOnlyAboveFivePercent,
                onChanged: (value) {
                  setState(() {
                    _showOnlyAboveFivePercent = value!;
                  });
                },
              ),
              SizedBox(width: 8),
              Icon(Icons.pie_chart, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Mostrar solo inversiones >5% (agrupar otras como "Otros")',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, Map<String, dynamic>> investmentData, double totalInvested) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: _buildPieChartSections(investmentData, totalInvested),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, Map<String, dynamic>> investmentData, double totalInvested) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...investmentData.entries.map((entry) {
            final value = entry.value['value'] as double;
            final quantity = entry.value['quantity'] as double;
            final symbol = entry.value['symbol'] as String;
            final purchaseValue = entry.value['purchaseValue'] as double;
            final currentValue = entry.value['currentValue'] as double;
            final percentage = (value / totalInvested) * 100;
            
            // Calcular ganancia/pérdida si estamos mostrando valor actual
            final gainLoss = currentValue > 0 ? currentValue - purchaseValue : 0.0;
            final gainLossPercentage = purchaseValue > 0 ? (gainLoss / purchaseValue) * 100 : 0.0;
            
            final colorIndex = investmentData.keys.toList().indexOf(entry.key) % _chartColors.length;

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _chartColors[colorIndex].withOpacity(0.3),
                  width: 2.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con nombre y porcentaje
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _chartColors[colorIndex],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _chartColors[colorIndex],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mostrar cantidad de acciones/unidades con formato mejorado
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            size: 14,
                            color: Theme.of(context).hintColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Cantidad: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey.shade400 
                                  : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _formatQuantity(quantity, symbol),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(value, widget.displayCurrency),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _chartColors[colorIndex],
                        ),
                      ),
                    ],
                  ),
                  // Mostrar información adicional si estamos en modo valor actual
                  if (_selectedValueMode == 'current' && currentValue > 0) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [                          Text(
                            'Compra: ${_formatCurrency(purchaseValue, widget.displayCurrency)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey.shade400 
                                  : Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gainLoss >= 0 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${gainLoss >= 0 ? '+' : ''}${_formatCurrency(gainLoss, widget.displayCurrency)} (${gainLossPercentage >= 0 ? '+' : ''}${gainLossPercentage.toStringAsFixed(1)}%)',                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: gainLoss >= 0 
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.green.shade300
                                      : Colors.green.shade700)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.red.shade300
                                      : Colors.red.shade700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
            ),
            );
            }),        ],
      ),
    );
  }

  // Helper para obtener plataformas únicas
  List<String> _getUniquePlatforms() {
    Set<String> platforms = {'all'}; // Comenzar con "all"
    
    for (var investment in widget.investments) {
      if (investment.platform != null && investment.platform!.isNotEmpty) {
        platforms.add(investment.platform!);
      } else {
        platforms.add('sin_plataforma');
      }
    }
    
    return platforms.toList()..sort();
  }

  List<Investment> _getFilteredInvestments() {
    List<Investment> filtered = widget.investments;

    // Filtrar por plataforma si no es "all"
    if (_selectedPlatformFilter != 'all') {
      filtered = filtered.where((investment) => 
        investment.platform?.toLowerCase() == _selectedPlatformFilter.toLowerCase() ||
        (investment.platform == null && _selectedPlatformFilter == 'sin_plataforma')
      ).toList();
    }

    // Filtrar según el modo seleccionado
    if (_selectedFilterMode == 'type') {
      // Filtrar por tipo si no es "all"
      if (_selectedTypeFilter != 'all') {
        filtered = filtered.where((investment) => investment.type == _selectedTypeFilter).toList();
      }
    } else if (_selectedFilterMode == 'asset') {
      // En modo "activo específico", aplicar el filtro de tipo de inversión
      if (_selectedTypeFilter != 'all') {
        filtered = filtered.where((investment) => investment.type == _selectedTypeFilter).toList();
      }
      
      // Luego filtrar por activo específico si no es "all"
      if (_selectedAssetFilter != 'all') {
        filtered = filtered.where((investment) => investment.isinSymbol == _selectedAssetFilter).toList();
      }
    }

    return filtered;
  }
  // Estructura para almacenar datos de inversión más completos usando cálculos en tiempo real
  Future<Map<String, Map<String, dynamic>>> _calculateInvestmentData(List<Investment> investments) async {
    // Mapa para almacenar datos por clave (puede ser nombre o tipo según el filtro)
    Map<String, Map<String, dynamic>> investmentData = {};

    // Importar las funciones necesarias
    final StockQuoteCacheService stockService = StockQuoteCacheService();
    
    // Sumar datos según el modo de filtro seleccionado
    for (var investment in investments) {
      double realTimeCurrentValue = 0.0;
      
      // Calcular valor actual en tiempo real si es posible
      if (_selectedValueMode == 'current') {
        final symbol = mapInvestmentToFinnhubSymbol(investment);
        if (symbol != null) {
          try {
            final quote = await stockService.getQuote(symbol);
            if (quote != null && quote.price > 0) {
              realTimeCurrentValue = quote.price * investment.currentQuantity;
            }
          } catch (e) {
            // Silenciar errores de red, usar valor estimado como fallback
          }
        }
        
        // Si no se pudo obtener precio en tiempo real, usar el estimado existente
        if (realTimeCurrentValue == 0.0) {
          realTimeCurrentValue = investment.estimatedCurrentValue;
        }
      }
      
      // Determinar qué valor usar según el filtro seleccionado
      double valueToUse;
      if (_selectedValueMode == 'current') {
        // Usar valor actual en tiempo real (si está disponible, sino usar valor de compra)
        valueToUse = realTimeCurrentValue > 0 
            ? realTimeCurrentValue 
            : investment.totalInvested;
      } else {
        // Usar valor de compra (por defecto)
        valueToUse = investment.totalInvested;
      }
          // Determinar la clave de agrupación según el modo de filtro
    String groupingKey;
    if (_selectedFilterMode == 'type') {
      // Agrupar por tipo de inversión
      groupingKey = _getInvestmentTypeDisplayName(investment.type);
    } else {
      // Agrupar por activo individual (comportamiento anterior)
      groupingKey = investment.name;
    }
      
      if (!investmentData.containsKey(groupingKey)) {
        investmentData[groupingKey] = {
          'value': valueToUse,
          'quantity': investment.currentQuantity, // Usamos currentQuantity en lugar de totalQuantity
          'symbol': '', // Ya no usamos el ISIN como símbolo
          'purchaseValue': investment.totalInvested, // Guardamos también el valor de compra para referencia
          'currentValue': realTimeCurrentValue > 0 ? realTimeCurrentValue : investment.estimatedCurrentValue, // Valor actual en tiempo real o estimado
        };
      } else {
        investmentData[groupingKey]!['value'] += valueToUse;
        investmentData[groupingKey]!['quantity'] += investment.currentQuantity; // Usamos currentQuantity
        investmentData[groupingKey]!['purchaseValue'] += investment.totalInvested;
        investmentData[groupingKey]!['currentValue'] += (realTimeCurrentValue > 0 ? realTimeCurrentValue : investment.estimatedCurrentValue);
      }
    }

    // Si está activado el filtro de >5%, agrupar las menores
    if (_showOnlyAboveFivePercent && investmentData.isNotEmpty) {
      final totalInvested = investmentData.values.fold(0.0, (sum, data) => sum + (data['value'] as double));
      final fivePercentThreshold = totalInvested * 0.05;

      Map<String, Map<String, dynamic>> filteredData = {};
      double othersAmount = 0.0;
      double othersQuantity = 0.0;
      double othersPurchaseValue = 0.0;
      double othersCurrentValue = 0.0;

      // Ordenar por valor antes de filtrar
      var sortedEntries = investmentData.entries.toList()
        ..sort((a, b) => (b.value['value'] as double).compareTo(a.value['value'] as double));

      for (var entry in sortedEntries) {
        if ((entry.value['value'] as double) >= fivePercentThreshold) {
          filteredData[entry.key] = entry.value;
        } else {
          othersAmount += (entry.value['value'] as double);
          othersQuantity += (entry.value['quantity'] as double);
          othersPurchaseValue += (entry.value['purchaseValue'] as double);
          othersCurrentValue += (entry.value['currentValue'] as double);
        }
      }

      if (othersAmount > 0) {
        filteredData['Otros'] = {
          'value': othersAmount,
          'quantity': othersQuantity,
          'symbol': '',
          'purchaseValue': othersPurchaseValue,
          'currentValue': othersCurrentValue,
        };
      }

      return filteredData;
    }

    // Ordenar el mapa por valor (de mayor a menor)
    var sortedEntries = investmentData.entries.toList()
      ..sort((a, b) => (b.value['value'] as double).compareTo(a.value['value'] as double));
    
    Map<String, Map<String, dynamic>> sortedData = {};
    for (var entry in sortedEntries) {
      sortedData[entry.key] = entry.value;
    }

    return sortedData;
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, Map<String, dynamic>> investmentData, double totalInvested) {
    return investmentData.entries.map((entry) {
      final value = entry.value['value'] as double;
      final percentage = (value / totalInvested) * 100;
      final colorIndex = investmentData.keys.toList().indexOf(entry.key) % _chartColors.length;

      return PieChartSectionData(
        color: _chartColors[colorIndex],
        value: value,
        title: percentage >= 5.0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();  }

  // Helper para obtener el texto a mostrar para el tipo de inversión
  String _getInvestmentTypeDisplayName(String type) {
    switch (type) {
      case 'stocks': return 'Acciones';
      case 'funds': return 'Fondos de Inversión';
      case 'crypto': return 'Criptomonedas';
      case 'real_estate': return 'Bienes Raíces';
      case 'bonds': return 'Bonos';
      case 'other': return 'Otros';
      default: return type;
    }
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: amount >= 1000 ? 0 : 2,
    );
    return formatter.format(amount);
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'COP': return '\$';
      case 'GBP': return '£';
      default: return currency;
    }
  }

  String _formatQuantity(double quantity, String symbol) {
    // Si la cantidad es 0, mostrar explícitamente
    if (quantity == 0) {
      return '0';
    }
    
    // Eliminar decimales si son cero
    String formattedQuantity;
    if (quantity.truncateToDouble() == quantity) {
      // Si es un número entero, no mostrar decimales
      formattedQuantity = quantity.toInt().toString();
    } else if (quantity < 1) {
      // Para cantidades pequeñas (como criptomonedas) mostrar más decimales
      formattedQuantity = quantity.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } else {
      // Para cantidades más grandes, mostrar dos decimales
      formattedQuantity = quantity.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }    // Ya no añadimos el símbolo (ISIN), solo devolvemos la cantidad formateada
    return formattedQuantity;
  }
}
