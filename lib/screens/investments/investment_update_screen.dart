// lib/screens/investments/investment_update_screen.dart

import 'package:flutter/material.dart';
import 'widgets/stock_quote_widget.dart';

class InvestmentUpdateScreen extends StatelessWidget {
  const InvestmentUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final etfs = [
      'VOO',
      'QQQ',
      'IBIT',
      'SOXX',
      'VNQ',
      'IAU',
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

    ];
    final stocks = [
      'CVX',
      'TSM',
      'JPM',
      'BRK.B',
      'GOOGL',
      'AAPL',
      'BAC',
      'NVDA',
      'AMD',
      'KO',
      'JNJ',
      'LIT',
      'V',
      'PEP',
      'VZ',
      'MO',
      'MRK',
      'PG',
      'AMGN',

    ];
    final cryptos = [
      'BINANCE:BTCUSDT',
      'BINANCE:ETHUSDT',
      'BINANCE:XRPUSDT',
      'BINANCE:DOGEUSDT',
      'BINANCE:BCHUSDT',
      'BINANCE:LTCUSDT',
      'BINANCE:SOLUSDT',
      'BINANCE:SHIBUSDT',
      'BINANCE:ETCUSDT',
      'BINANCE:PEPEUSDT',
    ];

    Widget buildExpansionTile({
      required String title,
      required Icon leading,
      required List<String> symbols,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          initiallyExpanded: true,
          leading: leading,
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          children: symbols
              .map((symbol) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: StockQuoteWidget(symbol: symbol),
                  ))
              .toList(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualización de Inversiones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          buildExpansionTile(
            title: 'ETFs',
            leading: const Icon(Icons.trending_up, color: Colors.blue),
            symbols: etfs,
          ),
          buildExpansionTile(
            title: 'Acciones',
            leading: const Icon(Icons.show_chart, color: Colors.green),
            symbols: stocks,
          ),
          buildExpansionTile(
            title: 'Criptomonedas',
            leading: const Icon(Icons.currency_bitcoin, color: Colors.orange),
            symbols: cryptos,
          ),
        ],
      ),
    );
  }
}
