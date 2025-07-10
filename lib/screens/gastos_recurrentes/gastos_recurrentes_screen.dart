import 'package:flutter/material.dart';
import '../../models/gasto_recurrente.dart';
import '../../supabase/gasto_recurrente_service_supabase.dart';
import '../../supabase/cuenta_service_supabase.dart';
import '../../supabase/categoria_service_supabase.dart';
import '../../models/cuenta.dart';
import '../../models/categoria.dart';
import '../../Service/drawer.dart';

class GastosRecurrentesScreen extends StatefulWidget {
  const GastosRecurrentesScreen({Key? key}) : super(key: key);

  @override
  State<GastosRecurrentesScreen> createState() => _GastosRecurrentesScreenState();
}

class _GastosRecurrentesScreenState extends State<GastosRecurrentesScreen> {
  final GastoRecurrenteServiceSupabase _service = GastoRecurrenteServiceSupabase();
  final CuentaServiceSupabase _cuentaService = CuentaServiceSupabase();
  final CategoriaServiceSupabase _categoriaService = CategoriaServiceSupabase();
  List<GastoRecurrente> _gastos = [];
  List<Cuenta> _cuentas = [];
  List<Categoria> _categorias = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final gastos = await _service.getGastos();
      final cuentas = await _cuentaService.getCuentas();
      final categorias = await _categoriaService.getCategorias();
      setState(() {
        _gastos = gastos;
        _cuentas = cuentas;
        _categorias = categorias;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _openEditGasto({GastoRecurrente? gasto}) async {
    final frecuenciaCtrl = TextEditingController(text: gasto?.frecuenciaDias.toString() ?? '');
    final descripcionCtrl = TextEditingController(text: gasto?.descripcion ?? '');
    final montoCtrl = TextEditingController(text: gasto?.monto.toString() ?? '');
    int cuentaId = gasto?.cuentaId ?? (_cuentas.isNotEmpty ? _cuentas.first.id! : 0);
    int categoriaId = gasto?.categoriaId ?? (_categorias.isNotEmpty ? _categorias.first.id! : 0);
    DateTime? fechaInicio = gasto?.fechaInicio;
    DateTime? fechaFinal = gasto?.fechaFinal;
    final observacionCtrl = TextEditingController(text: gasto?.observacion ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gasto == null ? 'Agregar gasto recurrente' : 'Editar gasto recurrente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: frecuenciaCtrl, decoration: const InputDecoration(labelText: 'Frecuencia (días)'), keyboardType: TextInputType.number),
              TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
              TextField(controller: montoCtrl, decoration: const InputDecoration(labelText: 'Monto'), keyboardType: TextInputType.number),
              DropdownButtonFormField<int>(
                value: cuentaId,
                decoration: const InputDecoration(labelText: 'Cuenta asociada'),
                items: _cuentas.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: (v) => cuentaId = v ?? cuentaId,
              ),
              DropdownButtonFormField<int>(
                value: categoriaId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: (v) => categoriaId = v ?? categoriaId,
              ),
              ListTile(
                title: Text('Fecha de inicio: ${fechaInicio != null ? fechaInicio!.toLocal().toString().split(' ')[0] : 'Seleccionar'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fechaInicio ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => fechaInicio = picked);
                },
              ),
              ListTile(
                title: Text('Fecha final: ${fechaFinal != null ? fechaFinal!.toLocal().toString().split(' ')[0] : 'Seleccionar'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fechaFinal ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => fechaFinal = picked);
                },
              ),
              TextField(controller: observacionCtrl, decoration: const InputDecoration(labelText: 'Observación')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nuevo = GastoRecurrente(
                id: gasto?.id,
                frecuenciaDias: int.tryParse(frecuenciaCtrl.text) ?? 0,
                descripcion: descripcionCtrl.text,
                monto: double.tryParse(montoCtrl.text) ?? 0,
                cuentaId: cuentaId,
                categoriaId: categoriaId,
                fechaInicio: fechaInicio ?? DateTime.now(),
                fechaFinal: fechaFinal,
                observacion: observacionCtrl.text,
              );
              if (gasto == null) {
                await _service.addGasto(nuevo);
              } else {
                await _service.updateGasto(nuevo);
              }
              if (mounted) Navigator.pop(context);
              _loadAll();
            },
            child: Text(gasto == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteGasto(int id) async {
    await _service.deleteGasto(id);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos Recurrentes')),
      drawer: SupabaseDrawer(userEmail: null),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Descripción')),
                      DataColumn(label: Text('Monto')),
                      DataColumn(label: Text('Frecuencia (días)')),
                      DataColumn(label: Text('Cuenta')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Fecha inicio')),
                      DataColumn(label: Text('Fecha final')),
                      DataColumn(label: Text('Observación')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: _gastos.map((g) => DataRow(cells: [
                      DataCell(Text(g.descripcion)),
                      DataCell(Text(g.monto.toString())),
                      DataCell(Text(g.frecuenciaDias.toString())),
                      DataCell(Text(_cuentas.firstWhere((c) => c.id == g.cuentaId, orElse: () => Cuenta(id: 0, nombre: '-', tipoCuenta: '-', moneda: '-', saldoInicial: 0, tasaRendimiento: 0, llave: '-', numeroCuenta: '-')).nombre)),
                      DataCell(Text(_categorias.firstWhere((c) => c.id == g.categoriaId, orElse: () => Categoria(id: 0, nombre: '-', tipoCategoria: '-', tipoPresupuesto: '-')).nombre)),
                      DataCell(Text(g.fechaInicio.toLocal().toString().split(' ')[0])),
                      DataCell(Text(g.fechaFinal != null ? g.fechaFinal!.toLocal().toString().split(' ')[0] : '-')),
                      DataCell(Text(g.observacion ?? '')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditGasto(gasto: g),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteGasto(g.id!),
                          ),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditGasto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
