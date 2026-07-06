// lib/screens/settings/currency_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _selectedCurrency = 'USD';
  String _initialCurrency = 'USD';
  bool _hasChanges = false;
  String _searchQuery = '';

  final List<Map<String, String>> _allCurrencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': 'Rs', 'flag': '🇵🇰'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ', 'flag': '🇦🇪'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼', 'flag': '🇸🇦'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩', 'flag': '🇰🇷'},
    {'code': 'BHD', 'name': 'Bahraini Dinar', 'symbol': 'BD', 'flag': '🇧🇭'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar', 'symbol': 'KD', 'flag': '🇰🇼'},
    {'code': 'OMR', 'name': 'Omani Rial', 'symbol': 'RO', 'flag': '🇴🇲'},
    {'code': 'QAR', 'name': 'Qatari Riyal', 'symbol': '﷼', 'flag': '🇶🇦'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'E£', 'flag': '🇪🇬'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺', 'flag': '🇹🇷'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽', 'flag': '🇷🇺'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$', 'flag': '🇧🇷'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R', 'flag': '🇿🇦'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱', 'flag': '🇵🇭'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'flag': '🇮🇩'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿', 'flag': '🇹🇭'},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'symbol': '₫', 'flag': '🇻🇳'},
  ];

  List<Map<String, String>> get _favoriteCurrencies {
    return _allCurrencies.where((c) => 
      c['code'] == 'USD' || c['code'] == 'PKR' || c['code'] == 'EUR' || 
      c['code'] == 'GBP' || c['code'] == 'AED' || c['code'] == 'SAR'
    ).toList();
  }

  List<Map<String, String>> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return _allCurrencies;
    return _allCurrencies.where((c) =>
      c['code']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c['name']!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString('currency') ?? 'USD';
    setState(() {
      _selectedCurrency = currency;
      _initialCurrency = currency;
      _hasChanges = false;
    });
  }

  void _selectCurrency(String code) {
    setState(() {
      _selectedCurrency = code;
      _hasChanges = _selectedCurrency != _initialCurrency;
    });
  }

  Future<void> _saveCurrency() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _selectedCurrency);
    await Helpers.setCurrency(_selectedCurrency);
    
    setState(() => _hasChanges = false);
    
    Helpers.showSnackBar(
      context,
      'Currency updated to $_selectedCurrency',
      color: Colors.green,
    );
    
    Navigator.pop(context, _selectedCurrency);
  }

  void _cancelChanges() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved currency changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedCurrency = _initialCurrency;
                  _hasChanges = false;
                });
                Helpers.showSnackBar(
                  context,
                  'Currency changes discarded',
                  color: Colors.grey,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Currency Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveCurrency,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                // Current Currency
                _buildSectionHeader('Current Currency'),
                _buildCurrencyTile(
                  currency: _allCurrencies.firstWhere(
                    (c) => c['code'] == _selectedCurrency,
                    orElse: () => {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
                  ),
                  isSelected: true,
                  showCheck: true,
                ),
                const SizedBox(height: 8),

                // Favorites
                _buildSectionHeader('Favorites'),
                ..._favoriteCurrencies.map((currency) =>
                  _buildCurrencyTile(
                    currency: currency,
                    isSelected: _selectedCurrency == currency['code'],
                    onTap: () => _selectCurrency(currency['code']!),
                  ),
                ),
                const SizedBox(height: 8),

                // All Currencies
                _buildSectionHeader('All Currencies'),
                ..._filteredCurrencies.map((currency) =>
                  _buildCurrencyTile(
                    currency: currency,
                    isSelected: _selectedCurrency == currency['code'],
                    onTap: () => _selectCurrency(currency['code']!),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCurrencyTile({
    required Map<String, String> currency,
    bool isSelected = false,
    VoidCallback? onTap,
    bool showCheck = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Text(
          currency['flag'] ?? '🌍',
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          '${currency['code']} - ${currency['name']}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Text(
          currency['symbol'] ?? '',
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
          ),
        ),
        trailing: showCheck || isSelected
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            : null,
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelChanges,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _hasChanges ? _saveCurrency : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasChanges 
                    ? AppTheme.primaryColor 
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_hasChanges ? 'Save Changes' : 'No Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
