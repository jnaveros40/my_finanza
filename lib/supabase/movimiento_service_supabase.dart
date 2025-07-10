import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento.dart';
import '../models/cuenta.dart';
import 'cuenta_service_supabase.dart';

class MovimientoServiceSupabase {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'movimientos';

  Future<List<Movimiento>> getMovimientos() async {
    final data = await _client.from(_table).select().order('fecha', ascending: false);
    return (data as List).map((e) => Movimiento.fromMap(e)).toList();
  }

  Future<Movimiento> addMovimiento(Movimiento movimiento) async {
    // 1. Obtener cuentas y saldos antes
    final cuentaService = CuentaServiceSupabase();
    final cuentas = await cuentaService.getCuentas();
    final cuentaOrigen = cuentas.firstWhere((c) => c.id == movimiento.cuentaId);
    Cuenta? cuentaDestino;
    if (movimiento.cuentaDestinoId != null) {
      cuentaDestino = cuentas.firstWhere((c) => c.id == movimiento.cuentaDestinoId, orElse: () => cuentaOrigen);
    }

    double saldoOrigenAntes = cuentaOrigen.saldoActual;
    double saldoDestinoAntes = cuentaDestino?.saldoActual ?? 0;
    double saldoOrigenDespues = saldoOrigenAntes;
    double saldoDestinoDespues = saldoDestinoAntes;

    switch (movimiento.tipoMovimiento.toLowerCase()) {
      case 'ingreso':
        saldoOrigenDespues += movimiento.monto;
        break;
      case 'gasto':
        saldoOrigenDespues -= movimiento.monto;
        break;
      case 'transferencia':
        saldoOrigenDespues -= movimiento.monto;
        if (cuentaDestino != null && cuentaDestino.id != cuentaOrigen.id) {
          saldoDestinoDespues += movimiento.monto;
        }
        break;
      case 'pago':
        saldoOrigenDespues -= movimiento.monto;
        if (cuentaDestino != null && cuentaDestino.id != cuentaOrigen.id) {
          saldoDestinoDespues += movimiento.monto;
        }
        break;
    }

    // 2. Insertar el movimiento con los saldos antes y después
    final movimientoConSaldos = Movimiento(
      id: movimiento.id,
      descripcion: movimiento.descripcion,
      monto: movimiento.monto,
      fecha: movimiento.fecha,
      cuentaId: movimiento.cuentaId,
      categoriaId: movimiento.categoriaId,
      tipoMovimiento: movimiento.tipoMovimiento,
      observacion: movimiento.observacion,
      cuentaDestinoId: movimiento.cuentaDestinoId,
      saldoOrigenAntes: saldoOrigenAntes,
      saldoOrigenDespues: saldoOrigenDespues,
      saldoDestinoAntes: movimiento.cuentaDestinoId != null ? saldoDestinoAntes : null,
      saldoDestinoDespues: movimiento.cuentaDestinoId != null ? saldoDestinoDespues : null,
    );
    final inserted = await _client.from(_table).insert(movimientoConSaldos.toMap()).select().single();
    final nuevo = Movimiento.fromMap(inserted);

    // 3. Actualizar cuenta origen
    await _client.from('cuentas').update({'saldo_actual': saldoOrigenDespues}).eq('id', cuentaOrigen.id ?? 0);
    // 4. Actualizar cuenta destino si corresponde
    if (cuentaDestino != null && cuentaDestino.id != cuentaOrigen.id) {
      await _client.from('cuentas').update({'saldo_actual': saldoDestinoDespues}).eq('id', cuentaDestino.id ?? 0);
    }

    return nuevo;
  }

  Future<void> updateMovimiento(Movimiento movimiento) async {
    await _client.from(_table).update(movimiento.toMap()).eq('id', movimiento.id ?? 0);
  }

  Future<void> deleteMovimiento(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
