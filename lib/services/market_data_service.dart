import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_quote.dart';

class MarketDataService {
  final String apiKey = 'd0r0421r01qn4tjfkf70d0r0421r01qn4tjfkf7g'; // API Key de Finnhub
  final String baseUrl = 'https://finnhub.io/api/v1';

  static const List<String> trackedSymbols = [
    'VOO', 'QQQ', 'CVX', 'TSM', 'JPM', 'BRK.B', 'IBIT', 'GOOGL', 'SOXX',
    'AAPL', 'BAC', 'NVDA', 'AMD', 'VNQ', 'IAU', 'KO', 'JNJ','LIT','V',
    'PEP',
      'VZ',
      'MO',
      'MRK',
      'PG',
      'AMGN',
      'KBWY',
      'XSHD',
      'DIV',
      'NUDV',
      'SPYD',
      'RDIV',
      'SCHD',
      'VIG',
      'DVY',
      'VYM',
      'VGT',
      'VHT',
      'VFH',
      'VPU',
      'SDY',

    // Criptomonedas (símbolos de Finnhub, formato correcto para Binance)
    'BINANCE:BTCUSDT', 'BINANCE:XRPUSDT', 'BINANCE:DOGEUSDT', 'BINANCE:BCHUSDT', 'BINANCE:LTCUSDT', 'BINANCE:ETHUSDT', 'BINANCE:SOLUSDT', 'BINANCE:SHIBUSDT', 'BINANCE:ETCUSDT', 'BINANCE:PEPEUSDT',
  ];

  Future<StockQuote?> fetchQuote(String symbol) async {
    // Finnhub usa diferentes formatos para algunos símbolos (por ejemplo, BRK.B -> BRK.B o BRK-B)
    // Puedes ajustar aquí si algún símbolo no funciona correctamente
    final url = Uri.parse('$baseUrl/quote?symbol=$symbol&token=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Finnhub devuelve un objeto con claves: c (current), d (change), dp (change %), t (timestamp)
      if (data['c'] != null) {
        return StockQuote(
          symbol: symbol,
          price: (data['c'] as num?)?.toDouble() ?? 0.0,
          change: (data['d'] as num?)?.toDouble() ?? 0.0,
          changePercent: (data['dp'] as num?)?.toDouble() ?? 0.0,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch((data['t'] ?? 0) * 1000),
        );
      }
    }
    return null;
  }
}
