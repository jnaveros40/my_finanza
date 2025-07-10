// lib/services/dividend_service.dart

import 'package:mis_finanza/models/investment.dart';
import 'package:mis_finanza/services/finnhub_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DividendService {
  /// Obtener dividendos reales y simulados combinados
  static Future<List<DividendInfo>> getUpcomingDividends(List<Investment> investments) async {
    List<DividendInfo> allDividends = [];

    for (final investment in investments) {
      try {
        // Mapear nombre de inversión a símbolo
        final symbol = FinnhubService.mapInvestmentNameToSymbol(investment.name);        // Intentar obtener dividendos reales de Finnhub con fallback
        final dividendResult = await FinnhubService.getDividendsWithFallback(symbol);
        
        if (dividendResult.dividends.isNotEmpty) {
          // Usar dividendos (reales o fallback realista)
          for (final dividend in dividendResult.dividends) {
            // Solo incluir dividendos futuros o recientes (últimos 6 meses)
            if (dividend.date.isAfter(DateTime.now().subtract(Duration(days: 180)))) {
              allDividends.add(DividendInfo(
                investment: investment,
                date: dividend.date,
                amount: dividend.amount * investment.totalQuantity, // Multiplicar por cantidad de acciones
                currency: dividend.currency,
                frequency: dividend.frequency,
                isReal: dividendResult.isFromApi, // Solo marcar como real si viene de la API
                symbol: symbol,
                notes: dividendResult.isFromApi ? 
                  'Dividendo real de ${investment.name} (API Finnhub)' : 
                  'Dividendo estimado basado en datos históricos de ${investment.name}',
              ));
            }
          }
        } else {
          // Fallback final a simulación básica
          final simulatedDividends = _generateSimulatedDividends(investment);
          allDividends.addAll(simulatedDividends);
        }
      } catch (e) {
        print('Error procesando dividendos para ${investment.name}: $e');
        // Fallback a simulación en caso de error
        final simulatedDividends = _generateSimulatedDividends(investment);
        allDividends.addAll(simulatedDividends);
      }
    }

    // Ordenar por fecha
    allDividends.sort((a, b) => a.date.compareTo(b.date));
    
    return allDividends;
  }

  /// Generar dividendos simulados basados en el historial de la inversión
  static List<DividendInfo> _generateSimulatedDividends(Investment investment) {
    List<DividendInfo> simulatedDividends = [];
    
    // Buscar dividendos históricos en el historial de la inversión
    final historicalDividends = investment.history?.where((movement) => 
      movement['type'] == 'dividendo'
    ).toList() ?? [];

    if (historicalDividends.isNotEmpty) {
      // Usar datos históricos para simular próximos dividendos
      for (int i = 0; i < historicalDividends.length; i++) {
        final movement = historicalDividends[i];
        final date = (movement['date'] as Timestamp?)?.toDate();
        final amount = (movement['amount'] as num?)?.toDouble() ?? 0.0;
        final notes = movement['notes'] as String? ?? '';

        if (date != null) {
          simulatedDividends.add(DividendInfo(
            investment: investment,
            date: date,
            amount: amount,
            currency: 'USD',
            frequency: 'Historical',
            isReal: false,
            symbol: investment.name.toUpperCase(),
            notes: notes.isNotEmpty ? notes : 'Dividendo histórico registrado',
          ));
        }
      }
    } else {
      // Generar dividendos simulados inteligentemente
      final baseAmount = investment.estimatedCurrentValue * 0.02; // 2% dividend yield aproximado
      final now = DateTime.now();
      
      // Generar próximos 4 dividendos trimestrales
      for (int i = 1; i <= 4; i++) {
        final futureDate = DateTime(now.year, now.month + (i * 3), 15);
        
        simulatedDividends.add(DividendInfo(
          investment: investment,
          date: futureDate,
          amount: baseAmount / 4, // Dividendo trimestral
          currency: 'USD',
          frequency: 'Quarterly',
          isReal: false,
          symbol: investment.name.toUpperCase(),
          notes: 'Dividendo simulado (estimación basada en 2% yield anual)',
        ));
      }
    }

    return simulatedDividends;
  }

  /// Obtener información de la empresa desde Finnhub
  static Future<CompanyProfile?> getCompanyInfo(String investmentName) async {
    try {
      final symbol = FinnhubService.mapInvestmentNameToSymbol(investmentName);
      return await FinnhubService.getCompanyProfile(symbol);
    } catch (e) {
      print('Error obteniendo información de la empresa $investmentName: $e');
      return null;
    }
  }

  /// Obtener cotización actual desde Finnhub
  static Future<StockQuote?> getCurrentQuote(String investmentName) async {
    try {
      final symbol = FinnhubService.mapInvestmentNameToSymbol(investmentName);
      return await FinnhubService.getQuote(symbol);
    } catch (e) {
      print('Error obteniendo cotización de $investmentName: $e');
      return null;
    }
  }
}

/// Modelo de información de dividendos enriquecido
class DividendInfo {
  final Investment investment;
  final DateTime date;
  final double amount;
  final String currency;
  final String frequency;
  final bool isReal; // true si viene de API real, false si es simulado
  final String symbol;
  final String notes;

  DividendInfo({
    required this.investment,
    required this.date,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.isReal,
    required this.symbol,
    required this.notes,
  });

  /// Obtener estado del dividendo
  DividendStatus get status {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return DividendStatus.today;
    } else if (difference < 0) {
      return DividendStatus.past;
    } else if (difference <= 7) {
      return DividendStatus.thisWeek;
    } else if (difference <= 30) {
      return DividendStatus.thisMonth;
    } else {
      return DividendStatus.future;
    }
  }

  /// Obtener color según el estado
  String get statusText {
    switch (status) {
      case DividendStatus.today:
        return 'Hoy';
      case DividendStatus.past:
        return 'Pasado';
      case DividendStatus.thisWeek:
        return 'Esta semana';
      case DividendStatus.thisMonth:
        return 'Este mes';
      case DividendStatus.future:
        return 'Próximo';
    }
  }
}

enum DividendStatus {
  today,
  past,
  thisWeek,
  thisMonth,
  future,
}
