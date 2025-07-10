import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../supabase/categoria_service_supabase.dart';
import '../../Service/drawer.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({Key? key}) : super(key: key);

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final CategoriaServiceSupabase _service = CategoriaServiceSupabase();
  List<Categoria> _categorias = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    setState(() { _loading = true; _error = null; });
    try {
      final categorias = await _service.getCategorias();
      setState(() { _categorias = categorias; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _openEditCategoria({Categoria? categoria}) async {
    final nombreCtrl = TextEditingController(text: categoria?.nombre ?? '');
    String tipoCategoria = categoria?.tipoCategoria ?? 'Gasto';
    String tipoPresupuesto = categoria?.tipoPresupuesto ?? 'Necesidades';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(categoria == null ? 'Agregar categoría' : 'Editar categoría'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              DropdownButtonFormField<String>(
                value: tipoCategoria,
                decoration: const InputDecoration(labelText: 'Tipo de categoría'),
                items: const [
                  DropdownMenuItem(value: 'Gasto', child: Text('Gasto')),
                  DropdownMenuItem(value: 'Ingreso', child: Text('Ingreso')),
                ],
                onChanged: (v) => tipoCategoria = v ?? 'Gasto',
              ),
              DropdownButtonFormField<String>(
                value: tipoPresupuesto,
                decoration: const InputDecoration(labelText: 'Tipo de presupuesto'),
                items: const [
                  DropdownMenuItem(value: 'Necesidades', child: Text('Necesidades')),
                  DropdownMenuItem(value: 'Deseos', child: Text('Deseos')),
                  DropdownMenuItem(value: 'Ahorros', child: Text('Ahorros')),
                ],
                onChanged: (v) => tipoPresupuesto = v ?? 'Necesidades',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nueva = Categoria(
                id: categoria?.id,
                nombre: nombreCtrl.text,
                tipoCategoria: tipoCategoria,
                tipoPresupuesto: tipoPresupuesto,
              );
              if (categoria == null) {
                await _service.addCategoria(nueva);
              } else {
                await _service.updateCategoria(nueva);
              }
              if (mounted) Navigator.pop(context);
              _loadCategorias();
            },
            child: Text(categoria == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteCategoria(int id) async {
    await _service.deleteCategoria(id);
    _loadCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      drawer: SupabaseDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Tipo de categoría')),
                      DataColumn(label: Text('Tipo de presupuesto')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: _categorias.map((c) => DataRow(cells: [
                      DataCell(Text(c.nombre)),
                      DataCell(Text(c.tipoCategoria)),
                      DataCell(Text(c.tipoPresupuesto)),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditCategoria(categoria: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCategoria(c.id!),
                          ),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditCategoria(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
