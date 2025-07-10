import 'package:flutter/material.dart';
import 'package:mis_finanza/models/stock_quote.dart';
import 'package:mis_finanza/services/market_data_service.dart';
import 'package:mis_finanza/services/stock_quote_cache_service.dart';

class StockQuoteWidget extends StatefulWidget {
  final String symbol;
  const StockQuoteWidget({super.key, required this.symbol});

  @override
  State<StockQuoteWidget> createState() => _StockQuoteWidgetState();
}

class _StockQuoteWidgetState extends State<StockQuoteWidget> {
  StockQuote? _quote;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrFetchQuote();
  }

  Future<void> _loadOrFetchQuote() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final cache = StockQuoteCacheService();
    final cached = await cache.getQuote(widget.symbol);
    final now = DateTime.now();
    if (cached != null && now.difference(cached.lastUpdated).inHours < 24) {
      setState(() {
        _quote = cached;
        _loading = false;
      });
    } else {
      await _fetchQuote(saveToCache: true);
    }
  }

  Future<void> _fetchQuote({bool saveToCache = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = MarketDataService();
      final quote = await service.fetchQuote(widget.symbol);
      if (quote != null && saveToCache) {
        await StockQuoteCacheService().saveQuote(quote);
      }
      setState(() {
        _quote = quote;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al obtener cotización';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : _quote == null
                    ? const Text('Sin datos de cotización')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _quote!.symbol,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Precio: ${_quote!.price.toStringAsFixed(2)}'),
                          Text('Cambio: ${_quote!.change.toStringAsFixed(2)}'),
                          Text('Variación: ${_quote!.changePercent.toStringAsFixed(2)}%'),
                          Text('Actualizado: ${_quote!.lastUpdated.hour}:${_quote!.lastUpdated.minute.toString().padLeft(2, '0')}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _fetchQuote(saveToCache: true),
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
      ),
    );
  }
}
