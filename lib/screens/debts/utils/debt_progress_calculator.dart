/// Utilidad para calcular el progreso de pago de deudas de manera consistente
/// en toda la aplicación.
library;

/// Calcula el porcentaje de progreso de una deuda usando una lógica unificada:
/// 1. Si hay cuotas definidas (totalInstallments > 0), usa progreso por cuotas pagadas
/// 2. Si no hay cuotas definidas, usa progreso por monto (initialAmount - currentAmount)
/// 
/// [paidInstallments] - Número de cuotas normales pagadas (excluye abonos)
/// [totalInstallments] - Número total de cuotas programadas
/// [initialAmount] - Monto inicial de la deuda
/// [currentAmount] - Monto restante de la deuda
/// 
/// Retorna el porcentaje de progreso (0.0 - 100.0)
double calculateDebtProgress({
  required int paidInstallments,
  required int totalInstallments,
  required double initialAmount,
  required double currentAmount,
}) {
  // Priorizar progreso por cuotas si está disponible
  if (totalInstallments > 0) {
    return (paidInstallments / totalInstallments) * 100;
  }
  
  // Fallback: progreso por monto si no hay cuotas definidas
  if (initialAmount > 0) {
    return ((initialAmount - currentAmount) / initialAmount) * 100;
  }
  
  // Si no hay información suficiente, retornar 0%
  return 0.0;
}

/// Calcula el número de cuotas normales pagadas (excluye abonos a capital)
/// [paymentHistory] - Historial de pagos de la deuda
/// 
/// Retorna el número de pagos con tipo 'normal'
int calculatePaidInstallments(List<Map<String, dynamic>>? paymentHistory) {
  if (paymentHistory == null || paymentHistory.isEmpty) {
    return 0;
  }
  
  return paymentHistory.where((payment) {
    final paymentType = payment['paymentType'] as String? ?? 'normal';
    return paymentType == 'normal'; // Solo contar cuotas normales, no abonos
  }).length;
}

/// Calcula el método de cálculo que se está usando para el progreso
/// Útil para debugging y logging
String getProgressCalculationMethod(int totalInstallments) {
  return totalInstallments > 0 ? 'installments' : 'amount';
}
