class Cuenta {
  final int? id;
  final String nombre;
  final String tipoCuenta; // Ej: Ahorro, Corriente, Inversión
  final String moneda; // Ej: MXN, USD, EUR
  final double saldoInicial;
  final double saldoActual;
  final double tasaRendimiento;
  final String llave;
  final String numeroCuenta;
  final double? cupo;
  final double? cupoActual;
  final int? fechaCorte;
  final int? fechaPago;

  Cuenta({
    this.id,
    required this.nombre,
    required this.tipoCuenta,
    required this.moneda,
    required this.saldoInicial,
    required this.saldoActual,
    required this.tasaRendimiento,
    required this.llave,
    required this.numeroCuenta,
    this.cupo,
    this.cupoActual,
    this.fechaCorte,
    this.fechaPago,
  });

  factory Cuenta.fromMap(Map<String, dynamic> map) {
    return Cuenta(
      id: map['id'] as int?,
      nombre: map['nombre'] ?? '',
      tipoCuenta: map['tipo_cuenta'] ?? '',
      moneda: map['moneda'] ?? '',
      saldoInicial: (map['saldo_inicial'] as num?)?.toDouble() ?? 0.0,
      saldoActual: (map['saldo_actual'] as num?)?.toDouble() ?? 0.0,
      tasaRendimiento: (map['tasa_rendimiento'] as num?)?.toDouble() ?? 0.0,
      llave: map['llave'] ?? '',
      numeroCuenta: map['numero_cuenta'] ?? '',
      cupo: (map['cupo'] as num?)?.toDouble(),
      cupoActual: (map['cupo_actual'] as num?)?.toDouble(),
      fechaCorte: map['fecha_corte'] as int?,
      fechaPago: map['fecha_pago'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'tipo_cuenta': tipoCuenta,
      'moneda': moneda,
      'saldo_inicial': saldoInicial,
      'saldo_actual': saldoActual,
      'tasa_rendimiento': tasaRendimiento,
      'llave': llave,
      'numero_cuenta': numeroCuenta,
      'cupo': cupo,
      'cupo_actual': cupoActual,
      'fecha_corte': fechaCorte,
      'fecha_pago': fechaPago,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
