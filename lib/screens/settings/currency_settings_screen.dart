// lib/screens/settings/currency_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/currency_model.dart';
// ✅ FIXED: Added missing import
import '../../services/currency_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({Key? key}) : super(key: key);

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String? _selectedCurrency;
  List<CurrencyModel> _currencies = [];
  List<CurrencyModel> _filteredCurrencies = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCurrencies() {
    final currencyProvider = context.read<CurrencyProvider>();
    _selectedCurrency = currencyProvider.currentCurrency;
    _currencies = currencyProvider.getCurrencyList();
    _filteredCurrencies = _currencies;
  }

  void _searchCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = _currencies;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCurrencies = _currencies.where((c) {
          return c.code.toLowerCase().contains(lowerQuery) ||
              c.name.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _saveCurrency() async {
    if (_selectedCurrency == null) {
      CustomSnackBar.show(
        context,
        'Please select a currency',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currencyProvider = context.read<CurrencyProvider>();
      await currencyProvider.setCurrency(_selectedCurrency!);
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Currency updated to ${_selectedCurrency!} successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to update currency: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCurrency,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchCurrencies('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchCurrencies,
            ),
          ),

          // Current currency
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    // ✅ FIXED: CurrencyService is now imported
                    CurrencyService.getSymbol(_selectedCurrency ?? 'PKR'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Currency',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _selectedCurrency ?? 'PKR',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  // ✅ FIXED: CurrencyService is now imported
                  CurrencyService.getName(_selectedCurrency ?? 'PKR'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Currency list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == _selectedCurrency;
                final isPopular = currency.isPopular;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : isDark
                            ? Colors.grey[800]
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : isDark
                              ? Colors.grey[700]!
                              : Colors.grey[200]!,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(
                      currency.symbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          currency.code,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blue : null,
                          ),
                        ),
                        if (isPopular) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Popular',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(currency.name),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency.code;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
