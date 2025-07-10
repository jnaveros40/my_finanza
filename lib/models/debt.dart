// lib/models/debt.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Debt {
  final String? id; // ID del documento en Firestore
  final String userId; // ID del usuario propietario
  final String description; // Nombre identificativo de la deuda
  final String? creditorDebtor; // Persona o entidad a quien se le debe el dinero (acreedor)
  final double initialAmount; // Monto original prestado o financiado (capital_inicial)
  final double currentAmount; // Monto restante de la deuda (mantener para seguimiento)

  final double? insuranceValue; // Suma de seguros asociados (Valor fijo mensual)
  final int? totalInstallments; // Total de cuotas pactadas (Plazo en meses)
  final int? paidInstallments; // Cuántas cuotas ya se han pagado
  final double? installmentValue; // Monto que se paga en cada cuota (CALCULADO: Cuota mensual total con seguro)

  final DateTime creationDate; // Fecha en que se creó el registro de la deuda en la app
  final DateTime? startDate; // Fecha del primer pago o inicio del crédito
  final DateTime? dueDate; // Fecha estimada del último pago (fecha_fin)

  final double? annualEffectiveInterestRate; // Tasa de interés efectiva anual (%)
  final double? interestPaid; // Acumulado de intereses pagados hasta ahora (REAL, por pagos registrados)
  final double? totalCalculatedInterest; // NUEVO: Total de intereses calculado por la herramienta

  final String type; // Tipo de deuda (ej. 'loan', 'credit_card_debt', 'other')
  final String status; // Estado de la deuda (ej. 'active', 'paid', 'defaulted')

  final String currency; // Moneda de la deuda (ej. 'COP', 'USD')
  final String? notes; // Comentarios o información adicional relevante

  // Historial de pagos: Ahora cada mapa incluye 'paymentType'
  final List<Map<String, dynamic>>? paymentHistory;
  final String? externalId; // ID de referencia en un sistema externo
  final int? paymentDay; // Día de pago (1-30)

  Debt({
    this.id,
    required this.userId,
    required this.description,
    this.creditorDebtor,
    required this.initialAmount,
    required this.currentAmount,
    this.insuranceValue,
    this.totalInstallments,
    this.paidInstallments,
    this.installmentValue, // Ahora puede ser el valor calculado
    required this.creationDate,
    this.startDate,
    this.dueDate,
    this.annualEffectiveInterestRate,
    this.interestPaid, // Para seguimiento real
    this.totalCalculatedInterest, // NUEVO: Para el cálculo inicial
    required this.type,
    required this.status,
    required this.currency,
    this.notes,
    this.paymentHistory, // Puede ser null inicialmente
    this.externalId,
    this.paymentDay,
  });

  // Constructor factory para crear una instancia de Debt desde un documento de Firestore
  factory Debt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Asegurarse de que paymentHistory se lee correctamente, incluyendo el nuevo campo
    final List<dynamic>? historyData = data['paymentHistory'] as List<dynamic>?;
    final List<Map<String, dynamic>>? paymentHistory = historyData?.map((item) {
      final Map<String, dynamic> paymentMap = item as Map<String, dynamic>;
      // Asegurar que 'paymentType' existe, usar un valor por defecto si no
      paymentMap['paymentType'] = paymentMap['paymentType'] as String? ?? 'normal'; // Valor por defecto 'normal'
      return paymentMap;
    }).toList();


    return Debt(
      id: doc.id, // El ID del documento es importante
      userId: data['userId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      creditorDebtor: data['creditorDebtor'] as String?,
      initialAmount: (data['initialAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      insuranceValue: (data['insuranceValue'] as num?)?.toDouble(),
      totalInstallments: data['totalInstallments'] as int?,
      paidInstallments: data['paidInstallments'] as int?,
      installmentValue: (data['installmentValue'] as num?)?.toDouble(), // Leer el valor calculado o ingresado
      creationDate: (data['creationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      annualEffectiveInterestRate: (data['annualEffectiveInterestRate'] as num?)?.toDouble(),
      interestPaid: (data['interestPaid'] as num?)?.toDouble(), // Leer el interés pagado real
      totalCalculatedInterest: (data['totalCalculatedInterest'] as num?)?.toDouble(), // NUEVO: Leer el total calculado
      type: data['type'] as String? ?? 'other',
      status: data['status'] as String? ?? 'active',
      currency: data['currency'] as String? ?? '???',
      notes: data['notes'] as String?,
      paymentHistory: paymentHistory, // Usar la lista procesada
      externalId: data['externalId'] as String?,
      paymentDay: data['paymentDay'] as int?,
    );
  }

  // Método para convertir una instancia de Debt a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'description': description,
      'creditorDebtor': creditorDebtor,
      'initialAmount': initialAmount,
      'currentAmount': currentAmount,
      'insuranceValue': insuranceValue,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'installmentValue': installmentValue, // Guardar el valor calculado o ingresado
      'creationDate': Timestamp.fromDate(creationDate),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'annualEffectiveInterestRate': annualEffectiveInterestRate,
      'interestPaid': interestPaid, // Guardar el interés pagado real
      'totalCalculatedInterest': totalCalculatedInterest, // NUEVO: Guardar el total calculado
      'type': type,
      'status': status,
      'currency': currency,
      'notes': notes,
      'paymentHistory': paymentHistory, // Guardar la lista (cada mapa con paymentType)
      'externalId': externalId,
      'paymentDay': paymentDay,
    };
  }

  // Método copyWith para facilitar la creación de nuevas instancias modificadas
  Debt copyWith({
    String? id,
    String? userId,
    String? description,
    String? creditorDebtor,
    double? initialAmount,
    double? currentAmount,
    double? insuranceValue,
    int? totalInstallments,
    int? paidInstallments,
    double? installmentValue,
    DateTime? creationDate,
    DateTime? startDate,
    DateTime? dueDate,
    double? annualEffectiveInterestRate,
    double? interestPaid,
    double? totalCalculatedInterest, // NUEVO: Añadir a copyWith
    String? type,
    String? status,
    String? currency,
    String? notes,
    List<Map<String, dynamic>>? paymentHistory,
    String? externalId,
    int? paymentDay,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      creditorDebtor: creditorDebtor ?? this.creditorDebtor,
      initialAmount: initialAmount ?? this.initialAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      insuranceValue: insuranceValue ?? this.insuranceValue,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      installmentValue: installmentValue ?? this.installmentValue, // Incluir en copyWith
      creationDate: creationDate ?? this.creationDate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      annualEffectiveInterestRate: annualEffectiveInterestRate ?? this.annualEffectiveInterestRate,
      interestPaid: interestPaid ?? this.interestPaid, // Incluir en copyWith
      totalCalculatedInterest: totalCalculatedInterest ?? this.totalCalculatedInterest, // NUEVO: Incluir en copyWith
      type: type ?? this.type,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      externalId: externalId ?? this.externalId,
      paymentDay: paymentDay ?? this.paymentDay,
    );
  }
}
