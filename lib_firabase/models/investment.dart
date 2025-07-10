// lib/models/investment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Investment {
  final String? id; // ID del documento en Firestore
  final String userId; // ID del usuario propietario
  final String name; // Nombre o descripción de la inversión (ej. "Acciones Apple", "ETF Vanguard")
  final String type; // Tipo de inversión (ej. 'stocks', 'funds', 'crypto', 'real_estate', 'other')
  final double initialAmount; // Monto inicial invertido (en la moneda de la inversión)

  // NUEVO: Cantidad total de activos (ej. número de acciones, unidades de fondo)
  final double totalQuantity;

  final DateTime startDate; // Fecha en que se realizó la inversión

  final String? currency; // Moneda de la inversión (ej. 'USD', 'EUR', 'COP')
  final double? currentAmount; // Valor actual de la inversión (opcional, puede requerir seguimiento manual o API)
  final double? yieldRate; // Tasa de rendimiento (ej. anual, mensual)
  final String? yieldFrequency; // Frecuencia del rendimiento (ej. 'annual', 'monthly', 'quarterly')
  final DateTime? lastYieldDate; // Fecha del último rendimiento recibido

  final String? platform; // Plataforma o bróker donde se gestiona la inversión
  final String? externalId; // ID de referencia en una plataforma externa
  final String? notes; // Comentarios o información adicional

  // Historial de movimientos: Array de mapas.
  // Cada mapa podría tener 'date', 'type' (ej. 'contribution', 'withdrawal', 'dividend'), 'amount', 'quantity', 'exchangeRate', 'notes'
  final List<Map<String, dynamic>>? history;

  // Campos calculados (añadidos aquí para compatibilidad con la estructura anterior, aunque la lógica de cálculo se implementaría en la UI o servicio)
  final double currentQuantity; // Unidades actuales disponibles tras movimientos
  final double totalInvested; // Suma total invertida (para compras y aportes)
  final double estimatedCurrentValue; // Valor actual de mercado si se conoce (actualizable manualmente)
  final double estimatedGainLoss ; // Valor actual - valor invertido total
  final double totalDividends; // Acumulado recibido por dividendos

   // Nuevos campos del modelo restructurado (mantener para compatibilidad)
   final DateTime creationDate;
   final String status;
   final String? isinSymbol;
   final String? originCountry;
   final double? annualProjectedYield;


  Investment({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialAmount,
    required this.totalQuantity, // <-- Incluir totalQuantity
    required this.startDate,
    this.currency,
    this.currentAmount,
    this.yieldRate,
    this.yieldFrequency,
    this.lastYieldDate,
    this.platform,
    this.externalId,
    this.notes,
    this.history, // Puede ser null inicialmente

    // Campos calculados (inicializar con valores por defecto o leer de Firestore si existen)
    this.currentQuantity = 0.0,
    this.totalInvested = 0.0,
    this.estimatedCurrentValue = 0.0,
    this.estimatedGainLoss = 0.0,
    this.totalDividends = 0.0,

    // Nuevos campos del modelo restructurado (inicializar con valores por defecto o leer de Firestore si existen)
    DateTime? creationDate, // Hacer opcional en constructor para no requerirlo siempre
    String? status, // Hacer opcional en constructor
    this.isinSymbol,
    this.originCountry,
    this.annualProjectedYield,

  }) : creationDate = creationDate ?? DateTime.now(), // Asignar valor por defecto si es nulo
       status = status ?? 'active'; // Asignar valor por defecto si es nulo


  // Constructor factory para crear una instancia de Investment desde un documento de Firestore
  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // Procesar history
    final List<dynamic>? historyData = data['history'] as List<dynamic>?;
    final List<Map<String, dynamic>>? history = historyData?.map((item) {
      final Map<String, dynamic> historyMap = Map<String, dynamic>.from(item as Map);
      // Manejar date como Timestamp o String
      final rawDate = historyMap['date'];
      historyMap['date'] = parseDate(rawDate);
      historyMap['type'] = historyMap['type'] as String? ?? 'other';
      historyMap['amount'] = (historyMap['amount'] as num?)?.toDouble() ?? 0.0;
      historyMap['quantity'] = (historyMap['quantity'] as num?)?.toDouble();
      historyMap['exchangeRate'] = (historyMap['exchangeRate'] as num?)?.toDouble();
      historyMap['notes'] = historyMap['notes'] as String?;
      return historyMap;
    }).toList();

    return Investment(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'other',
      initialAmount: (data['initialAmount'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (data['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      startDate: parseDate(data['startDate']) ?? DateTime.now(),
      currency: data['currency'] as String?,
      currentAmount: (data['currentAmount'] as num?)?.toDouble(),
      yieldRate: (data['yieldRate'] as num?)?.toDouble(),
      yieldFrequency: data['yieldFrequency'] as String?,
      lastYieldDate: parseDate(data['lastYieldDate']),
      platform: data['platform'] as String?,
      externalId: data['externalId'] as String?,
      notes: data['notes'] as String?,
      history: history,
      currentQuantity: (data['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      totalInvested: (data['totalInvested'] as num?)?.toDouble() ?? 0.0,
      estimatedCurrentValue: (data['estimatedCurrentValue'] as num?)?.toDouble() ?? 0.0,
      estimatedGainLoss: (data['estimatedGainLoss'] as num?)?.toDouble() ?? 0.0,
      totalDividends: (data['totalDividends'] as num?)?.toDouble() ?? 0.0,
      creationDate: parseDate(data['creationDate']) ?? DateTime.now(),
      status: data['status'] as String?,
      isinSymbol: data['isinSymbol'] as String?,
      originCountry: data['originCountry'] as String?,
      annualProjectedYield: (data['annualProjectedYield'] as num?)?.toDouble(),
    );
  }

  // Método para convertir una instancia de Investment a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'initialAmount': initialAmount,
      'totalQuantity': totalQuantity, // <-- Guardar totalQuantity
      'startDate': Timestamp.fromDate(startDate),
      'currency': currency,
      'currentAmount': currentAmount,
      'yieldRate': yieldRate,
      'yieldFrequency': yieldFrequency,
      'lastYieldDate': lastYieldDate != null ? Timestamp.fromDate(lastYieldDate!) : null,
      'platform': platform,
      'externalId': externalId,
      'notes': notes,
      'history': history, // Guardar la lista (cada mapa con los nuevos campos si existen)

      // Guardar campos calculados
      'currentQuantity': currentQuantity,
      'totalInvested': totalInvested,
      'estimatedCurrentValue': estimatedCurrentValue,
      'estimatedGainLoss': estimatedGainLoss,
      'totalDividends': totalDividends,

      // Guardar nuevos campos del modelo restructurado
      'creationDate': Timestamp.fromDate(creationDate),
      'status': status,
      'isinSymbol': isinSymbol,
      'originCountry': originCountry,
      'annualProjectedYield': annualProjectedYield,
    };
  }

  // Método copyWith para facilitar la creación de nuevas instancias modificadas
  Investment copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? initialAmount,
    double? totalQuantity, // <-- Añadir a copyWith
    DateTime? startDate,
    String? currency,
    double? currentAmount,
    double? yieldRate,
    String? yieldFrequency,
    DateTime? lastYieldDate,
    String? platform,
    String? externalId,
    String? notes,
    List<Map<String, dynamic>>? history,

    // Campos calculados
    double? currentQuantity,
    double? totalInvested,
    double? estimatedCurrentValue,
    double? estimatedGainLoss,
    double? totalDividends,

     // Nuevos campos del modelo restructurado
    DateTime? creationDate,
    String? status,
    String? isinSymbol,
    String? originCountry,
    double? annualProjectedYield,

  }) {
    return Investment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialAmount: initialAmount ?? this.initialAmount,
      totalQuantity: totalQuantity ?? this.totalQuantity, // <-- Usar en copyWith
      startDate: startDate ?? this.startDate,
      currency: currency ?? this.currency,
      currentAmount: currentAmount ?? this.currentAmount,
      yieldRate: yieldRate ?? this.yieldRate,
      yieldFrequency: yieldFrequency ?? this.yieldFrequency,
      lastYieldDate: lastYieldDate ?? this.lastYieldDate,
      platform: platform ?? this.platform,
      externalId: externalId ?? this.externalId,
      notes: notes ?? this.notes,
      history: history ?? this.history,

      // Campos calculados
      currentQuantity: currentQuantity ?? this.currentQuantity,
      totalInvested: totalInvested ?? this.totalInvested,
      estimatedCurrentValue: estimatedCurrentValue ?? this.estimatedCurrentValue,
      estimatedGainLoss: estimatedGainLoss ?? this.estimatedGainLoss,
      totalDividends: totalDividends ?? this.totalDividends,

       // Nuevos campos del modelo restructurado
      creationDate: creationDate ?? this.creationDate,
      status: status ?? this.status,
      isinSymbol: isinSymbol ?? this.isinSymbol,
      originCountry: originCountry ?? this.originCountry,
      annualProjectedYield: annualProjectedYield ?? this.annualProjectedYield,
    );
  }
}
