import '../models/currency_model.dart';

class CurrencyData {
  static final List<CurrencyModel> allCurrencies = [
    CurrencyModel(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    CurrencyModel(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    CurrencyModel(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    CurrencyModel(code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs', flag: '🇵🇰'),
    CurrencyModel(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
    CurrencyModel(code: 'BHD', name: 'Bahraini Dinar', symbol: 'د.ب', flag: '🇧🇭'),
    CurrencyModel(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    CurrencyModel(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    CurrencyModel(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
    CurrencyModel(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
  ];

  static CurrencyModel? getByCode(String code) {
    try {
      return allCurrencies.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }
}
