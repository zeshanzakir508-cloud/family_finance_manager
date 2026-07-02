import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../providers/mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'USD';
  double _convertedAmount = 0;
  double _exchangeRate = 1.0;
  bool _showConversion = false;
  bool _isRecurring = false;
  String _recurringInterval = 'monthly';
  bool _isLoading = false;

  final List<String> _incomeCategories = Constants.incomeCategories;
  final List<String> _recurringIntervals = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
  }

  void _loadUserCurrency() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId != null) {
      final user = await DatabaseService.getUser(userId);
      if (user != null && user.currency != null) {
        setState(() => _selectedCurrency = user.currency!);
      }
    }
  }

  void _convertCurrency() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() {
        _showConversion = false;
        _convertedAmount = 0;
      });
      return;
    }

    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final baseCurrency = familyProvider.currentFamily?.baseCurrency ?? 'USD';

    if (_selectedCurrency == baseCurrency) {
      setState(() {
        _convertedAmount = amount;
        _exchangeRate = 1.0;
        _showConversion = true;
      });
      return;
    }

    try {
      final rate = await ExchangeRateService.getRate(_selectedCurrency, baseCurrency);
      setState(() {
        _convertedAmount = amount * rate;
        _exchangeRate = rate;
        _showConversion = true;
      });
    } catch (e) {
      setState(() {
        _convertedAmount = amount;
        _exchangeRate = 1.0;
        _showConversion = true;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      final modeProvider = Provider.of<ModeProvider>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);

      if (userId == null) throw Exception('User not logged in');

      final baseCurrency = modeProvider.isFamilyMode
          ? familyProvider.currentFamily?.baseCurrency ?? 'USD'
          : 'USD';

      final transaction = TransactionModel(
        id: Helpers.generateId(),
        userId: userId,
        amount: amount,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        type: 'income',
        date: _selectedDate,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        familyId: modeProvider.isFamilyMode ? familyProvider.currentFamily?.id : null,
        isFamilyTransaction: modeProvider.isFamilyMode,
        originalCurrency: _selectedCurrency,
        originalAmount: amount,
        baseCurrency: baseCurrency,
        amountInBaseCurrency: _convertedAmount,
        exchangeRateUsed: _exchangeRate,
        isRecurring: _isRecurring,
        recurringInterval: _isRecurring ? _recurringInterval : null,
      );

      await DatabaseService.saveTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final baseCurrency = familyProvider.currentFamily?.baseCurrency ?? 'USD';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Income'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: _selectedCurrency,
                ),
                onChanged: (_) => _convertCurrency(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Currency Selector
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  prefixIcon: Icon(Icons.currency_exchange),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['USD', 'PKR', 'SAR', 'BHD', 'AED', 'EUR', 'GBP', 'INR'].map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text('$currency (${_getCurrencySymbol(currency)})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCurrency = value!);
                  _convertCurrency();
                },
              ),
              const SizedBox(height: 8),

              // Conversion Preview
              if (_showConversion)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_amountController.text} $_selectedCurrency = ${_convertedAmount.toStringAsFixed(2)} $baseCurrency',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              'Rate: 1 $_selectedCurrency = ${_exchangeRate.toStringAsFixed(2)} $baseCurrency',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _incomeCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Recurring
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _isRecurring,
                          onChanged: (value) {
                            setState(() => _isRecurring = value);
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Text('Recurring Transaction'),
                      ],
                    ),
                    if (_isRecurring)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: DropdownButtonFormField<String>(
                          value: _recurringInterval,
                          decoration: const InputDecoration(
                            labelText: 'Repeat Every',
                            border: OutlineInputBorder(),
                          ),
                          items: _recurringIntervals.map((interval) {
                            return DropdownMenuItem(
                              value: interval,
                              child: Text(interval[0].toUpperCase() + interval.substring(1)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _recurringInterval = value!);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Income'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrencySymbol(String code) {
    const symbols = {
      'USD': '\$', 'PKR': 'Rs', 'SAR': '﷼', 'BHD': 'د.ب',
      'AED': 'د.إ', 'EUR': '€', 'GBP': '£', 'INR': '₹',
    };
    return symbols[code] ?? code;
  }
}
