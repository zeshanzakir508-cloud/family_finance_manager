import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/exchange_rate_service.dart';
import '../../data/currency_data.dart';
import '../../models/currency_model.dart';
import '../../utils/app_theme.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _selectedCurrency = 'USD';
  List<String> _favorites = [];
  List<String> _recentlyUsed = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('display_currency') ?? 'USD';
      _favorites = prefs.getStringList('currency_favorites') ?? ['PKR', 'SAR', 'BHD'];
      _recentlyUsed = prefs.getStringList('recently_used_currencies') ?? [];
    });
  }

  Future<void> _saveCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_currency', code);
    
    // Update recently used
    List<String> recent = _recentlyUsed;
    recent.remove(code);
    recent.insert(0, code);
    if (recent.length > 5) recent = recent.sublist(0, 5);
    await prefs.setStringList('recently_used_currencies', recent);
    
    setState(() {
      _selectedCurrency = code;
      _recentlyUsed = recent;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Currency updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _toggleFavorite(String code) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = List.from(_favorites);
    
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }
    
    await prefs.setStringList('currency_favorites', favorites);
    
    setState(() {
      _favorites = favorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = CurrencyData.allCurrencies
        .where((c) => c.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final favoriteCurrencies = filteredCurrencies
        .where((c) => _favorites.contains(c.code))
        .toList();

    final recentCurrencies = filteredCurrencies
        .where((c) => _recentlyUsed.contains(c.code) && !_favorites.contains(c.code))
        .toList();

    final otherCurrencies = filteredCurrencies
        .where((c) => !_favorites.contains(c.code) && !_recentlyUsed.contains(c.code))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Currency Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
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
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Currency List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Current Selected
                _buildSectionHeader('Current Currency'),
                _buildCurrencyTile(
                  CurrencyData.getByCode(_selectedCurrency)!,
                  isSelected: true,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                
                // Favorites
                if (favoriteCurrencies.isNotEmpty) ...[
                  _buildSectionHeader('⭐ Favorites'),
                  ...favoriteCurrencies.map((c) => _buildCurrencyTile(
                    c,
                    isFavorite: true,
                    isSelected: c.code == _selectedCurrency,
                    onTap: () => _saveCurrency(c.code),
                    onFavoriteTap: () => _toggleFavorite(c.code),
                  )),
                  const SizedBox(height: 8),
                ],
                
                // Recently Used
                if (recentCurrencies.isNotEmpty) ...[
                  _buildSectionHeader('📌 Recently Used'),
                  ...recentCurrencies.map((c) => _buildCurrencyTile(
                    c,
                    isSelected: c.code == _selectedCurrency,
                    onTap: () => _saveCurrency(c.code),
                    onFavoriteTap: () => _toggleFavorite(c.code),
                  )),
                  const SizedBox(height: 8),
                ],
                
                // All Currencies
                _buildSectionHeader('🌍 All Currencies'),
                ...otherCurrencies.map((c) => _buildCurrencyTile(
                  c,
                  isSelected: c.code == _selectedCurrency,
                  onTap: () => _saveCurrency(c.code),
                  onFavoriteTap: () => _toggleFavorite(c.code),
                )),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(
    CurrencyModel currency, {
    bool isSelected = false,
    bool isFavorite = false,
    required VoidCallback onTap,
    VoidCallback? onFavoriteTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 0,
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
      child: ListTile(
        leading: Text(
          currency.flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          '${currency.code} - ${currency.name}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Text(currency.symbol),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 20,
              ),
              onPressed: onFavoriteTap,
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
