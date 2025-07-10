import 'package:flutter/material.dart';
import '../../models/movimiento.dart';
import '../../supabase/movimiento_service_supabase.dart';
import '../../supabase/cuenta_service_supabase.dart';
import '../../supabase/categoria_service_supabase.dart';
import '../../models/cuenta.dart';
import '../../models/categoria.dart';
import '../../Service/drawer.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({Key? key}) : super(key: key);

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final MovimientoServiceSupabase _service = MovimientoServiceSupabase();
  final CuentaServiceSupabase _cuentaService = CuentaServiceSupabase();
  final CategoriaServiceSupabase _categoriaService = CategoriaServiceSupabase();
  List<Movimiento> _movimientos = [];
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
      final movimientos = await _service.getMovimientos();
      final cuentas = await _cuentaService.getCuentas();
      final categorias = await _categoriaService.getCategorias();
      setState(() {
        _movimientos = movimientos;
        _cuentas = cuentas;
        _categorias = categorias;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _openEditMovimiento({Movimiento? movimiento}) async {
    final descripcionCtrl = TextEditingController(text: movimiento?.descripcion ?? '');
    final montoCtrl = TextEditingController(text: movimiento?.monto.toString() ?? '');
    int cuentaId = movimiento?.cuentaId ?? (_cuentas.isNotEmpty ? _cuentas.first.id! : 0);
    int? categoriaId = movimiento?.categoriaId;
    String tipoMovimiento = movimiento?.tipoMovimiento ?? 'Gasto';
    int? cuentaDestinoId = movimiento?.cuentaDestinoId;
    DateTime? fecha = movimiento?.fecha ?? DateTime.now();
    final observacionCtrl = TextEditingController(text: movimiento?.observacion ?? '');

    final _formKey = GlobalKey<FormState>();
    String? descripcionError;
    String? montoError;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          String? cuentaDestinoError;
          return AlertDialog(
            title: Text(movimiento == null ? 'Agregar movimiento' : 'Editar movimiento'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: descripcionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        errorText: descripcionError,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es obligatoria';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: montoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        errorText: montoError,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El monto es obligatorio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingrese un monto válido';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: tipoMovimiento,
                      decoration: const InputDecoration(labelText: 'Tipo de movimiento'),
                      items: const [
                        DropdownMenuItem(value: 'Ingreso', child: Text('Ingreso')),
                        DropdownMenuItem(value: 'Gasto', child: Text('Gasto')),
                        DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                        DropdownMenuItem(value: 'Pago', child: Text('Pago')),
                      ],
                      onChanged: (v) => setStateDialog(() => tipoMovimiento = v ?? 'Gasto'),
                    ),
                    DropdownButtonFormField<int>(
                      value: cuentaId,
                      decoration: InputDecoration(
                        labelText: tipoMovimiento == 'Transferencia' ? 'Cuenta origen' : 'Cuenta',
                      ),
                      items: _cuentas.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                      onChanged: (v) => setStateDialog(() => cuentaId = v ?? cuentaId),
                    ),
                    if (tipoMovimiento != 'Transferencia' && tipoMovimiento != 'Pago')
                      DropdownButtonFormField<int>(
                        value: categoriaId,
                        decoration: const InputDecoration(labelText: 'Categoría'),
                        items: _categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                        onChanged: (v) => setStateDialog(() => categoriaId = v ?? categoriaId),
                        validator: (value) {
                          if (tipoMovimiento != 'Transferencia' && tipoMovimiento != 'Pago' && (value == null)) {
                            return 'Seleccione una categoría';
                          }
                          return null;
                        },
                      ),
                    if (tipoMovimiento == 'Transferencia' || tipoMovimiento == 'Pago')
                      DropdownButtonFormField<int>(
                        value: cuentaDestinoId,
                        decoration: InputDecoration(
                          labelText: 'Cuenta destino',
                          errorText: cuentaDestinoError,
                        ),
                        items: (tipoMovimiento == 'Pago'
                                ? _cuentas.where((c) => c.tipoCuenta.toLowerCase().contains('tarjeta'))
                                : _cuentas.where((c) => c.id != cuentaId))
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                            .toList(),
                        onChanged: (v) => setStateDialog(() => cuentaDestinoId = v),
                        validator: (value) {
                          if (tipoMovimiento == 'Transferencia') {
                            if (value == null) {
                              return 'Seleccione la cuenta destino';
                            }
                            if (value == cuentaId) {
                              return 'La cuenta destino debe ser diferente a la origen';
                            }
                          }
                          if (tipoMovimiento == 'Pago') {
                            if (value == null) {
                              return 'Seleccione la tarjeta de crédito a pagar';
                            }
                          }
                          return null;
                        },
                      ),
                    ListTile(
                      title: Text('Fecha: \\${fecha != null ? fecha!.toLocal().toString().split(' ')[0] : 'Seleccionar'}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fecha ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setStateDialog(() => fecha = picked);
                      },
                    ),
                    TextFormField(
                      controller: observacionCtrl,
                      decoration: const InputDecoration(labelText: 'Observación'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true) {
                    setStateDialog(() {});
                    return;
                  }
                  final nuevo = Movimiento(
                    id: movimiento?.id,
                    descripcion: descripcionCtrl.text,
                    monto: double.tryParse(montoCtrl.text) ?? 0,
                    fecha: fecha ?? DateTime.now(),
                    cuentaId: cuentaId,
                    categoriaId: categoriaId,
                    tipoMovimiento: tipoMovimiento,
                    observacion: observacionCtrl.text,
                    cuentaDestinoId: cuentaDestinoId,
                  );
                  if (movimiento == null) {
                    await _service.addMovimiento(nuevo);
                  } else {
                    await _service.updateMovimiento(nuevo);
                  }
                  if (mounted) Navigator.pop(context);
                  _loadAll();
                },
                child: Text(movimiento == null ? 'Agregar' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteMovimiento(int id) async {
    await _service.deleteMovimiento(id);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      drawer: SupabaseDrawer(),
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
                      DataColumn(label: Text('Tipo')),
                      DataColumn(label: Text('Cuenta')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Cuenta destino')),
                      DataColumn(label: Text('Saldo Origen Antes')),
                      DataColumn(label: Text('Saldo Origen Después')),
                      DataColumn(label: Text('Saldo Destino Antes')),
                      DataColumn(label: Text('Saldo Destino Después')),
                      DataColumn(label: Text('Observación')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: _movimientos.map((m) => DataRow(cells: [
                      DataCell(Text(m.descripcion)),
                      DataCell(Text(m.monto.toString())),
                      DataCell(Text(m.tipoMovimiento)),
                      DataCell(Text(_cuentas.firstWhere((c) => c.id == m.cuentaId, orElse: () => Cuenta(id: 0, nombre: '-', tipoCuenta: '-', moneda: '-', saldoInicial: 0, saldoActual: 0, tasaRendimiento: 0, llave: '-', numeroCuenta: '-')).nombre)),
                      DataCell(Text(_categorias.firstWhere((c) => c.id == m.categoriaId, orElse: () => Categoria(id: 0, nombre: '-', tipoCategoria: '-', tipoPresupuesto: '-')).nombre)),
                      DataCell(Text(m.fecha.toLocal().toString().split(' ')[0])),
                      DataCell(Text(m.cuentaDestinoId != null ? _cuentas.firstWhere((c) => c.id == m.cuentaDestinoId, orElse: () => Cuenta(id: 0, nombre: '-', tipoCuenta: '-', moneda: '-', saldoInicial: 0, saldoActual: 0, tasaRendimiento: 0, llave: '-', numeroCuenta: '-')).nombre : '-')),
                      DataCell(Text(m.saldoOrigenAntes?.toStringAsFixed(2) ?? '-')),
                      DataCell(Text(m.saldoOrigenDespues?.toStringAsFixed(2) ?? '-')),
                      DataCell(Text(m.saldoDestinoAntes?.toStringAsFixed(2) ?? '-')),
                      DataCell(Text(m.saldoDestinoDespues?.toStringAsFixed(2) ?? '-')),
                      DataCell(Text(m.observacion ?? '')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditMovimiento(movimiento: m),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteMovimiento(m.id!),
                          ),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditMovimiento(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
