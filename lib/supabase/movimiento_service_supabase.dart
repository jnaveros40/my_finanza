import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento.dart';
import '../models/cuenta.dart';
import 'cuenta_service_supabase.dart';

class MovimientoServiceSupabase {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'f_movimientos';

  Future<List<Movimiento>> getMovimientos() async {
    final data = await _client.from(_table).select().order('fecha', ascending: false);
    return (data as List).map((e) => Movimiento.fromMap(e)).toList();
  }

  Future<Movimiento> addMovimiento(Movimiento movimiento) async {
    double? cupoActualAntes;
    double? cupoActualDespues;
    print('--- INICIO addMovimiento ---');
    print('Datos recibidos:');
    print(movimiento.toMap());
    // 1. Obtener cuentas y saldos antes
    final cuentaService = CuentaServiceSupabase();
    final cuentas = await cuentaService.getCuentas();
    final cuentaOrigen = cuentas.firstWhere((c) => c.id == movimiento.cuentaId);
    Cuenta? cuentaDestino;
    if (movimiento.cuentaDestinoId != null) {
      cuentaDestino = cuentas.firstWhere((c) => c.id == movimiento.cuentaDestinoId, orElse: () => cuentaOrigen);
      // Auditoría de cupo para pagos de tarjeta de crédito
      if (movimiento.tipoMovimiento.toLowerCase() == 'pago' && cuentaDestino.cupoActual != null) {
        cupoActualAntes = cuentaDestino.cupoActual;
        cupoActualDespues = cupoActualAntes! + movimiento.monto;
        print('Auditoría cupo tarjeta: antes=$cupoActualAntes, después=$cupoActualDespues');
        // Actualizar el cupo_actual en la cuenta destino (tarjeta)
        await _client.from('f_cuentas').update({'cupo_actual': cupoActualDespues}).eq('id', cuentaDestino.id ?? 0);
      }
    }

    double saldoOrigenAntes = cuentaOrigen.saldoActual;
    double saldoDestinoAntes = cuentaDestino?.saldoActual ?? 0;
    double saldoOrigenDespues = saldoOrigenAntes;
    double saldoDestinoDespues = saldoDestinoAntes;

    // 2. Auditoría y actualización de presupuesto
    int? presupuestoId;
    double? presupuestoActual;
    double? presupuestoNuevo;
    if (movimiento.categoriaId != null) {
      print('Buscando presupuesto vigente...');
      // Buscar presupuesto vigente
      final now = DateTime.now();
      final presupuestos = await Supabase.instance.client
        .from('f_presupuestos')
        .select()
        .eq('periodo_mes', now.month)
        .eq('periodo_anio', now.year);
      print('Presupuestos encontrados:');
      print(presupuestos);
      if (presupuestos.isNotEmpty) {
        final presupuesto = presupuestos.first;
        presupuestoId = presupuesto['id'] as int?;
        // Determinar tipo de presupuesto desde la categoría
      print('Buscando categoría...');
      final categoria = await Supabase.instance.client
        .from('f_categorias')
        .select()
        .eq('id', movimiento.categoriaId!)
        .single();
        print('Categoría encontrada:');
        print(categoria);
        final tipoPresupuesto = categoria['tipo_presupuesto'];
        String campoActual = '';
        if (tipoPresupuesto == 'necesidades') campoActual = 'actual_necesidades';
        else if (tipoPresupuesto == 'deseos') campoActual = 'actual_deseos';
        else if (tipoPresupuesto == 'ahorros') campoActual = 'actual_ahorros';
        if (campoActual.isNotEmpty) {
          presupuestoActual = (presupuesto[campoActual] as num?)?.toDouble() ?? 0.0;
          // Actualizar el valor según el tipo de movimiento
          if (movimiento.tipoMovimiento.toLowerCase() == 'gasto') {
            presupuestoNuevo = presupuestoActual + movimiento.monto;
          } else if (movimiento.tipoMovimiento.toLowerCase() == 'ingreso') {
            presupuestoNuevo = presupuestoActual - movimiento.monto;
          } else {
            presupuestoNuevo = presupuestoActual;
          }
          print('Auditoría presupuesto:');
          print('presupuestoId: $presupuestoId');
          print('campoActual: $campoActual');
          print('presupuestoActual: $presupuestoActual');
          print('presupuestoNuevo: $presupuestoNuevo');
          // Actualizar presupuesto en la base de datos
          await Supabase.instance.client
            .from('f_presupuestos')
            .update({campoActual: presupuestoNuevo, 'fecha_actualizacion': DateTime.now().toIso8601String()})
            .eq('id', presupuestoId!);
        }
        else {
          print('No se encontró campoActual para tipoPresupuesto: $tipoPresupuesto');
        }
      }
      else {
        print('No se encontró presupuesto vigente para el mes/año actual');
      }
    }

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

    // 3. Insertar el movimiento con los saldos y auditoría de presupuesto
    print('Insertando movimiento en Supabase...');
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
      presupuestoId: presupuestoId,
      presupuestoActual: presupuestoActual,
      presupuestoNuevo: presupuestoNuevo,
      saldoOrigenAntes: saldoOrigenAntes,
      saldoOrigenDespues: saldoOrigenDespues,
      saldoDestinoAntes: movimiento.cuentaDestinoId != null ? saldoDestinoAntes : null,
      saldoDestinoDespues: movimiento.cuentaDestinoId != null ? saldoDestinoDespues : null,
      cupoActualAntes: cupoActualAntes,
      cupoActualDespues: cupoActualDespues,
    );
    print(movimientoConSaldos.toMap());
    final inserted = await _client.from(_table).insert(movimientoConSaldos.toMap()).select().single();
    print('Respuesta insert Supabase:');
    print(inserted);
    final nuevo = Movimiento.fromMap(inserted);

    // 4. Actualizar cuenta origen
    print('Actualizando cuenta origen...');
    await _client.from('f_cuentas').update({'saldo_actual': saldoOrigenDespues}).eq('id', cuentaOrigen.id ?? 0);
    // 5. Actualizar cuenta destino si corresponde
    if (cuentaDestino != null && cuentaDestino.id != cuentaOrigen.id) {
      print('Actualizando cuenta destino...');
      await _client.from('f_cuentas').update({'saldo_actual': saldoDestinoDespues}).eq('id', cuentaDestino.id ?? 0);
    }

    print('--- FIN addMovimiento ---');
    return nuevo;
  }

  Future<void> updateMovimiento(Movimiento movimiento) async {
    await _client.from(_table).update(movimiento.toMap()).eq('id', movimiento.id ?? 0);
  }

  Future<void> deleteMovimiento(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
