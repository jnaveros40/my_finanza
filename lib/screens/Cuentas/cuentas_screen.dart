import 'package:flutter/material.dart';
import '../../models/cuenta.dart';
import '../../supabase/cuenta_service_supabase.dart';
import 'cuentas_crear_editar.dart';
import '../../Service/drawer.dart';

class CuentasScreen extends StatefulWidget {
  const CuentasScreen({Key? key}) : super(key: key);

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  final CuentaServiceSupabase _service = CuentaServiceSupabase();
  List<Cuenta> _cuentas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCuentas();
  }

  Future<void> _loadCuentas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cuentas = await _service.getCuentas();
      setState(() { _cuentas = cuentas; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _openEditCuenta({Cuenta? cuenta}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CuentasCrearEditarScreen(
          cuenta: cuenta,
          onSave: (cuentaEditada) async {
            if (cuenta == null) {
              await _service.addCuenta(cuentaEditada);
            } else {
              await _service.updateCuenta(cuentaEditada);
            }
            _loadCuentas();
          },
        ),
      ),
    );
  }

  void _openCreateCuenta() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CuentasCrearEditarScreen(
          cuenta: null,
          onSave: (cuentaEditada) async {
            await _service.addCuenta(cuentaEditada);
            _loadCuentas();
          },
        ),
      ),
    );
  }

  void _deleteCuenta(int id) async {
    await _service.deleteCuenta(id);
    _loadCuentas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      drawer: SupabaseDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: [31m$_error[0m'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Tipo')),
                      DataColumn(label: Text('Moneda')),
                      DataColumn(label: Text('Saldo')),
                      DataColumn(label: Text('Tasa')),
                      DataColumn(label: Text('Llave')),
                      DataColumn(label: Text('N° Cuenta')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: _cuentas.map((c) => DataRow(cells: [
                      DataCell(Text(c.nombre)),
                      DataCell(Text(c.tipoCuenta)),
                      DataCell(Text(c.moneda)),
                      DataCell(Text(c.saldoInicial.toString())),
                      DataCell(Text(c.tasaRendimiento.toString())),
                      DataCell(Text(c.llave)),
                      DataCell(Text(c.numeroCuenta)),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditCuenta(cuenta: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCuenta(c.id!),
                          ),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateCuenta,
        child: const Icon(Icons.add),
      ),
    );
  }
}
