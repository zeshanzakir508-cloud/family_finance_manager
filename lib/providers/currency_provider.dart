// lib/providers/currency_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/currency_service.dart';
import '../models/currency_model.dart';

class CurrencyProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  String _currentCurrency = 'PKR';
  Map<String, double> _exchangeRates = {};
  bool _isLoading = false;
  DateTime? _lastUpdate;

  CurrencyProvider(this._prefs) {
    _loadCurrency();
    _loadExchangeRates();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  String get currentCurrency => _currentCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;

  String get currencySymbol => CurrencyService.getSymbol(_currentCurrency);
  String get currencyName => CurrencyService.getName(_currentCurrency);

  // ============================================================
  // LOAD & SAVE
  // ============================================================

  void _loadCurrency() {
    _currentCurrency = _prefs.getString('selected_currency') ?? 'PKR';
    notifyListeners();
  }

  Future<void> _saveCurrency() async {
    await _prefs.setString('selected_currency', _currentCurrency);
  }

  Future<void> _loadExchangeRates() async {
    try {
      _isLoading = true;
      notifyListeners();

      _exchangeRates = await CurrencyService.getExchangeRates();
      _lastUpdate = DateTime.now();
      
      // Cache in SharedPreferences
      await _prefs.setString('exchange_rates', _exchangeRates.toString());
      await _prefs.setString('exchange_rates_last_update', _lastUpdate!.toIso8601String());
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Try to load cached rates
      final cached = _prefs.getString('exchange_rates');
      if (cached != null) {
        try {
          // Parse cached rates
          final cleaned = cached.replaceAll('{', '').replaceAll('}', '');
          final pairs = cleaned.split(', ');
          _exchangeRates = {};
          for (var pair in pairs) {
            final parts = pair.split(': ');
            if (parts.length == 2) {
              _exchangeRates[parts[0]] = double.tryParse(parts[1]) ?? 1.0;
            }
          }
        } catch (_) {
          _exchangeRates = {};
        }
      }
      
      final cachedDate = _prefs.getString('exchange_rates_last_update');
      if (cachedDate != null) {
        _lastUpdate = DateTime.tryParse(cachedDate);
      }
      
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CURRENCY METHODS
  // ============================================================

  Future<void> setCurrency(String currencyCode) async {
    if (_currentCurrency == currencyCode) return;
    
    _currentCurrency = currencyCode;
    await _saveCurrency();
    
    // Refresh exchange rates with new base
    _exchangeRates = await CurrencyService.getExchangeRates(base: currencyCode);
    _lastUpdate = DateTime.now();
    
    notifyListeners();
  }

  Future<void> refreshExchangeRates() async {
    await _loadExchangeRates();
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String formatAmount(double amount, {int decimalPlaces = 2}) {
    return CurrencyService.formatAmountSync(
      amount,
      currencyCode: _currentCurrency,
      decimalPlaces: decimalPlaces,
    );
  }

  String formatAmountWithCode(double amount, {int decimalPlaces = 2}) {
    final symbol = currencySymbol;
    final code = _currentCurrency;
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$symbol $formatted $code';
  }

  // ============================================================
  // CONVERSION
  // ============================================================

  double convertToCurrency(double amount, String fromCurrency) {
    if (fromCurrency == _currentCurrency) return amount;
    
    final rate = _exchangeRates[_currentCurrency] ?? 1.0;
    if (rate == 0) return amount;
    
    return amount / rate;
  }

  double convertFromCurrency(double amount, String toCurrency) {
    if (toCurrency == _currentCurrency) return amount;
    
    final rate = _exchangeRates[_currentCurrency] ?? 1.0;
    if (rate == 0) return amount;
    
    return amount * rate;
  }

  double convertBetween(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final fromRate = _exchangeRates[fromCurrency] ?? 1.0;
    final toRate = _exchangeRates[toCurrency] ?? 1.0;
    
    if (fromRate == 0 || toRate == 0) return amount;
    
    return (amount / fromRate) * toRate;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String getSymbolForCode(String code) {
    return CurrencyService.getSymbol(code);
  }

  String getNameForCode(String code) {
    return CurrencyService.getName(code);
  }

  List<CurrencyModel> getCurrencyList() {
    return CurrencyService.getCurrencyList();
  }

  List<String> getPopularCurrencies() {
    return CurrencyService.getPopularCurrencies();
  }

  bool isPopularCurrency(String code) {
    return CurrencyService.getPopularCurrencies().contains(code);
  }

  List<String> searchCurrencies(String query) {
    return CurrencyService.getAvailableCurrencies()
        .where((code) =>
            code.toLowerCase().contains(query.toLowerCase()) ||
            CurrencyService.getName(code).toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Map<String, dynamic> getCurrencyInfo() {
    return {
      'code': _currentCurrency,
      'symbol': currencySymbol,
      'name': currencyName,
      'isPopular': isPopularCurrency(_currentCurrency),
      'lastUpdate': _lastUpdate,
      'ratesCount': _exchangeRates.length,
    };
  }

  bool get hasExchangeRates => _exchangeRates.isNotEmpty;
}
