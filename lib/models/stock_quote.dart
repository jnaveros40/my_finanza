class StockQuote {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;

  StockQuote({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });

  factory StockQuote.fromAlphaVantage(Map<String, dynamic> json) {
    // Alpha Vantage devuelve los datos en la clave 'Global Quote'
    final quote = json['Global Quote'] ?? {};
    return StockQuote(
      symbol: quote['01. symbol'] ?? '',
      price: double.tryParse(quote['05. price'] ?? '0') ?? 0.0,
      change: double.tryParse(quote['09. change'] ?? '0') ?? 0.0,
      changePercent: double.tryParse((quote['10. change percent'] ?? '0').replaceAll('%', '')) ?? 0.0,
      lastUpdated: DateTime.now(),
    );
  }
}
