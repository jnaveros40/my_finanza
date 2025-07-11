class Presupuesto {
  final int? id;
  final int periodoMes;
  final int periodoAnio;
  final double montoTotal;
  final double porcentajeNecesidades;
  final double porcentajeDeseos;
  final double porcentajeAhorros;
  final double montoNecesidades;
  final double montoDeseos;
  final double montoAhorros;
  final double actualNecesidades;
  final double actualDeseos;
  final double actualAhorros;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Presupuesto({
    this.id,
    required this.periodoMes,
    required this.periodoAnio,
    required this.montoTotal,
    required this.porcentajeNecesidades,
    required this.porcentajeDeseos,
    required this.porcentajeAhorros,
    required this.montoNecesidades,
    required this.montoDeseos,
    required this.montoAhorros,
    required this.actualNecesidades,
    required this.actualDeseos,
    required this.actualAhorros,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Presupuesto.fromMap(Map<String, dynamic> map) {
    return Presupuesto(
      id: map['id'] as int?,
      periodoMes: map['periodo_mes'] as int,
      periodoAnio: map['periodo_anio'] as int,
      montoTotal: (map['monto_total'] as num).toDouble(),
      porcentajeNecesidades: (map['porcentaje_necesidades'] as num).toDouble(),
      porcentajeDeseos: (map['porcentaje_deseos'] as num).toDouble(),
      porcentajeAhorros: (map['porcentaje_ahorros'] as num).toDouble(),
      montoNecesidades: (map['monto_necesidades'] as num).toDouble(),
      montoDeseos: (map['monto_deseos'] as num).toDouble(),
      montoAhorros: (map['monto_ahorros'] as num).toDouble(),
      actualNecesidades: (map['actual_necesidades'] as num).toDouble(),
      actualDeseos: (map['actual_deseos'] as num).toDouble(),
      actualAhorros: (map['actual_ahorros'] as num).toDouble(),
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
      fechaActualizacion: DateTime.parse(map['fecha_actualizacion']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'periodo_mes': periodoMes,
      'periodo_anio': periodoAnio,
      'monto_total': montoTotal,
      'porcentaje_necesidades': porcentajeNecesidades,
      'porcentaje_deseos': porcentajeDeseos,
      'porcentaje_ahorros': porcentajeAhorros,
      'monto_necesidades': montoNecesidades,
      'monto_deseos': montoDeseos,
      'monto_ahorros': montoAhorros,
      'actual_necesidades': actualNecesidades,
      'actual_deseos': actualDeseos,
      'actual_ahorros': actualAhorros,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
