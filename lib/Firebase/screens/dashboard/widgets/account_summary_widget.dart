// lib/screens/dashboard/widgets/account_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mis_finanza/models/account.dart';
import 'package:mis_finanza/models/movement.dart';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class AccountSummaryWidget extends StatefulWidget {
  const AccountSummaryWidget({super.key});

  @override
  _AccountSummaryWidgetState createState() => _AccountSummaryWidgetState();
}

class _AccountSummaryWidgetState extends State<AccountSummaryWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Account> _accounts = [];
  List<Movement> _movements = [];
  bool _isLoading = true;
  String? _error;
  bool _isExpanded = false; // Para el comportamiento desplegable

  // Filtro de período (por defecto mes actual)
  String _selectedPeriod = 'current_month';
  DateTime? _selectedCustomDate; // Para el selector de fecha personalizada

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      // Cargar cuentas y movimientos
      final accounts = await _firestoreService.getAccounts().first;
      final movements = await _firestoreService.getMovements().first;

      setState(() {
        _accounts = accounts;
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar datos: $e';
      });
    }
  }  // Mostrar selector de mes y año
  Future<void> _showMonthYearPicker() async {
    final now = DateTime.now();
    final initialDate = _selectedCustomDate ?? now;
    
    // Crear una lista de años disponibles (últimos 5 años y próximos 2)
    final currentYear = now.year;
    final years = List.generate(8, (index) => currentYear - 5 + index);
    
    // Nombres de los meses en español
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Seleccionar Período',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selector de año
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text('Año:', style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: selectedYear,
                          isExpanded: true,
                          items: years.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedYear = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Selector de mes
                  Row(
                    children: [
                      Icon(Icons.event, size: 20),
                      SizedBox(width: 8),
                      Text('Mes:', style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: selectedMonth,
                          isExpanded: true,
                          items: months.asMap().entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key + 1,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedMonth = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Vista previa del período seleccionado
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Período: ${months[selectedMonth - 1]} $selectedYear',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'year': selectedYear,
                      'month': selectedMonth,
                    });
                  },
                  child: Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedCustomDate = DateTime(result['year']!, result['month']!, 1);
      });
    }
  }

  // Filtrar movimientos por período
  List<Movement> _getFilteredMovements() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'current_month':
        return _movements.where((movement) {
          return movement.dateTime.year == now.year && 
                 movement.dateTime.month == now.month;
        }).toList();
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return _movements.where((movement) {
          return movement.dateTime.year == lastMonth.year && 
                 movement.dateTime.month == lastMonth.month;
        }).toList();
      case 'current_year':
        return _movements.where((movement) {
          return movement.dateTime.year == now.year;
        }).toList();
      case 'custom':
        if (_selectedCustomDate != null) {
          return _movements.where((movement) {
            return movement.dateTime.year == _selectedCustomDate!.year && 
                   movement.dateTime.month == _selectedCustomDate!.month;
          }).toList();
        }
        return _movements.where((movement) {
          return movement.dateTime.year == now.year && 
                 movement.dateTime.month == now.month;
        }).toList();
      case 'all':
      default:
        return _movements;
    }
  }
  // Calcular resumen por cuenta
  Map<String, AccountSummary> _calculateAccountSummaries() {
    final filteredMovements = _getFilteredMovements();
    final summaries = <String, AccountSummary>{};

    // Inicializar resúmenes
    for (final account in _accounts) {
      if (account.id != null) {
        summaries[account.id!] = AccountSummary(
          account: account,
          income: 0.0,
          expenses: 0.0,
          payments: 0.0,
          transfers: 0.0,
        );
      }
    }

    // Procesar movimientos
    for (final movement in filteredMovements) {
      final accountId = movement.accountId;
      if (!summaries.containsKey(accountId)) continue;

      switch (movement.type) {
        case 'income':
          summaries[accountId]!.income += movement.amount;
          break;
        case 'expense':
          summaries[accountId]!.expenses += movement.amount;
          break;
        case 'payment':
          // Solo contar pagos que salen de esta cuenta
          summaries[accountId]!.payments += movement.amount;
          break;
        case 'transfer':
          // Solo contar transferencias que salen de esta cuenta (origen)
          // El movement.accountId es la cuenta origen en transferencias
          summaries[accountId]!.transfers += movement.amount;
          break;
      }
    }

    return summaries;
  }  // Exportar datos a CSV y compartir inmediatamente
  Future<void> _exportToCSV() async {
    try {
      final summaries = _calculateAccountSummaries();
      
      // Crear los datos del CSV
      List<List<dynamic>> csvData = [
        // Encabezados
        ['Cuenta', 'Balance', 'Ingresos', 'Gastos', 'Pagos', 'Transferencias']
      ];
      
      // Agregar datos de cada cuenta
      for (final summary in summaries.values) {
        csvData.add([
          summary.account.name,
          summary.account.currentBalance,
          summary.income,
          summary.expenses,
          summary.payments,
          summary.transfers,
        ]);
      }
      
      // Convertir a string CSV
      String csvString = const ListToCsvConverter().convert(csvData);
      
      // Generar nombre del archivo con el período
      final periodName = _getPeriodName().replaceAll(' ', '_').toLowerCase();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'resumen_cuentas_${periodName}_$timestamp.csv';
      
      // Obtener directorio temporal para compartir
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Escribir archivo
      final file = File(filePath);
      await file.writeAsString(csvString);
      
      // Compartir el archivo inmediatamente
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Resumen de cuentas - ${_getPeriodName()}',
        subject: 'Exportación CSV - Resumen Financiero',
      );
      
      // Mostrar mensaje de éxito
      if (mounted) {
        String mensaje = 'Archivo CSV compartido exitosamente';
        
        // Personalizar mensaje según el resultado
        if (result.status == ShareResultStatus.success) {
          mensaje = 'Archivo CSV compartido exitosamente';
        } else if (result.status == ShareResultStatus.dismissed) {
          mensaje = 'Compartir cancelado. Archivo generado correctamente';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensaje,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Archivo: $fileName',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Compartir de nuevo',
              textColor: Colors.white,
              onPressed: () async {
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'Resumen de cuentas - ${_getPeriodName()}',
                );
              },
            ),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al exportar: $e',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  String _getPeriodName() {
    switch (_selectedPeriod) {
      case 'current_month':
        return DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now());
      case 'last_month':
        final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        return DateFormat('MMMM yyyy', 'es_ES').format(lastMonth);
      case 'current_year':
        return DateTime.now().year.toString();
      case 'custom':
        if (_selectedCustomDate != null) {
          return DateFormat('MMMM yyyy', 'es_ES').format(_selectedCustomDate!);
        }
        return 'Personalizado';
      case 'all':
        return 'Todo el tiempo';
      default:
        return 'Período seleccionado';
    }  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _buildErrorCard('Usuario no autenticado');
    }

    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_error != null) {
      return _buildErrorCard(_error!);
    }

    if (_accounts.isEmpty) {
      return _buildEmptyCard();
    }    final summaries = _calculateAccountSummaries();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Resumen por Cuenta',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              _getPeriodName().toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_selectedPeriod == 'custom') ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'PERSONALIZADO',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: _isExpanded 
              ? _buildAccountsList(summaries)
              : _buildCollapsedSummary(summaries),
          ),
        ],
      ),
    );
  }
  Widget _buildAccountsList(Map<String, AccountSummary> summaries) {
    return Column(
      children: [        // Controles de filtro (solo visibles cuando está expandido)
        Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del filtro
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Selector de período
              Row(
                children: [
                  Text(
                    'Período:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          isDense: true,
                          isExpanded: true,
                          style: Theme.of(context).textTheme.bodyMedium,
                          items: [
                            DropdownMenuItem(value: 'current_month', child: Text('Este mes')),
                            DropdownMenuItem(value: 'last_month', child: Text('Mes pasado')),
                            DropdownMenuItem(value: 'current_year', child: Text('Este año')),
                            DropdownMenuItem(value: 'custom', child: Text('Personalizado')),
                            DropdownMenuItem(value: 'all', child: Text('Todo')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPeriod = value;
                                if (value == 'custom' && _selectedCustomDate == null) {
                                  _selectedCustomDate = DateTime.now();
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Botón de calendario para período personalizado
                  if (_selectedPeriod == 'custom') ...[
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _showMonthYearPicker,
                        icon: Icon(
                          Icons.calendar_month_rounded,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 18,
                        ),
                        tooltip: 'Seleccionar mes y año',
                        constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.all(6),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Información del período personalizado seleccionado
              if (_selectedPeriod == 'custom' && _selectedCustomDate != null) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Período seleccionado: ${DateFormat('MMMM yyyy', 'es_ES').format(_selectedCustomDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Botón de exportación
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.file_download_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Exportar datos:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportToCSV,
                      icon: Icon(Icons.table_chart_rounded, size: 18),
                      label: Text('Exportar CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista de cuentas
        ...summaries.values.map((summary) => _buildAccountSummaryCard(summary)).toList(),
      ],
    );
  }

  Widget _buildCollapsedSummary(Map<String, AccountSummary> summaries) {
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalPayments = 0;
    double totalTransfers = 0;

    for (final summary in summaries.values) {
      totalIncome += summary.income;
      totalExpenses += summary.expenses;
      totalPayments += summary.payments;
      totalTransfers += summary.transfers;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Ingresos',
              totalIncome,
              Colors.green,
              Icons.trending_up_rounded,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Gastos',
              totalExpenses,
              Colors.red,
              Icons.trending_down_rounded,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Pagos',
              totalPayments,
              Colors.orange,
              Icons.payment_rounded,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Transferencias',
              totalTransfers,
              Colors.blue,
              Icons.swap_horiz_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSummaryCard(AccountSummary summary) {
    final account = summary.account;
    final hasActivity = summary.income > 0 || 
                       summary.expenses > 0 || 
                       summary.payments > 0 || 
                       summary.transfers > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasActivity 
          ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActivity 
            ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
            : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de la cuenta y balance
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getAccountTypeColor(account.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAccountTypeIcon(account.type),
                  color: _getAccountTypeColor(account.type),
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Balance: ${_formatCurrency(account.currentBalance)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasActivity) ...[
            SizedBox(height: 16),
            // Grid de métricas
            Row(
              children: [
                Expanded(child: _buildMetricItem('Ingresos', summary.income, Icons.add_rounded, Colors.green)),
                SizedBox(width: 12),
                Expanded(child: _buildMetricItem('Gastos', summary.expenses, Icons.remove_rounded, Colors.red)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMetricItem('Pagos', summary.payments, Icons.payment_rounded, Colors.orange)),
                SizedBox(width: 12),
                Expanded(child: _buildMetricItem('Transferencias', summary.transfers, Icons.swap_horiz_rounded, Colors.blue)),
              ],
            ),
          ] else ...[
            SizedBox(height: 8),
            Text(
              'Sin actividad en el período seleccionado',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccountTypeColor(String type) {
    switch (type) {
      case 'savings':
        return Colors.green;
      case 'checking':
        return Colors.blue;
      case 'credit':
        return Colors.orange;
      case 'investment':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type) {
      case 'savings':
        return Icons.savings_rounded;
      case 'checking':
        return Icons.account_balance_rounded;
      case 'credit':
        return Icons.credit_card_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando resumen de cuentas...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No hay cuentas registradas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega tus cuentas para ver el resumen de actividad',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Clase auxiliar para el resumen de cuenta
class AccountSummary {
  final Account account;
  double income;
  double expenses;
  double payments;
  double transfers;

  AccountSummary({
    required this.account,
    required this.income,
    required this.expenses,
    required this.payments,
    required this.transfers,
  });
}
