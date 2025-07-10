import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_quote.dart';

class StockQuoteCacheService {
  static const String _prefix = 'stock_quote_';

  Future<void> saveQuote(StockQuote quote) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode({
      'symbol': quote.symbol,
      'price': quote.price,
      'change': quote.change,
      'changePercent': quote.changePercent,
      'lastUpdated': quote.lastUpdated.toIso8601String(),
    });
    await prefs.setString(_prefix + quote.symbol, data);
  }

  Future<StockQuote?> getQuote(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefix + symbol);
    if (data == null) return null;
    final map = json.decode(data);
    return StockQuote(
      symbol: map['symbol'],
      price: (map['price'] as num).toDouble(),
      change: (map['change'] as num).toDouble(),
      changePercent: (map['changePercent'] as num).toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
