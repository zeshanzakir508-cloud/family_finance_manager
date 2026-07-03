// lib/screens/settings/currency_settings_screen.dart
import 'dart:async';  // <-- ADD THIS IMPORT
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
  String _initialCurrency = 'USD';
  List<String> _favorites = [];
  List<String> _recentlyUsed = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasChanges = false;

  // Debounce
  Timer? _debounceTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debounceAction(VoidCallback action) {
    if (_isProcessing) return;
    _debounceTimer?.cancel();
    _isProcessing = true;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      action();
      _isProcessing = false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('display_currency') ?? 'USD';
      _initialCurrency = _selectedCurrency;
      _favorites = prefs.getStringList('currency_favorites') ?? ['PKR', 'SAR', 'BHD'];
      _recentlyUsed = prefs.getStringList('recently_used_currencies') ?? [];
      _hasChanges = false;
    });
  }

  void _selectCurrency(String code) {
    _debounceAction(() {
      setState(() {
        _selectedCurrency = code;
        _hasChanges = _selectedCurrency != _initialCurrency;
      });
    });
  }

  Future<void> _saveCurrency() async {
    _debounceAction(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('display_currency', _selectedCurrency);
      
      // Update recently used
      List<String> recent = List.from(_recentlyUsed);
      recent.remove(_selectedCurrency);
      recent.insert(0, _selectedCurrency);
      if (recent.length > 5) recent = recent.sublist(0, 5);
      await prefs.setStringList('recently_used_currencies', recent);
      
      setState(() {
        _initialCurrency = _selectedCurrency;
        _recentlyUsed = recent;
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Currency updated to ${_selectedCurrency}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context, _selectedCurrency);
    });
  }

  void _cancelChanges() {
    _debounceAction(() {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Currency changes discarded'),
                      backgroundColor: Colors.grey,
                    ),
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
    });
  }

  Future<void> _toggleFavorite(String code) async {
    _debounceAction(() async {
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
          if (_hasChanges)
            TextButton(
              onPressed: _saveCurrency,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
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
                    onTap: () => _selectCurrency(c.code),
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
                    onTap: () => _selectCurrency(c.code),
                    onFavoriteTap: () => _toggleFavorite(c.code),
                  )),
                  const SizedBox(height: 8),
                ],
                
                // All Currencies
                _buildSectionHeader('🌍 All Currencies'),
                ...otherCurrencies.map((c) => _buildCurrencyTile(
                  c,
                  isSelected: c.code == _selectedCurrency,
                  onTap: () => _selectCurrency(c.code),
                  onFavoriteTap: () => _toggleFavorite(c.code),
                )),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Bottom Buttons
          _buildBottomButtons(),
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
    final isInitial = _initialCurrency == currency.code;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected 
              ? AppTheme.primaryColor 
              : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected 
          ? AppTheme.primaryColor.withOpacity(0.05) 
          : Colors.white,
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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            if (!isSelected && isInitial && !_hasChanges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
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
