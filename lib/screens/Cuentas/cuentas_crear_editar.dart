import 'package:flutter/material.dart';
import '../../models/cuenta.dart';

class CuentasCrearEditarScreen extends StatefulWidget {
  final Cuenta? cuenta;
  final void Function(Cuenta cuenta) onSave;
  const CuentasCrearEditarScreen({Key? key, this.cuenta, required this.onSave}) : super(key: key);

  @override
  State<CuentasCrearEditarScreen> createState() => _CuentasCrearEditarScreenState();
}
class _CuentasCrearEditarScreenState extends State<CuentasCrearEditarScreen> {
  late TextEditingController nombreCtrl;
  late TextEditingController saldoCtrl;
  late TextEditingController tasaCtrl;
  late TextEditingController llaveCtrl;
  late TextEditingController numeroCtrl;
  late TextEditingController cupoCtrl;
  late TextEditingController fechaCorteCtrl;
  late TextEditingController fechaPagoCtrl;
  String tipoCuenta = 'Cuenta de ahorro';
  String moneda = 'COP';
  final List<String> tiposCuenta = [
    'Cuenta de ahorro',
    'Tarjeta crédito',
    'Efectivo',
  ];
  final List<String> monedas = [
    'COP',
    'USD',
    'EUR',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.cuenta;
    nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    tipoCuenta = c?.tipoCuenta ?? 'Cuenta de ahorro';
    moneda = c?.moneda ?? 'COP';
    saldoCtrl = TextEditingController(text: c?.saldoInicial.toString() ?? '');
    tasaCtrl = TextEditingController(text: c?.tasaRendimiento.toString() ?? '');
    llaveCtrl = TextEditingController(text: c?.llave ?? '');
    numeroCtrl = TextEditingController(text: c?.numeroCuenta ?? '');
    cupoCtrl = TextEditingController(text: c?.cupo?.toString() ?? '');
    fechaCorteCtrl = TextEditingController(text: c?.fechaCorte?.toString() ?? '');
    fechaPagoCtrl = TextEditingController(text: c?.fechaPago?.toString() ?? '');
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    saldoCtrl.dispose();
    tasaCtrl.dispose();
    llaveCtrl.dispose();
    numeroCtrl.dispose();
    cupoCtrl.dispose();
    fechaCorteCtrl.dispose();
    fechaPagoCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final saldoInicialValue = double.tryParse(saldoCtrl.text) ?? 0;
    double saldoActualValue;
    if (widget.cuenta == null) {
      saldoActualValue = saldoInicialValue;
    } else {
      saldoActualValue = widget.cuenta!.saldoActual;
    }
    final cuenta = Cuenta(
      id: widget.cuenta?.id,
      nombre: nombreCtrl.text,
      tipoCuenta: tipoCuenta,
      moneda: moneda,
      saldoInicial: saldoInicialValue,
      saldoActual: saldoActualValue,
      tasaRendimiento: double.tryParse(tasaCtrl.text) ?? 0,
      llave: llaveCtrl.text,
      numeroCuenta: numeroCtrl.text,
      cupo: tipoCuenta == 'Tarjeta crédito' ? double.tryParse(cupoCtrl.text) ?? 0 : null,
      fechaCorte: tipoCuenta == 'Tarjeta crédito' ? int.tryParse(fechaCorteCtrl.text) : null,
      fechaPago: tipoCuenta == 'Tarjeta crédito' ? int.tryParse(fechaPagoCtrl.text) : null,
    );
    widget.onSave(cuenta);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cuenta == null ? 'Agregar cuenta' : 'Editar cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            DropdownButtonFormField<String>(
              value: tipoCuenta,
              decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
              items: tiposCuenta.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
              onChanged: (v) => setState(() => tipoCuenta = v ?? 'Cuenta de ahorro'),
            ),
            DropdownButtonFormField<String>(
              value: moneda,
              decoration: const InputDecoration(labelText: 'Moneda'),
              items: monedas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => moneda = v ?? 'COP'),
            ),
            TextField(controller: saldoCtrl, decoration: const InputDecoration(labelText: 'Saldo inicial'), keyboardType: TextInputType.number),
            TextField(controller: tasaCtrl, decoration: const InputDecoration(labelText: 'Tasa de rendimiento'), keyboardType: TextInputType.number),
            TextField(controller: llaveCtrl, decoration: const InputDecoration(labelText: 'Llave')),
            TextField(controller: numeroCtrl, decoration: const InputDecoration(labelText: 'Número de cuenta')),
            if (tipoCuenta == 'Tarjeta crédito') ...[
              const SizedBox(height: 16),
              Text('Datos de tarjeta de crédito', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: cupoCtrl, decoration: const InputDecoration(labelText: 'Cupo'), keyboardType: TextInputType.number),
              TextField(controller: fechaCorteCtrl, decoration: const InputDecoration(labelText: 'Día de corte (1-30)'), keyboardType: TextInputType.number),
              TextField(controller: fechaPagoCtrl, decoration: const InputDecoration(labelText: 'Día de pago (1-30)'), keyboardType: TextInputType.number),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.cuenta == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
