class GastoRecurrente {
  final int? id;
  final int frecuenciaDias;
  final String descripcion;
  final double monto;
  final int cuentaId;
  final int categoriaId;
  final DateTime fechaInicio;
  final DateTime? fechaFinal;
  final String? observacion;

  GastoRecurrente({
    this.id,
    required this.frecuenciaDias,
    required this.descripcion,
    required this.monto,
    required this.cuentaId,
    required this.categoriaId,
    required this.fechaInicio,
    this.fechaFinal,
    this.observacion,
  });

  factory GastoRecurrente.fromMap(Map<String, dynamic> map) {
    return GastoRecurrente(
      id: map['id'] as int?,
      frecuenciaDias: map['frecuencia_dias'] ?? 0,
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      cuentaId: map['cuenta_id'] ?? 0,
      categoriaId: map['categoria_id'] ?? 0,
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFinal: map['fecha_final'] != null ? DateTime.tryParse(map['fecha_final']) : null,
      observacion: map['observacion'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'frecuencia_dias': frecuenciaDias,
      'descripcion': descripcion,
      'monto': monto,
      'cuenta_id': cuentaId,
      'categoria_id': categoriaId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_final': fechaFinal?.toIso8601String(),
      'observacion': observacion,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
