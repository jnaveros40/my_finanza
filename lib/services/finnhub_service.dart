// lib/services/finnhub_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FinnhubService {
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  // ⚠️ IMPORTANTE: Necesitas registrarte en https://finnhub.io/ para obtener una API key gratuita
  // El plan gratuito incluye 60 llamadas por minuto
  // static const String _apiKey = 'sandbox_c83naiad3if3cn6a4vd0'; // API key de sandbox para pruebas
  
  // Para producción, usa tu API key real obtenida de https://finnhub.io/
  static const String _apiKey = 'd1858chr01ql1b4lsjdgd1858chr01ql1b4lsje0';
  
  // Cache para evitar llamadas innecesarias
  static final Map<String, List<DividendData>> _dividendCache = {};
  static final Map<String, CompanyProfile> _companyCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 6);

  // Lista de criptomonedas que NO tienen dividendos
  static const Set<String> _cryptoSymbols = {
    'BTC', 'ETH', 'LTC', 'BCH', 'XRP', 'DOGE', 'SOL', 'SHIB', 'PEPE', 'ETC',
    'ADA', 'MATIC', 'DOT', 'LINK', 'UNI', 'AVAX', 'ATOM', 'FTM', 'NEAR'
  };

  // Lista de ETFs que SÍ pueden tener dividendos
  static const Set<String> _etfSymbols = {
    'QQQ', 'VNQ', 'IAU', 'SOXX', 'IBIT', 'VOO', 'SPY', 'VTI', 'VXUS',
    'IWM', 'EFA', 'VEA', 'VWO', 'GLD', 'TLT', 'IEF', 'LQD', 'HYG'
  };

  /// Verificar si un símbolo puede tener dividendos
  static bool _canHaveDividends(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    
    // Las criptomonedas NO tienen dividendos
    if (_cryptoSymbols.contains(upperSymbol)) {
      //print('🪙 Skipping $symbol - Cryptocurrencies don\'t pay dividends');
      return false;
    }
    
    // Solo procesar acciones y ETFs conocidos
    return true;
  }
  /// Verificar si la API key está configurada correctamente
  static bool _hasValidApiKey() {
    return _apiKey != 'YOUR_API_KEY_HERE' && 
           _apiKey.isNotEmpty && 
           !_apiKey.startsWith('sandbox_');
  }/// Obtener dividendos de una acción específica
  static Future<List<DividendData>> getDividends(String symbol, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      // Verificar si el símbolo puede tener dividendos
      if (!_canHaveDividends(symbol)) {
        return [];
      }      // Verificar API key
      if (!_hasValidApiKey()) {
        print('⚠️ Warning: Using sandbox API key. Register at https://finnhub.io for real data');
      } else {
        print('✅ Using production API key for real dividend data');
      }

      // Verificar cache
      final cacheKey = '${symbol}_dividends';
      if (_dividendCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        print('📦 Returning cached dividends for $symbol');
        return _dividendCache[cacheKey]!;
      }

      from ??= DateTime.now().subtract(Duration(days: 365));
      to ??= DateTime.now().add(Duration(days: 365));
      
      final url = Uri.parse(
        '$_baseUrl/stock/dividend?symbol=$symbol&from=${_dateToUnix(from)}&to=${_dateToUnix(to)}&token=$_apiKey'
      );
      
      print('📈 Fetching dividends for $symbol (stocks/ETF)...');
      final response = await http.get(url);
        if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          final dividends = data.map((dividend) => DividendData.fromFinnhub(dividend)).toList();
          
          // Guardar en cache
          _dividendCache[cacheKey] = dividends;
          _cacheTimestamps[cacheKey] = DateTime.now();
          
          print('🎉 SUCCESS: Found ${dividends.length} real dividends for $symbol');
          
          // Mostrar algunos detalles para debugging
          if (dividends.isNotEmpty) {
            final latest = dividends.first;
            print('   📅 Latest dividend: ${latest.amount} ${latest.currency} on ${latest.date.toString().split(' ')[0]}');
          }
          
          return dividends;
        } else {
          print('📭 No dividends found for $symbol (company may not pay dividends)');
          return [];
        }
      } else if (response.statusCode == 403) {
        print('� API Access denied for $symbol');
        //print('💡 Solution: Register at https://finnhub.io for a free API key');
        //print('💡 Free tier: 60 calls/minute, perfect for this app');
        return [];
      } else if (response.statusCode == 429) {
        print('⏳ API rate limit exceeded. Waiting...');
        await Future.delayed(Duration(seconds: 1));
        return [];
      } else {
        print('❌ API Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getting dividends for $symbol: $e');
      return [];
    }
  }
  
  /// Obtener información de perfil de una empresa
  static Future<CompanyProfile?> getCompanyProfile(String symbol) async {
    try {
      // Verificar cache
      final cacheKey = '${symbol}_profile';
      if (_companyCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        print('📦 Returning cached profile for $symbol');
        return _companyCache[cacheKey];
      }

      final url = Uri.parse('$_baseUrl/stock/profile2?symbol=$symbol&token=$_apiKey');
      
      print('🌐 Fetching company profile for $symbol from Finnhub...');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data != null && data.isNotEmpty) {
          final profile = CompanyProfile.fromJson(data);
          
          // Guardar en cache
          _companyCache[cacheKey] = profile;
          _cacheTimestamps[cacheKey] = DateTime.now();
          
          print('✅ Found profile for $symbol: ${profile.name}');
          return profile;
        } else {
          print('⚠️ No profile found for $symbol');
          return null;
        }
      } else {
        print('❌ Error fetching profile: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting company profile for $symbol: $e');
      return null;
    }
  }

  /// Obtener cotización actual de una acción
  static Future<StockQuote?> getQuote(String symbol) async {
    try {
      final url = Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data != null && data['c'] != null) {
          return StockQuote.fromJson(data);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Exception getting quote for $symbol: $e');
      return null;
    }
  }

  /// Mapear nombres de inversiones a símbolos de acciones reales
  static String mapInvestmentNameToSymbol(String investmentName) {
    final name = investmentName.toUpperCase();
    
    // Mapeo de nombres comunes a símbolos
    final symbolMap = {
      // Acciones populares
      'APPLE': 'AAPL',
      'MICROSOFT': 'MSFT',
      'GOOGLE': 'GOOGL',
      'ALPHABET': 'GOOGL',
      'AMAZON': 'AMZN',
      'TESLA': 'TSLA',
      'NVIDIA': 'NVDA',
      'META': 'META',
      'FACEBOOK': 'META',
      'NETFLIX': 'NFLX',
      'ADOBE': 'ADBE',
      'INTEL': 'INTC',
      'ORACLE': 'ORCL',
      'CISCO': 'CSCO',
      'IBM': 'IBM',
      'SALESFORCE': 'CRM',
      'PAYPAL': 'PYPL',
      'UBER': 'UBER',
      'ZOOM': 'ZM',
      'SPOTIFY': 'SPOT',
      'TWITTER': 'X',
      'SNAPCHAT': 'SNAP',
      'PINTEREST': 'PINS',
      'SQUARE': 'SQ',
      'SHOPIFY': 'SHOP',
      'AIRBNB': 'ABNB',
      'COINBASE': 'COIN',
      'ROBINHOOD': 'HOOD',
      
      // Bancos
      'JPMORGAN': 'JPM',
      'JP MORGAN': 'JPM',
      'BANK OF AMERICA': 'BAC',
      'WELLS FARGO': 'WFC',
      'GOLDMAN SACHS': 'GS',
      'MORGAN STANLEY': 'MS',
      'CITIGROUP': 'C',
      
      // Industria
      'BOEING': 'BA',
      'CATERPILLAR': 'CAT',
      'GENERAL ELECTRIC': 'GE',
      'FORD': 'F',
      'GENERAL MOTORS': 'GM',
      'DISNEY': 'DIS',
      'WALT DISNEY': 'DIS',
      'WALMART': 'WMT',
      'MCDONALD\'S': 'MCD',
      'MCDONALDS': 'MCD',
      'COCA COLA': 'KO',
      'COCA-COLA': 'KO',
      'PEPSI': 'PEP',
      'JOHNSON & JOHNSON': 'JNJ',
      'PROCTER & GAMBLE': 'PG',
      
      // ETFs populares
      'SPY': 'SPY',
      'QQQ': 'QQQ',
      'VTI': 'VTI',
      'VOO': 'VOO',
      'IVV': 'IVV',
      'VEA': 'VEA',
      'VWO': 'VWO',
      'BND': 'BND',
      'AGG': 'AGG',
      'GLD': 'GLD',
      'SLV': 'SLV',
    };
    
    // Primero buscar coincidencia exacta
    if (symbolMap.containsKey(name)) {
      return symbolMap[name]!;
    }
    
    // Buscar coincidencia parcial
    for (final entry in symbolMap.entries) {
      if (name.contains(entry.key) || entry.key.contains(name)) {
        return entry.value;
      }
    }
    
    // Si no hay mapeo, retornar el nombre original (podría ser ya un símbolo)
    return investmentName.toUpperCase();
  }

  /// Limpiar cache
  static void clearCache() {
    _dividendCache.clear();
    _companyCache.clear();
    _cacheTimestamps.clear();
    print('🧹 Cache cleared');
  }

  /// Obtener información sobre el estado de la API
  static Map<String, dynamic> getApiStatus() {
    return {
      'hasValidKey': _hasValidApiKey(),
      'cacheSize': _dividendCache.length,
      'apiKeyType': _apiKey.startsWith('sandbox_') ? 'sandbox' : 'production',
      'setupInstructions': {
        'step1': 'Go to https://finnhub.io/',
        'step2': 'Sign up for free account',
        'step3': 'Get your API key from dashboard',
        'step4': 'Replace the API key in finnhub_service.dart',
        'limits': 'Free tier: 60 calls/minute, 30 calls/second'
      }
    };
  }

  /// Verificar si el cache es válido
  static bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    
    return now.difference(timestamp) < _cacheExpiry;
  }
  
  /// Convertir DateTime a timestamp Unix
  static int _dateToUnix(DateTime date) {
    return (date.millisecondsSinceEpoch / 1000).round();
  }

  // Fallback: Datos de dividendos realistas para cuando la API no funciona
  static Map<String, List<Map<String, dynamic>>> _realisticDividendData = {
    'VOO': [
      {'date': '2025-03-31', 'amount': 1.81, 'currency': 'USD'},
      {'date': '2024-12-26', 'amount': 1.74, 'currency': 'USD'},
      {'date': '2024-10-01', 'amount': 1.64, 'currency': 'USD'},
      {'date': '2024-07-07', 'amount': 1.78, 'currency': 'USD'},
    ],
    'QQQ': [
      {'date': '2025-04-30', 'amount': 0.72, 'currency': 'USD'},
      {'date': '2024-12-31', 'amount': 0.83, 'currency': 'USD'},
      {'date': '2024-10-31', 'amount': 0.68, 'currency': 'USD'},
      {'date': '2024-07-31', 'amount': 0.76, 'currency': 'USD'},
    ],
    'CVX': [
      {'date': '2025-06-16', 'amount': 1.71, 'currency': 'USD'},
      {'date': '2025-03-16', 'amount': 1.71, 'currency': 'USD'},
      {'date': '2024-12-17', 'amount': 1.63, 'currency': 'USD'},
      {'date': '2024-09-15', 'amount': 1.63, 'currency': 'USD'},
    ],
    'JNJ': [
      {'date': '2024-12-10', 'amount': 1.19, 'currency': 'USD'},
      {'date': '2024-09-10', 'amount': 1.19, 'currency': 'USD'},
      {'date': '2024-06-11', 'amount': 1.19, 'currency': 'USD'},
      {'date': '2024-03-12', 'amount': 1.13, 'currency': 'USD'},
    ],
    'KO': [
      {'date': '2024-12-16', 'amount': 0.485, 'currency': 'USD'},
      {'date': '2024-09-16', 'amount': 0.485, 'currency': 'USD'},
      {'date': '2024-06-17', 'amount': 0.485, 'currency': 'USD'},
      {'date': '2024-03-15', 'amount': 0.46, 'currency': 'USD'},
    ],
    'JPM': [
      {'date': '2024-10-31', 'amount': 1.25, 'currency': 'USD'},
      {'date': '2024-07-31', 'amount': 1.25, 'currency': 'USD'},
      {'date': '2024-04-30', 'amount': 1.15, 'currency': 'USD'},
      {'date': '2024-01-31', 'amount': 1.15, 'currency': 'USD'},
    ],
    'VOO': [
      {'date': '2024-12-20', 'amount': 1.563, 'currency': 'USD'},
      {'date': '2024-09-20', 'amount': 1.441, 'currency': 'USD'},
      {'date': '2024-06-21', 'amount': 1.378, 'currency': 'USD'},
      {'date': '2024-03-22', 'amount': 1.357, 'currency': 'USD'},
    ],
    'QQQ': [
      {'date': '2024-12-20', 'amount': 0.708, 'currency': 'USD'},
      {'date': '2024-09-20', 'amount': 0.652, 'currency': 'USD'},
      {'date': '2024-06-21', 'amount': 0.595, 'currency': 'USD'},
      {'date': '2024-03-22', 'amount': 0.574, 'currency': 'USD'},
    ],
    'VNQ': [
      {'date': '2024-12-23', 'amount': 0.832, 'currency': 'USD'},
      {'date': '2024-09-24', 'amount': 0.814, 'currency': 'USD'},
      {'date': '2024-06-25', 'amount': 0.798, 'currency': 'USD'},
      {'date': '2024-03-26', 'amount': 0.769, 'currency': 'USD'},
    ],
  };

  /// Generar dividendos futuros realistas basados en datos históricos
  static List<DividendData> _generateFutureDividends(String symbol) {
    if (!_realisticDividendData.containsKey(symbol)) {
      return [];
    }

    final historicalData = _realisticDividendData[symbol]!;
    final List<DividendData> futureDividends = [];

    // Usar los últimos datos disponibles para proyectar futuros dividendos
    final latestData = historicalData.last;
    final latestDate = DateTime.parse(latestData['date']);
    final amount = latestData['amount'] as double;
    final currency = latestData['currency'] as String;

    // Generar próximos 4 dividendos (cada 3 meses)
    for (int i = 1; i <= 4; i++) {
      final dividendDate = DateTime(latestDate.year + (latestDate.month + i * 3 > 12 ? 1 : 0),
                                    (latestDate.month + i * 3 - 1) % 12 + 1,
                                    latestDate.day);
      futureDividends.add(DividendData(
        date: dividendDate,
        amount: amount,
        currency: currency,
        frequency: 'Quarterly',
      ));
    }

    return futureDividends;
  }
  /// Obtener dividendos con fallback a datos realistas
  static Future<DividendResult> getDividendsWithFallback(String symbol, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      // Primero intentar con la API real
      final apiDividends = await getDividends(symbol, from: from, to: to);
      
      if (apiDividends.isNotEmpty) {
        return DividendResult(dividends: apiDividends, isFromApi: true);
      }
      
      // Si la API no devuelve datos, usar fallback realista
      print('🔄 Using realistic fallback data for $symbol');
      final fallbackDividends = _generateFutureDividends(symbol);
      return DividendResult(dividends: fallbackDividends, isFromApi: false);
      
    } catch (e) {
      // En caso de error, usar fallback
      print('⚠️ API failed for $symbol, using fallback data');
      final fallbackDividends = _generateFutureDividends(symbol);
      return DividendResult(dividends: fallbackDividends, isFromApi: false);
    }
  }
}

/// Modelo de datos para dividendos
class DividendData {
  final DateTime date;
  final double amount;
  final String currency;
  final String frequency;
  final DateTime? exDividendDate;
  final DateTime? recordDate;

  DividendData({
    required this.date,
    required this.amount,
    required this.currency,
    required this.frequency,
    this.exDividendDate,
    this.recordDate,
  });

  factory DividendData.fromFinnhub(Map<String, dynamic> json) {
    return DividendData(
      date: DateTime.fromMillisecondsSinceEpoch((json['date'] as int) * 1000),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      frequency: json['frequency'] as String? ?? 'Quarterly',
      exDividendDate: json['exDividendDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch((json['exDividendDate'] as int) * 1000)
        : null,
      recordDate: json['recordDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch((json['recordDate'] as int) * 1000)
        : null,
    );
  }

  factory DividendData.fromRealistic(Map<String, dynamic> data, DateTime futureDate) {
    return DividendData(
      date: futureDate,
      amount: data['amount'] as double,
      currency: data['currency'] as String,
      frequency: 'Quarterly',
      exDividendDate: futureDate.subtract(Duration(days: 2)),
      recordDate: futureDate.subtract(Duration(days: 1)),
    );
  }
}

/// Modelo de datos para perfil de empresa
class CompanyProfile {
  final String name;
  final String logo;
  final String country;
  final String currency;
  final String exchange;
  final String ipo;
  final String weburl;

  CompanyProfile({
    required this.name,
    required this.logo,
    required this.country,
    required this.currency,
    required this.exchange,
    required this.ipo,
    required this.weburl,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      country: json['country'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      exchange: json['exchange'] as String? ?? '',
      ipo: json['ipo'] as String? ?? '',
      weburl: json['weburl'] as String? ?? '',
    );
  }
}

/// Modelo de datos para cotizaciones de acciones
class StockQuote {
  final double currentPrice;
  final double change;
  final double changePercent;
  final double highPrice;
  final double lowPrice;
  final double openPrice;
  final double previousClose;

  StockQuote({
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.openPrice,
    required this.previousClose,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      currentPrice: (json['c'] as num?)?.toDouble() ?? 0.0,
      change: (json['d'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['dp'] as num?)?.toDouble() ?? 0.0,
      highPrice: (json['h'] as num?)?.toDouble() ?? 0.0,
      lowPrice: (json['l'] as num?)?.toDouble() ?? 0.0,
      openPrice: (json['o'] as num?)?.toDouble() ?? 0.0,
      previousClose: (json['pc'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Clase para indicar si los dividendos vienen de la API o son fallback
class DividendResult {
  final List<DividendData> dividends;
  final bool isFromApi;

  DividendResult({
    required this.dividends,
    required this.isFromApi,
  });
}