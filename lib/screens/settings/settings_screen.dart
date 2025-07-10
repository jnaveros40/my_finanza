// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mis_finanza/main.dart'; // Importar ThemeManager
import 'package:mis_finanza/services/export_service.dart';
import 'package:mis_finanza/services/import_service.dart'; // Importar ImportService
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:mis_finanza/services/user_data_wipe_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {  // Estado para switches de visibilidad de gráficos
  final  Map<String, bool> _dashboardWidgetsVisibility = {
    'AlertasFinancieras': true,
    'MetasAhorro': true,
    'FlujoEfectivo': true,
    'ComparacionesFinancieras': true,
    'SaludFinanciera': true,
    'TransaccionesRecientes': true,
    'GastosRecurrentes': true,
    'PlanificacionJubilacion': true,
    'AnalisisComercios': true,
    'CalendarioFinanciero': true,
    'ResumenGeneral': true,
    'ResumenCuentas': true,
    'TarjetasCredito': true,
    'MovimientosFiltrados': true,
    'Tendencias': true,
    'Ahorros': true,
    'ResumenTarjetas': true,
    'GastosPorCategoria': true,
    'IngresosPorCategoria': true,    
    'Presupuestos': true,
    'HistogramaMensual': true,
    'Deudas': true,
    'EvolucionPatrimonio': true,
    'WalletInversiones': true,
    'RendimientoPortafolio': true,
    'ROIInversiones': true,
    'Dividendos': true,
  };  // Estado para el orden de los widgets del dashboard
  List<String> _dashboardWidgetsOrder = [
    'AlertasFinancieras',
    'MetasAhorro',
    'FlujoEfectivo',
    'ComparacionesFinancieras',
    'SaludFinanciera',
    'TransaccionesRecientes',
    'GastosRecurrentes',
    'PlanificacionJubilacion',
    'AnalisisComercios',
    'CalendarioFinanciero',
    'ResumenGeneral',
    'ResumenCuentas',
    'TarjetasCredito',
    'MovimientosFiltrados',
    'Tendencias',
    'Ahorros',
    'GastosPorCategoria',
    'IngresosPorCategoria',    
    'Presupuestos',
    'HistogramaMensual',
    'Deudas',
    'EvolucionPatrimonio',    //'Inversiones',
    'WalletInversiones',    'RendimientoPortafolio',
    'ROIInversiones',
    'Dividendos',
  ];  // Mapa de nombres amigables para los widgets del dashboard
  final Map<String, String> _dashboardWidgetNames = {
    'AlertasFinancieras': 'Alertas y Notificaciones Inteligentes',
    'MetasAhorro': 'Metas de Ahorro y Objetivos',
    'FlujoEfectivo': 'Flujo de Efectivo y Proyecciones',
    'ComparacionesFinancieras': 'Comparaciones y Análisis Comparativo',
    'SaludFinanciera': 'Salud Financiera y Métricas Clave',
    'TransaccionesRecientes': 'Transacciones Recientes Inteligentes',
    'GastosRecurrentes': 'Gastos Recurrentes y Suscripciones',
    'PlanificacionJubilacion': 'Planificación de Jubilación',
    'AnalisisComercios': 'Análisis por Comercio y Establecimiento',
    'CalendarioFinanciero': 'Calendario de Eventos Financieros',
    'ResumenGeneral': 'Resumen Financiero',
    'ResumenCuentas': 'Resumen de Cuentas por Período',
    'TarjetasCredito': 'Tarjetas de Crédito',
    'MovimientosFiltrados': 'Análisis Detallado de Movimientos',
    'Tendencias': 'Análisis de Tendencias',
    'Ahorros': 'Distribucion de Cuentas de Ahorro',
    'GastosPorCategoria': 'Gastos por Categoría',
    'IngresosPorCategoria': 'Ingresos por Categoría',
    'Presupuestos': 'Progreso de Presupuestos',
    'HistogramaMensual': 'Histograma Mensual',
    'Deudas': 'Resumen de Deudas',
    'EvolucionPatrimonio': 'Evolución del Patrimonio Neto',
    //'Inversiones': 'Resumen de Inversiones',
    'WalletInversiones': 'Wallet de Inversiones',
    'RendimientoPortafolio': 'Rendimiento del Portafolio',
    'ROIInversiones': 'ROI de Inversiones',
    'Dividendos': 'Análisis de Dividendos',
  };
  @override
  void initState() {
    super.initState();
    _loadDashboardWidgetsVisibility();
    _loadDashboardWidgetsOrder();
    _cleanupObsoleteWidgetPreferences();
  }Future<void> _loadDashboardWidgetsVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Para cada widget en nuestro mapa de visibilidad actual
      _dashboardWidgetsVisibility.forEach((key, value) {
        // Si la preferencia existe, usar ese valor, de lo contrario usar true (visible)
        bool savedValue = prefs.getBool('dashboard_widget_$key') ?? true;
        _dashboardWidgetsVisibility[key] = savedValue;
      });
    });
  }Future<void> _loadDashboardWidgetsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('dashboard_widgets_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      // Filtrar el orden guardado para incluir solo widgets que existen en el código actual
      List<String> validSavedWidgets = savedOrder.where((widget) => 
        _dashboardWidgetsOrder.contains(widget)).toList();
      
      // Agregar widgets que están en el código actual pero no en el orden guardado
      List<String> missingWidgets = [];
      for (var widgetKey in _dashboardWidgetsOrder) {
        if (!validSavedWidgets.contains(widgetKey)) {
          missingWidgets.add(widgetKey);
        }
      }
      
      setState(() {
        if (missingWidgets.isEmpty) {
          _dashboardWidgetsOrder = validSavedWidgets;
        } else {
          // Crear una nueva lista que incluya los widgets válidos guardados más los faltantes
          _dashboardWidgetsOrder = [...validSavedWidgets, ...missingWidgets];
        }
      });
    }
  }

  Future<void> _saveDashboardWidgetsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dashboard_widgets_order', _dashboardWidgetsOrder);
  }
  // Implementa _saveDashboardWidgetsVisibility para guardar todos los switches a la vez
  Future<void> _saveDashboardWidgetsVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _dashboardWidgetsVisibility.entries) {
      await prefs.setBool('dashboard_widget_${entry.key}', entry.value);
    }
  }

  // Método para limpiar preferencias de widgets obsoletos
  Future<void> _cleanupObsoleteWidgetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
      // Lista de widgets obsoletos que necesitamos eliminar
    final obsoleteWidgets = ['ResumenCuentas', 'Inversiones', 'ResumenTarjetas'];
    
    for (final obsoleteWidget in obsoleteWidgets) {
      final key = 'dashboard_widget_$obsoleteWidget';
      if (allKeys.contains(key)) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acceder al ThemeManager usando Provider
    final themeManager = Provider.of<ThemeManager>(context);    // Lista de colores de acento disponibles
    final Map<String, Color> accentColors = {
      'Rojo': Colors.redAccent,
      'Amarillo': Colors.yellow,
      'Azul': Colors.blue,
      'Verde': Colors.green,
      'Naranja': Colors.orange,
      'Púrpura': Colors.purple,
      'Teal': Colors.teal,
    };

    // Determinar el color de acento actual que esté en la lista
    Color currentAccentColor = accentColors.values.contains(themeManager.baseAccentColor)
        ? themeManager.baseAccentColor
        : Colors.teal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [          Card(
            elevation: 4.0,
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema de la Aplicación', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Modo Oscuro', style: Theme.of(context).textTheme.bodyMedium),
                      Switch(
                        value: themeManager.themeMode == ThemeMode.dark,
                        onChanged: (isOn) {
                          themeManager.setThemeMode(isOn ? ThemeMode.dark : ThemeMode.light);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(color: Theme.of(context).dividerColor),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alto Contraste', style: Theme.of(context).textTheme.bodyMedium),
                            SizedBox(height: 4),
                            Text(
                              'Usa negro/blanco según el tema',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: themeManager.isHighContrastMode,
                        onChanged: (isOn) {
                          themeManager.setHighContrastMode(isOn);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),          Card(
            elevation: 4.0,
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color de Acento', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  if (themeManager.isHighContrastMode) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.contrast,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alto contraste activo: usando ${themeManager.themeMode == ThemeMode.dark ? 'blanco' : 'negro'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  Opacity(
                    opacity: themeManager.isHighContrastMode ? 0.5 : 1.0,
                    child: DropdownButtonFormField<Color>(
                      decoration: InputDecoration(
                        labelText: themeManager.isHighContrastMode 
                            ? 'Color base (inactivo en alto contraste)'
                            : 'Seleccionar Color',
                        border: OutlineInputBorder(),
                      ),
                      value: currentAccentColor,
                      items: accentColors.entries.map((entry) {
                        return DropdownMenuItem<Color>(
                          value: entry.value,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                color: entry.value,
                                margin: EdgeInsets.only(right: 8),
                              ),
                              Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: themeManager.isHighContrastMode ? null : (newColor) {
                        if (newColor != null) {
                          themeManager.setAccentColor(newColor);
                        }
                      },
                      isExpanded: true,
                    ),
                  ),
                  if (themeManager.isHighContrastMode) ...[
                    SizedBox(height: 8),
                    Text(
                      'Desactiva el alto contraste para cambiar el color de acento',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 4.0,
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mostrar/Ocultar y Ordenar Gráficos del Dashboard', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  _buildDashboardWidgetsOrderSection(),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 4.0,
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exportar datos', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text('Exporta toda tu información financiera (cuentas, movimientos, presupuestos, inversiones y deudas) en un archivo JSON.'),
                  SizedBox(height: 12),
                  // Botón para Exportar Datos
                  ListTile(
                    leading: Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                    title: Text('Exportar Datos', style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text('Guarda tus datos financieros en un archivo JSON.', style: Theme.of(context).textTheme.bodySmall),
                    onTap: () async {
                      final exportService = ExportService();
                      final scaffoldMessenger = ScaffoldMessenger.of(context); // Guardar referencia
                      
                      // Generar el JSON string
                      final String jsonString = await exportService.exportAllDataAsJson();
                      
                      // Guardar el string en un archivo temporal para compartir
                      final directory = await getTemporaryDirectory(); // Necesita path_provider
                      final filePath = '${directory.path}/finzanza_data_export.json';
                      final file = File(filePath); // Necesita dart:io
                      await file.writeAsString(jsonString);


                      if (filePath.isNotEmpty) { // filePath ahora no será null, sino que contendrá la ruta
                        final box = context.findRenderObject() as RenderBox?;
                        Share.shareXFiles(
                          [XFile(filePath)],
                          text: 'Mis datos financieros de Finzanza App.',
                          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                        );
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Datos exportados y listos para compartir en: $filePath')),
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Error al exportar datos.')),
                        );
                      }
                    },
                  ),
                  // Botón para Importar Datos
                  ListTile(
                    leading: Icon(Icons.file_download, color: Theme.of(context).colorScheme.primary), // Icono corregido
                    title: Text('Importar Datos', style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text('Carga tus datos financieros desde un archivo JSON.', style: Theme.of(context).textTheme.bodySmall),
                    onTap: () async {
                      final importService = ImportService();
                      final scaffoldMessenger = ScaffoldMessenger.of(context); // Guardar referencia
                      bool success = await importService.importData(context);

                      if (success) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Datos importados correctamente. Reinicia la app para ver los cambios.')),
                          // Considera ofrecer un refresh automático o una guía más específica
                        );
                      } else {
                        // El servicio de importación ya muestra mensajes de error/cancelación
                        // scaffoldMessenger.showSnackBar(
                        //   const SnackBar(content: Text('Error o cancelación al importar datos.')),
                        // );
                      }
                    },
                  ),
                  // Botón para Borrar Todos los Datos
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.redAccent),
                    title: Text('Borrar todos mis datos', style: TextStyle(color: Colors.redAccent)),
                    subtitle: Text('Elimina todas tus cuentas, movimientos, presupuestos, deudas y categorías. Esta acción no se puede deshacer.', style: Theme.of(context).textTheme.bodySmall),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('¿Borrar todos tus datos?'),
                          content: Text('Esta acción eliminará toda tu información financiera (cuentas, movimientos, presupuestos, deudas y categorías) asociada a tu usuario. ¿Estás seguro?'),
                          actions: [
                            TextButton(
                              child: Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: Text('Borrar', style: TextStyle(color: Colors.red)),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          // Importar el servicio de borrado masivo
                          // ignore: unused_import
                          
                          await UserDataWipeService.wipeAllUserData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('¡Todos tus datos han sido eliminados!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al borrar datos: ' + e.toString())),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardWidgetsOrderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Orden y visibilidad de los módulos del dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _dashboardWidgetsOrder.removeAt(oldIndex);
              _dashboardWidgetsOrder.insert(newIndex, item);
            });
            _saveDashboardWidgetsOrder();
          },
          children: _dashboardWidgetsOrder.map((widgetKey) {
            return ListTile(
              key: ValueKey(widgetKey),
              title: Text(_dashboardWidgetNames[widgetKey] ?? widgetKey),
              leading: Switch(
                value: _dashboardWidgetsVisibility[widgetKey] ?? true,
                onChanged: (value) {
                  setState(() {
                    _dashboardWidgetsVisibility[widgetKey] = value;
                  });
                  _saveDashboardWidgetsVisibility();
                },
              ),
              trailing: const Icon(Icons.drag_handle),
            );
          }).toList(),
        ),
      ],
    );
  }
}
