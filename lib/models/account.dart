// lib/models/account.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final String? id; // ID del documento en Firestore
  final String userId; // ID del usuario propietario
  final String name;
  final String type; // Ej: 'checking', 'savings', 'credit_card', 'investment', 'cash', 'Deuda'
  final String currency; // Ej: 'USD', 'COP', 'EUR'
  final double initialBalance; // Saldo inicial al crear (principalmente para cuentas no CC)
  final double currentBalance; // Para cuentas no CC: el saldo actual real. Para CC: el cupo DISPONIBLE.
  final double? yieldRate; // Tasa de rendimiento anual para cuentas de ahorro (opcional)
  final double? savingsTargetAmount; // Meta de ahorro (opcional)
  final DateTime? savingsTargetDate; // Fecha límite para la meta (opcional)
  final bool isArchived; // Para ocultar cuentas antiguas
  final int order; // Orden de visualización (opcional)

  // --- NUEVOS CAMPOS PARA TARJETAS DE CRÉDITO ---
  final bool isCreditCard; // Indica si esta cuenta es una tarjeta de crédito
  final double creditLimit; // Límite total de crédito
  final double currentStatementBalance; // Saldo actual adeudado en la tarjeta (gastado)  // NUEVOS CAMPOS PARA TARJETAS DE CRÉDITO RECURRENTES
  final int? cutOffDay; // Día de la fecha de corte (1-31)
  final int? paymentDueDay; // Día de la fecha de pago (1-31)
  // final DateTime? paymentDueDate; // Opcional: Fecha límite de pago del estado de cuenta actual (Si lo quieres añadir)
  // ---------------------------------------------

  // --- NUEVOS CAMPOS PERSONALIZABLES ---
  final String? customId; // ID personalizado alfanumérico (no obligatorio)
  final String? customKey; // Llave personalizada alfanumérica (no obligatorio)
  // -------------------------------------

  Account({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.currentBalance, // Nota: para CC, este será el Cupo Disponible al crear/leer
    this.yieldRate,
    this.savingsTargetAmount,
  this.savingsTargetDate,
  this.isArchived = false,
  required this.order,
    // --- Inicialización de nuevos campos (default values) ---
    this.isCreditCard = false, // Por defecto no es tarjeta de crédito
    this.creditLimit = 0.0,
    this.currentStatementBalance = 0.0,    this.cutOffDay,
    this.paymentDueDay,
    // this.paymentDueDate,
    // ----------------------------------------------------
    
    // --- Inicialización de nuevos campos personalizables ---
    this.customId,
    this.customKey,
    // ------------------------------------------------------
  });

  // Constructor factory para crear una instancia de Account desde un documento de Firestore
  factory Account.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] as String? ?? 'checking'; // Default to checking if type is null

    // --- Lógica para determinar isCreditCard y leer campos de CC ---
    final isCreditCard = data['isCreditCard'] as bool? ?? type == 'credit_card'; // Intentar leer el campo, o inferir del tipo
    final creditLimit = (data['creditLimit'] as num?)?.toDouble() ?? 0.0;
    final currentStatementBalance = (data['currentStatementBalance'] as num?)?.toDouble() ?? 0.0;    final cutOffDay = data['cutOffDay'] as int?;
    final paymentDueDay = data['paymentDueDay'] as int?;
    // final paymentDueDate = (data['paymentDueDate'] as Timestamp?)?.toDate();
    // -----------------------------------------------------------

    // --- Leer nuevos campos personalizables ---
    final customId = data['customId'] as String?;
    final customKey = data['customKey'] as String?;
    // -----------------------------------------

  return Account(
  id: doc.id, // El ID del documento es importante
  userId: data['userId'] as String? ?? '',
  name: data['name'] as String? ?? '',
  type: type,
  currency: data['currency'] as String? ?? 'USD',
  initialBalance: (data['initialBalance'] as num?)?.toDouble() ?? 0.0, // Asegurar lectura correcta
  // --- Leer currentBalance: para CC es Cupo Disponible (Limit - Adeudado) ---
      currentBalance: isCreditCard // Si es Tarjeta de Crédito...
          ? creditLimit - currentStatementBalance // ...el balance en el objeto es Cupo Disponible
          : (data['currentBalance'] as num?)?.toDouble() ?? 0.0, // ...si no, es el saldo real
      // -----------------------------------------------------------------------
  yieldRate: (data['yieldRate'] as num?)?.toDouble(),
  savingsTargetAmount: (data['savingsTargetAmount'] as num?)?.toDouble(),
  savingsTargetDate: (data['savingsTargetDate'] as Timestamp?)?.toDate(),
  isArchived: data['isArchived'] as bool? ?? false, // Asegurar lectura correcta
  order: (data['order'] as num?)?.toInt() ?? 0, // Asegurar lectura correcta
      // --- Asignar campos de CC leídos ---
      isCreditCard: isCreditCard,
      creditLimit: creditLimit,
      currentStatementBalance: currentStatementBalance,      cutOffDay: cutOffDay,
      paymentDueDay: paymentDueDay,
      // paymentDueDate: paymentDueDate,
      // ----------------------------------
      
      // --- Asignar nuevos campos personalizables ---
      customId: customId,
      customKey: customKey,
      // --------------------------------------------
  );
  }

  // Método para convertir una instancia de Account a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
   return {
  'userId': userId,
  'name': name,
  'type': type,
  'currency': currency,
  'initialBalance': initialBalance,
      // --- Guardar currentBalance: SOLO si NO es Tarjeta de Crédito ---
      // Para CC, no guardamos el currentBalance (Cupo Disponible) directamente,
      // se calcula a partir de creditLimit y currentStatementBalance.
  'currentBalance': isCreditCard ? null : currentBalance, // Guarda si no es CC, null si es CC
      // -------------------------------------------------------------------
  'yieldRate': yieldRate,
  'savingsTargetAmount': savingsTargetAmount,
  'savingsTargetDate': savingsTargetDate != null ? Timestamp.fromDate(savingsTargetDate!) : null,
  'isArchived': isArchived,
  'order': order,
      // --- Guardar NUEVOS campos (para CC) ---
      'isCreditCard': isCreditCard, // Guardamos si es CC o no
      'creditLimit': isCreditCard ? creditLimit : null, // Solo guarda si es CC
      'currentStatementBalance': isCreditCard ? currentStatementBalance : null, // Solo guarda si es CC      'cutOffDay': isCreditCard ? cutOffDay : null, // Solo guarda si es CC
      'paymentDueDay': isCreditCard ? paymentDueDay : null, // Solo guarda si es CC
      // 'paymentDueDate': paymentDueDate != null ? Timestamp.fromDate(paymentDueDate!) : null,
      // ----------------------------------------
      
      // --- Guardar nuevos campos personalizables ---
      'customId': customId, // Siempre guarda (puede ser null)
      'customKey': customKey, // Siempre guarda (puede ser null)
      // --------------------------------------------
  };
  }

  // Método copyWith para facilitar la creación de nuevas instancias modificadas
  Account copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? currency,
  double? initialBalance,
  double? currentBalance,
  double? yieldRate,
  double? savingsTargetAmount,
  DateTime? savingsTargetDate,
  bool? isArchived,
  int? order,
    // --- copyWith para NUEVOS campos ---
    bool? isCreditCard,
    double? creditLimit,
    double? currentStatementBalance,    int? cutOffDay,
    int? paymentDueDay,
    // DateTime? paymentDueDate,
    // ---------------------------------
    
    // --- copyWith para nuevos campos personalizables ---
    String? customId,
    String? customKey,
    // --------------------------------------------------
  }) {
  return Account(
  id: id ?? this.id,
  userId: userId ?? this.userId,
  name: name ?? this.name,
  type: type ?? this.type,
  currency: currency ?? this.currency,
  initialBalance: initialBalance ?? this.initialBalance,
      // Nota: si actualizas currentBalance vía copyWith para una CC,
      // estarías actualizando el Cupo Disponible.
      // Las actualizaciones de saldo/adeudado de CC se manejan mejor en la lógica de movimientos.
  currentBalance: currentBalance ?? this.currentBalance,
  yieldRate: yieldRate ?? this.yieldRate,
  savingsTargetAmount: savingsTargetAmount ?? this.savingsTargetAmount,
  savingsTargetDate: savingsTargetDate ?? this.savingsTargetDate,
  isArchived: isArchived ?? this.isArchived,
  order: order ?? this.order,
      // --- Asignar nuevos campos en copyWith ---
      isCreditCard: isCreditCard ?? this.isCreditCard,
      creditLimit: creditLimit ?? this.creditLimit,
      currentStatementBalance: currentStatementBalance ?? this.currentStatementBalance,      cutOffDay: cutOffDay ?? this.cutOffDay,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      // paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      // -----------------------------------------
      
      // --- Asignar nuevos campos personalizables en copyWith ---
      customId: customId ?? this.customId,
      customKey: customKey ?? this.customKey,
      // -------------------------------------------------------
    );
  }
}