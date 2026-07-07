// lib/services/currency_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/currency_model.dart';

class CurrencyService {
  static const String _prefKey = 'selected_currency';
  static const String _prefRateKey = 'exchange_rates';
  static const String _prefLastUpdateKey = 'exchange_rates_last_update';
  
  static const Map<String, String> _symbols = {
    'USD': '\$',
    'PKR': 'Rs',
    'SAR': '﷼',
    'BHD': '.د.ب',
    'AED': 'د.إ',
    'GBP': '£',
    'EUR': '€',
    'INR': '₹',
    'CAD': 'CA\$',
    'AUD': 'AU\$',
    'JPY': '¥',
    'CNY': '¥',
    'CHF': 'Fr',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'ZAR': 'R',
    'NZD': 'NZ\$',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'KRW': '₩',
    'TRY': '₺',
    'RUB': '₽',
    'BRL': 'R\$',
    'MXN': '\$',
    'PHP': '₱',
    'IDR': 'Rp',
    'MYR': 'RM',
    'THB': '฿',
    'VND': '₫',
  };

  static const Map<String, String> _names = {
    'USD': 'US Dollar',
    'PKR': 'Pakistani Rupee',
    'SAR': 'Saudi Riyal',
    'BHD': 'Bahraini Dinar',
    'AED': 'UAE Dirham',
    'GBP': 'British Pound',
    'EUR': 'Euro',
    'INR': 'Indian Rupee',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'CHF': 'Swiss Franc',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'ZAR': 'South African Rand',
    'NZD': 'New Zealand Dollar',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'KRW': 'South Korean Won',
    'TRY': 'Turkish Lira',
    'RUB': 'Russian Ruble',
    'BRL': 'Brazilian Real',
    'MXN': 'Mexican Peso',
    'PHP': 'Philippine Peso',
    'IDR': 'Indonesian Rupiah',
    'MYR': 'Malaysian Ringgit',
    'THB': 'Thai Baht',
    'VND': 'Vietnamese Dong',
  };

  static const List<String> _popularCurrencies = ['PKR', 'USD', 'SAR', 'AED', 'GBP', 'EUR'];

  // ============================================================
  // GETTERS
  // ============================================================

  static String getSymbol(String code) {
    return _symbols[code] ?? code;
  }

  static String getName(String code) {
    return _names[code] ?? code;
  }

  static List<String> getAvailableCurrencies() {
    return _symbols.keys.toList();
  }

  static List<String> getPopularCurrencies() {
    return _popularCurrencies;
  }

  static List<CurrencyModel> getCurrencyList() {
    return _symbols.keys.map((code) {
      return CurrencyModel(
        code: code,
        name: _names[code] ?? code,
        symbol: _symbols[code] ?? code,
        isPopular: _popularCurrencies.contains(code),
      );
    }).toList();
  }

  // ============================================================
  // PERSISTENCE
  // ============================================================

  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? 'PKR';
  }

  static Future<void> setSelectedCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, currencyCode);
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  static Future<String> formatAmount(
    double amount, {
    String? currencyCode,
    int decimalPlaces = 2,
    bool showSymbol = true,
  }) async {
    final code = currencyCode ?? await getSelectedCurrency();
    final symbol = showSymbol ? getSymbol(code) : code;
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$symbol $formatted';
  }

  static String formatAmountSync(
    double amount, {
    String currencyCode = 'PKR',
    int decimalPlaces = 2,
    bool showSymbol = true,
  }) {
    final symbol = showSymbol ? getSymbol(currencyCode) : currencyCode;
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$symbol $formatted';
  }

  static Future<String> formatAmountWithCurrency(
    double amount, {
    String? currencyCode,
    int decimalPlaces = 2,
  }) async {
    final code = currencyCode ?? await getSelectedCurrency();
    final symbol = getSymbol(code);
    final name = getName(code);
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$symbol $formatted $name';
  }

  // ============================================================
  // EXCHANGE RATES
  // ============================================================

  static Future<Map<String, double>> getExchangeRates({String base = 'USD'}) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$base'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(data['rates']);
        
        // Cache rates
        await _cacheRates(rates);
        return rates;
      }
      
      // Fallback to cached rates
      return await _getCachedRates();
    } catch (e) {
      print('Error fetching exchange rates: $e');
      return await _getCachedRates() ?? {};
    }
  }

  static Future<double> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return amount;

    final rates = await getExchangeRates(base: fromCurrency);
    final rate = rates[toCurrency];

    if (rate == null) return amount;
    return amount * rate;
  }

  static Future<Map<String, double>> _getCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefRateKey);
      if (cached == null) return {};
      
      final data = json.decode(cached);
      return Map<String, double>.from(data);
    } catch (e) {
      return {};
    }
  }

  static Future<void> _cacheRates(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefRateKey, json.encode(rates));
      await prefs.setString(_prefLastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching rates: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static Future<bool> isCurrencySupported(String code) async {
    return _symbols.containsKey(code);
  }

  static Future<Map<String, String>> getCurrencyDisplayInfo() async {
    final current = await getSelectedCurrency();
    return {
      'code': current,
      'symbol': getSymbol(current),
      'name': getName(current),
    };
  }

  static Future<String> getFormattedBalance(double amount) async {
    final currency = await getSelectedCurrency();
    return formatAmountSync(amount, currencyCode: currency);
  }

  static Future<String> getCurrencySymbolForCode(String code) async {
    return _symbols[code] ?? code;
  }

  static Future<List<String>> searchCurrencies(String query) async {
    if (query.isEmpty) return _popularCurrencies;
    
    final lowercaseQuery = query.toLowerCase();
    return _symbols.keys.where((code) {
      return code.toLowerCase().contains(lowercaseQuery) ||
          (_names[code]?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  static Future<bool> isPopularCurrency(String code) async {
    return _popularCurrencies.contains(code);
  }

  static Future<String> getDefaultCurrencyByCountry(String countryCode) async {
    // Map country codes to currency codes
    final countryCurrencyMap = {
      'PK': 'PKR',
      'US': 'USD',
      'SA': 'SAR',
      'AE': 'AED',
      'GB': 'GBP',
      'DE': 'EUR',
      'FR': 'EUR',
      'IN': 'INR',
      'CA': 'CAD',
      'AU': 'AUD',
      'JP': 'JPY',
      'CN': 'CNY',
      'CH': 'CHF',
      'SE': 'SEK',
      'NO': 'NOK',
      'DK': 'DKK',
      'ZA': 'ZAR',
      'NZ': 'NZD',
      'SG': 'SGD',
      'HK': 'HKD',
      'KR': 'KRW',
      'TR': 'TRY',
      'RU': 'RUB',
      'BR': 'BRL',
      'MX': 'MXN',
      'PH': 'PHP',
      'ID': 'IDR',
      'MY': 'MYR',
      'TH': 'THB',
      'VN': 'VND',
    };
    
    return countryCurrencyMap[countryCode] ?? 'USD';
  }
}
