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
    // 1. Insertar el movimiento
    final inserted = await _client.from(_table).insert(movimiento.toMap()).select().single();
    final nuevo = Movimiento.fromMap(inserted);

    // 2. Actualizar saldos según el tipo de movimiento
    final cuentaService = CuentaServiceSupabase();
    // Obtener cuenta origen
    final cuentas = await cuentaService.getCuentas();
    final cuentaOrigen = cuentas.firstWhere((c) => c.id == nuevo.cuentaId);
    Cuenta? cuentaDestino;
    if (nuevo.cuentaDestinoId != null) {
      cuentaDestino = cuentas.firstWhere((c) => c.id == nuevo.cuentaDestinoId, orElse: () => cuentaOrigen);
    }

    double saldoOrigen = cuentaOrigen.saldoActual;
    double saldoDestino = cuentaDestino?.saldoActual ?? 0;

    switch (nuevo.tipoMovimiento.toLowerCase()) {
      case 'ingreso':
        saldoOrigen += nuevo.monto;
        break;
      case 'gasto':
        saldoOrigen -= nuevo.monto;
        break;
      case 'transferencia':
        saldoOrigen -= nuevo.monto;
        if (cuentaDestino != null && cuentaDestino.id != cuentaOrigen.id) {
          saldoDestino += nuevo.monto;
        }
        break;
      case 'pago':
        saldoOrigen -= nuevo.monto;
        if (cuentaDestino != null && cuentaDestino.id != cuentaOrigen.id) {
          saldoDestino += nuevo.monto;
        }
        break;
    }

    // Actualizar cuenta origen
    await _client.from('cuentas').update({'saldo_actual': saldoOrigen}).eq('id', cuentaOrigen.id ?? 0);
    // Actualizar cuenta destino si corresponde
    if (cuentaDestino != null && cuentaDestino.id != cuentaOrigen.id) {
      await _client.from('cuentas').update({'saldo_actual': saldoDestino}).eq('id', cuentaDestino.id ?? 0);
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
