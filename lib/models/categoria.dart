class Categoria {
  final int? id;
  final String nombre;
  final String tipoCategoria;
  final String tipoPresupuesto;

  Categoria({
    this.id,
    required this.nombre,
    required this.tipoCategoria,
    required this.tipoPresupuesto,
  });

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nombre: map['nombre'] ?? '',
      tipoCategoria: map['tipo_categoria'] ?? '',
      tipoPresupuesto: map['tipo_presupuesto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'tipo_categoria': tipoCategoria,
      'tipo_presupuesto': tipoPresupuesto,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
