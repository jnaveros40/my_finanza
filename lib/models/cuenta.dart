class Cuenta {
  final int? id;
  final String nombre;
  final String tipoCuenta; // Ej: Ahorro, Corriente, Inversión
  final String moneda; // Ej: MXN, USD, EUR
  final double saldoInicial;
  final double tasaRendimiento;
  final String llave;
  final String numeroCuenta;

  Cuenta({
    this.id,
    required this.nombre,
    required this.tipoCuenta,
    required this.moneda,
    required this.saldoInicial,
    required this.tasaRendimiento,
    required this.llave,
    required this.numeroCuenta,
  });

  factory Cuenta.fromMap(Map<String, dynamic> map) {
    return Cuenta(
      id: map['id'] as int?,
      nombre: map['nombre'] ?? '',
      tipoCuenta: map['tipo_cuenta'] ?? '',
      moneda: map['moneda'] ?? '',
      saldoInicial: (map['saldo_inicial'] as num?)?.toDouble() ?? 0.0,
      tasaRendimiento: (map['tasa_rendimiento'] as num?)?.toDouble() ?? 0.0,
      llave: map['llave'] ?? '',
      numeroCuenta: map['numero_cuenta'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo_cuenta': tipoCuenta,
      'moneda': moneda,
      'saldo_inicial': saldoInicial,
      'tasa_rendimiento': tasaRendimiento,
      'llave': llave,
      'numero_cuenta': numeroCuenta,
    };
  }
}
