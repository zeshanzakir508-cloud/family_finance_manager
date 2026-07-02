import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ExchangeRateService {
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';
  static const String _cacheKey = 'cached_exchange_rates';
  static const String _lastUpdateKey = 'last_rate_update';
  static const Duration _cacheValidity = Duration(days: 7);

  static Map<String, double>? _cachedRates;
  static DateTime? _lastUpdateTime;
  static bool _isOnline = true;

  static Future<double> getRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    if (await _isConnected()) {
      try {
        final rates = await _fetchRates();
        _cachedRates = rates;
        _lastUpdateTime = DateTime.now();
        _isOnline = true;
        await _saveRatesToCache(rates);
        return _getRateFromRates(rates, fromCurrency, toCurrency);
      } catch (e) {
        _isOnline = false;
      }
    }

    return _getOfflineRate(fromCurrency, toCurrency);
  }

  static Future<double> convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return amount;
    final rate = await getRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  static Future<Map<String, double>> fetchAllRates() async {
    if (!await _isConnected()) {
      return _cachedRates ?? {};
    }
    return await _fetchRates();
  }

  static double _getOfflineRate(String fromCurrency, String toCurrency) {
    if (_cachedRates != null) {
      return _getRateFromRates(_cachedRates!, fromCurrency, toCurrency);
    }

    final cached = _loadRatesFromCache();
    if (cached != null) {
      _cachedRates = cached;
      return _getRateFromRates(cached, fromCurrency, toCurrency);
    }

    return _getFallbackRate(fromCurrency, toCurrency);
  }

  static double _getRateFromRates(
    Map<String, double> rates,
    String fromCurrency,
    String toCurrency,
  ) {
    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;
    return toRate / fromRate;
  }

  static double _getFallbackRate(String fromCurrency, String toCurrency) {
    const fallback = {
      'USD': 1.0, 'PKR': 278.0, 'SAR': 3.75, 'BHD': 0.376,
      'EUR': 0.85, 'GBP': 0.73, 'INR': 83.0, 'AED': 3.67,
    };
    
    final fromRate = fallback[fromCurrency] ?? 1.0;
    final toRate = fallback[toCurrency] ?? 1.0;
    return toRate / fromRate;
  }

  static Future<Map<String, double>> _fetchRates() async {
    final response = await http.get(
      Uri.parse(_apiUrl),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, double>.from(data['rates']);
    } else {
      throw Exception('Failed to fetch rates');
    }
  }

  static Future<void> _saveRatesToCache(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(rates);
    await prefs.setString(_cacheKey, json);
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  // ✅ FIXED: Added await
  static Map<String, double>? _loadRatesFromCache() {
    try {
      final prefs = SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json == null) return null;
      return Map<String, double>.from(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  static bool get isOnline => _isOnline;

  static Future<bool> get areRatesFresh async {
    if (_lastUpdateTime == null) {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      if (lastUpdate != null) {
        _lastUpdateTime = DateTime.parse(lastUpdate);
      }
    }
    if (_lastUpdateTime == null) return false;
    final diff = DateTime.now().difference(_lastUpdateTime!);
    return diff < _cacheValidity;
  }

  static DateTime? get lastUpdateTime => _lastUpdateTime;

  static Future<void> forceRefresh() async {
    if (await _isConnected()) {
      try {
        final rates = await _fetchRates();
        _cachedRates = rates;
        _lastUpdateTime = DateTime.now();
        _isOnline = true;
        await _saveRatesToCache(rates);
      } catch (e) {
        _isOnline = false;
        throw Exception('Failed to refresh rates');
      }
    } else {
      throw Exception('No internet connection');
    }
  }

  static Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static String getCurrencySymbol(String code) {
    const symbols = {
      'USD': '\$', 'PKR': 'Rs', 'SAR': '﷼', 'BHD': 'د.ب',
      'EUR': '€', 'GBP': '£', 'INR': '₹', 'AED': 'د.إ',
    };
    return symbols[code] ?? code;
  }
}
