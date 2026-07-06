// lib/utils/helpers.dart
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Helpers {
  static String? _cachedCurrency;
  static bool _isInitialized = false;

  /// ✅ Initialize currency once
  static Future<void> initCurrency() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCurrency = prefs.getString('currency') ?? 'USD';
      _isInitialized = true;
    } catch (e) {
      _cachedCurrency = 'USD';
      _isInitialized = true;
    }
  }

  /// ✅ Get current currency with caching
  static Future<String> getCurrentCurrency() async {
    if (_cachedCurrency != null) return _cachedCurrency!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCurrency = prefs.getString('currency') ?? 'USD';
      return _cachedCurrency!;
    } catch (e) {
      return 'USD';
    }
  }

  /// ✅ Get currency synchronously (after init)
  static String getCurrencySync() {
    return _cachedCurrency ?? 'USD';
  }

  /// ✅ Set currency and update cache
  static Future<void> setCurrency(String currencyCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', currencyCode);
      _cachedCurrency = currencyCode;
    } catch (e) {
      print('❌ Failed to save currency: $e');
    }
  }

  /// ✅ Format currency with dynamic symbol (FIXED)
  static String formatCurrency(double amount, {String? currencyCode}) {
    final code = currencyCode ?? _cachedCurrency ?? 'USD';
    final symbol = getCurrencySymbol(code);
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '$symbol$formatted';
  }

  /// ✅ Async version
  static Future<String> formatCurrencyAsync(double amount, {String? currencyCode}) async {
    final code = currencyCode ?? await getCurrentCurrency();
    final symbol = getCurrencySymbol(code);
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '$symbol$formatted';
  }

  /// ✅ Format with currency code
  static String formatCurrencyWithCode(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '$symbol$formatted $currencyCode';
  }

  // ============================================================
  // DATE FORMATTERS
  // ============================================================

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  // ============================================================
  // ID GENERATORS
  // ============================================================

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(6, (index) {
        final charIndex = (random + index * 7) % chars.length;
        return chars.codeUnitAt(charIndex);
      }),
    );
  }

  // ============================================================
  // VALIDATORS
  // ============================================================

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,15}$').hasMatch(phone);
  }

  static bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  // ============================================================
  // STRING HELPERS
  // ============================================================

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0][0].toUpperCase();
  }

  // ============================================================
  // MATH HELPERS
  // ============================================================

  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  static String formatWithCommas(double number) {
    return NumberFormat('#,##0.00').format(number);
  }

  // ============================================================
  // CURRENCY SYMBOLS
  // ============================================================

  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'PKR': return 'Rs';
      case 'INR': return '₹';
      case 'AED': return 'د.إ';
      case 'SAR': return '﷼';
      case 'CAD': return 'C\$';
      case 'AUD': return 'A\$';
      case 'JPY': return '¥';
      case 'CNY': return '¥';
      case 'KRW': return '₩';
      case 'BHD': return 'BD';
      case 'KWD': return 'KD';
      case 'OMR': return 'RO';
      case 'QAR': return '﷼';
      case 'EGP': return 'E£';
      case 'TRY': return '₺';
      case 'RUB': return '₽';
      case 'BRL': return 'R\$';
      case 'ZAR': return 'R';
      case 'SGD': return 'S\$';
      case 'MYR': return 'RM';
      case 'PHP': return '₱';
      case 'IDR': return 'Rp';
      case 'THB': return '฿';
      case 'VND': return '₫';
      default: return '\$';
    }
  }

  static String getCurrencyName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD': return 'US Dollar';
      case 'EUR': return 'Euro';
      case 'GBP': return 'British Pound';
      case 'PKR': return 'Pakistani Rupee';
      case 'INR': return 'Indian Rupee';
      case 'AED': return 'UAE Dirham';
      case 'SAR': return 'Saudi Riyal';
      case 'CAD': return 'Canadian Dollar';
      case 'AUD': return 'Australian Dollar';
      case 'JPY': return 'Japanese Yen';
      default: return currencyCode;
    }
  }
}
