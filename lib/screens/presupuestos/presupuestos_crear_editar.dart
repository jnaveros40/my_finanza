import 'package:flutter/material.dart';
import '../../models/presupuesto.dart';
//import '../../supabase/user_service_supabase.dart';

class PresupuestosCrearEditarScreen extends StatefulWidget {
  final Presupuesto? presupuesto;
  final void Function(Presupuesto presupuesto) onSave;
  const PresupuestosCrearEditarScreen({Key? key, this.presupuesto, required this.onSave}) : super(key: key);

  @override
  State<PresupuestosCrearEditarScreen> createState() => _PresupuestosCrearEditarScreenState();
}

class _PresupuestosCrearEditarScreenState extends State<PresupuestosCrearEditarScreen> {
  double get montoTotal => double.tryParse(montoCtrl.text) ?? 0;
  double get necesidades => double.tryParse(necesidadesCtrl.text) ?? 0;
  double get deseos => double.tryParse(deseosCtrl.text) ?? 0;
  double get ahorros => double.tryParse(ahorrosCtrl.text) ?? 0;
  double get montoNecesidades => montoTotal * necesidades / 100;
  double get montoDeseos => montoTotal * deseos / 100;
  double get montoAhorros => montoTotal * ahorros / 100;
  late TextEditingController montoCtrl;
  late TextEditingController necesidadesCtrl;
  late TextEditingController deseosCtrl;
  late TextEditingController ahorrosCtrl;
  int periodoMes = DateTime.now().month;
  int periodoAnio = DateTime.now().year;
  String errorPorcentaje = '';

  @override
  void initState() {
    super.initState();
    final p = widget.presupuesto;
    montoCtrl = TextEditingController(text: p?.montoTotal.toString() ?? '');
    necesidadesCtrl = TextEditingController(text: p?.porcentajeNecesidades.toString() ?? '50');
    deseosCtrl = TextEditingController(text: p?.porcentajeDeseos.toString() ?? '30');
    ahorrosCtrl = TextEditingController(text: p?.porcentajeAhorros.toString() ?? '20');
    periodoMes = p?.periodoMes ?? DateTime.now().month;
    periodoAnio = p?.periodoAnio ?? DateTime.now().year;
  }

  @override
  void dispose() {
    montoCtrl.dispose();
    necesidadesCtrl.dispose();
    deseosCtrl.dispose();
    ahorrosCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final montoTotal = double.tryParse(montoCtrl.text) ?? 0;
    final necesidades = double.tryParse(necesidadesCtrl.text) ?? 0;
    final deseos = double.tryParse(deseosCtrl.text) ?? 0;
    final ahorros = double.tryParse(ahorrosCtrl.text) ?? 0;
    final suma = necesidades + deseos + ahorros;
    if (suma != 100) {
      setState(() { errorPorcentaje = 'La suma debe ser 100%'; });
      return;
    }
    final montoNecesidades = montoTotal * necesidades / 100;
    final montoDeseos = montoTotal * deseos / 100;
    final montoAhorros = montoTotal * ahorros / 100;
    final presupuesto = Presupuesto(
      id: widget.presupuesto?.id,
      periodoMes: periodoMes,
      periodoAnio: periodoAnio,
      montoTotal: montoTotal,
      porcentajeNecesidades: necesidades,
      porcentajeDeseos: deseos,
      porcentajeAhorros: ahorros,
      montoNecesidades: montoNecesidades,
      montoDeseos: montoDeseos,
      montoAhorros: montoAhorros,
      actualNecesidades: widget.presupuesto?.actualNecesidades ?? 0,
      actualDeseos: widget.presupuesto?.actualDeseos ?? 0,
      actualAhorros: widget.presupuesto?.actualAhorros ?? 0,
      fechaCreacion: widget.presupuesto?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    widget.onSave(presupuesto);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.presupuesto == null ? 'Crear presupuesto' : 'Editar presupuesto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: periodoMes,
                    decoration: const InputDecoration(labelText: 'Mes'),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                    onChanged: (v) => setState(() => periodoMes = v ?? periodoMes),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: periodoAnio,
                    decoration: const InputDecoration(labelText: 'Año'),
                    items: List.generate(5, (i) => DropdownMenuItem(value: DateTime.now().year - 2 + i, child: Text('${DateTime.now().year - 2 + i}'))),
                    onChanged: (v) => setState(() => periodoAnio = v ?? periodoAnio),
                  ),
                ),
              ],
            ),
            TextField(
              controller: montoCtrl,
              decoration: const InputDecoration(labelText: 'Monto total'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('División 50/30/20 (editable, suma debe ser 100%)', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: necesidadesCtrl,
                        decoration: const InputDecoration(labelText: 'Necesidades (%)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      Text('Valor: ${montoNecesidades.toStringAsFixed(2)}', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: deseosCtrl,
                        decoration: const InputDecoration(labelText: 'Deseos (%)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      Text('Valor: ${montoDeseos.toStringAsFixed(2)}', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: ahorrosCtrl,
                        decoration: const InputDecoration(labelText: 'Ahorros (%)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      Text('Valor: ${montoAhorros.toStringAsFixed(2)}', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
            if (errorPorcentaje.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(errorPorcentaje, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.presupuesto == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
