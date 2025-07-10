class Movimiento {
  final int? id;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final int cuentaId;
  final int? categoriaId;
  final String tipoMovimiento;
  final String? observacion;
  final int? cuentaDestinoId;
  final double? saldoOrigenAntes;
  final double? saldoOrigenDespues;
  final double? saldoDestinoAntes;
  final double? saldoDestinoDespues;

  Movimiento({
    this.id,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.cuentaId,
    this.categoriaId,
    required this.tipoMovimiento,
    this.observacion,
    this.cuentaDestinoId,
    this.saldoOrigenAntes,
    this.saldoOrigenDespues,
    this.saldoDestinoAntes,
    this.saldoDestinoDespues,
  });

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'] as int?,
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      fecha: DateTime.parse(map['fecha']),
      cuentaId: map['cuenta_id'] ?? 0,
      categoriaId: map['categoria_id'],
      tipoMovimiento: map['tipo_movimiento'] ?? '',
      observacion: map['observacion'],
      cuentaDestinoId: map['cuenta_destino_id'],
      saldoOrigenAntes: (map['saldo_origen_antes'] as num?)?.toDouble(),
      saldoOrigenDespues: (map['saldo_origen_despues'] as num?)?.toDouble(),
      saldoDestinoAntes: (map['saldo_destino_antes'] as num?)?.toDouble(),
      saldoDestinoDespues: (map['saldo_destino_despues'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'cuenta_id': cuentaId,
      'tipo_movimiento': tipoMovimiento,
      'observacion': observacion,
      'cuenta_destino_id': cuentaDestinoId,
      'saldo_origen_antes': saldoOrigenAntes,
      'saldo_origen_despues': saldoOrigenDespues,
      'saldo_destino_antes': saldoDestinoAntes,
      'saldo_destino_despues': saldoDestinoDespues,
    };
    if (categoriaId != null) {
      map['categoria_id'] = categoriaId;
    }
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
