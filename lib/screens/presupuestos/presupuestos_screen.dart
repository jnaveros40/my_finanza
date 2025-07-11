import 'package:flutter/material.dart';
import '../../models/presupuesto.dart';
import 'presupuestos_crear_editar.dart';
import '../../Service/drawer.dart';
import '../../supabase/presupuesto_service_supabase.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({Key? key}) : super(key: key);

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  final PresupuestoServiceSupabase _service = PresupuestoServiceSupabase();
  List<Presupuesto> _presupuestos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPresupuestos();
  }

  Future<void> _loadPresupuestos() async {
    setState(() { _loading = true; _error = null; });
    try {
      final presupuestos = await _service.getPresupuestos();
      setState(() { _presupuestos = presupuestos; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _openCrearEditar({Presupuesto? presupuesto}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresupuestosCrearEditarScreen(
          presupuesto: presupuesto,
          onSave: (nuevo) async {
            print('Presupuesto a guardar: ${nuevo.toMap()}');
            if (nuevo.id == null) {
              await _service.addPresupuesto(nuevo);
            } else {
              await _service.updatePresupuesto(nuevo);
            }
            print('Guardado terminado');
            _loadPresupuestos();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      drawer: SupabaseDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _presupuestos.isEmpty
                  ? const Center(child: Text('No hay presupuestos'))
                  : ListView.builder(
                      itemCount: _presupuestos.length,
                      itemBuilder: (context, i) {
                        final p = _presupuestos[i];
                        final avanceNecesidades = p.montoNecesidades == 0 ? 0 : (p.actualNecesidades / p.montoNecesidades * 100).clamp(0, 100);
                        final avanceDeseos = p.montoDeseos == 0 ? 0 : (p.actualDeseos / p.montoDeseos * 100).clamp(0, 100);
                        final avanceAhorros = p.montoAhorros == 0 ? 0 : (p.actualAhorros / p.montoAhorros * 100).clamp(0, 100);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text('Presupuesto ${p.periodoMes}/${p.periodoAnio}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total: ${p.montoTotal.toStringAsFixed(2)}'),
                                Text('Necesidades: ${p.montoNecesidades.toStringAsFixed(2)} (${avanceNecesidades.toStringAsFixed(1)}%)'),
                                LinearProgressIndicator(value: avanceNecesidades / 100),
                                Text('Actual: ${p.actualNecesidades.toStringAsFixed(2)}'),
                                Text('Deseos: ${p.montoDeseos.toStringAsFixed(2)} (${avanceDeseos.toStringAsFixed(1)}%)'),
                                LinearProgressIndicator(value: avanceDeseos / 100),
                                Text('Actual: ${p.actualDeseos.toStringAsFixed(2)}'),
                                Text('Ahorros: ${p.montoAhorros.toStringAsFixed(2)} (${avanceAhorros.toStringAsFixed(1)}%)'),
                                LinearProgressIndicator(value: avanceAhorros / 100),
                                Text('Actual: ${p.actualAhorros.toStringAsFixed(2)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openCrearEditar(presupuesto: p),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCrearEditar(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
