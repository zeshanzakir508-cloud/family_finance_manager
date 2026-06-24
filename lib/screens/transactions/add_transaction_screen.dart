import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/transaction_model.dart';
import '../../models/user_profile.dart';
import '../../utils/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String? _selectedRecurrence;
  String? _selectedPaymentMethod;
  String? _selectedLocation;
  bool _isLoading = false;

  final List<String> _incomeCategories = [
    'salary',
    'investment',
    'gift',
    'rental',
    'business',
    'freelance',
    'other_income',
  ];

  final List<String> _expenseCategories = [
    'food',
    'transport',
    'shopping',
    'entertainment',
    'utilities',
    'rent',
    'healthcare',
    'education',
    'travel',
    'insurance',
    'groceries',
    'dining',
    'clothing',
    'electronics',
    'other_expense',
  ];

  final List<String> _recurrenceOptions = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> _paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Digital Wallet', 'Other'];
  final List<String> _locations = ['Home', 'Office', 'Store', 'Restaurant', 'Other'];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveTransaction(userId),
            child: Text(
              'Save',
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Toggle
                  _buildTypeToggle(),
                  const SizedBox(height: 24),

                  // Amount
                  _buildAmountField(),
                  const SizedBox(height: 16),

                  // Category
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Description
                  _buildDescriptionField(),
                  const SizedBox(height: 16),

                  // Date
                  _buildDatePicker(),
                  const SizedBox(height: 16),

                  // Payment Method
                  _buildPaymentMethodDropdown(),
                  const SizedBox(height: 16),

                  // Location
                  _buildLocationDropdown(),
                  const SizedBox(height: 16),

                  // Notes
                  _buildNotesField(),
                  const SizedBox(height: 16),

                  // Recurring
                  _buildRecurringToggle(),
                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    _buildRecurrenceDropdown(),
                  ],
                  const SizedBox(height: 24),

                  // Save Button
                  _buildSaveButton(userId),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = TransactionType.expense;
                  _selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.expense
                      ? Colors.red.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: _selectedType == TransactionType.expense
                          ? Colors.red
                          : AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expense',
                      style: AppTheme.bodyStyle.copyWith(
                        color: _selectedType == TransactionType.expense
                            ? Colors.red
                            : AppTheme.textSecondaryColor,
                        fontWeight: _selectedType == TransactionType.expense
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = TransactionType.income;
                  _selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.income
                      ? Colors.green.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: _selectedType == TransactionType.income
                          ? Colors.green
                          : AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Income',
                      style: AppTheme.bodyStyle.copyWith(
                        color: _selectedType == TransactionType.income
                            ? Colors.green
                            : AppTheme.textSecondaryColor,
                        fontWeight: _selectedType == TransactionType.income
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount *',
        hintText: '0.00',
        prefixText: '\$ ',
        prefixStyle: AppTheme.bodyStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      style: AppTheme.headingStyle.copyWith(fontSize: 24),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _selectedType == TransactionType.income
        ? _incomeCategories
        : _expenseCategories;
    
    final displayNames = categories.map((cat) {
      return cat.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
    }).toList();

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
        hintText: 'Select a category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      items: List.generate(categories.length, (index) {
        return DropdownMenuItem<String>(
          value: categories[index],
          child: Text(displayNames[index]),
        );
      }),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description *',
        hintText: 'What was this transaction for?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.surfaceColor,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: AppTheme.bodyStyle,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        hintText: 'Select payment method',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      decoration: InputDecoration(
        labelText: 'Location',
        hintText: 'Select location',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      items: _locations.map((location) {
        return DropdownMenuItem<String>(
          value: location,
          child: Text(location),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedLocation = value;
        });
      },
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional notes',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return Row(
      children: [
        Switch(
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
              if (!value) {
                _selectedRecurrence = null;
              }
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        Text(
          'Recurring Transaction',
          style: AppTheme.bodyStyle,
        ),
      ],
    );
  }

  Widget _buildRecurrenceDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRecurrence,
      decoration: InputDecoration(
        labelText: 'Recurrence Frequency *',
        hintText: 'How often?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      items: _recurrenceOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option.toLowerCase(),
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRecurrence = value;
        });
      },
    );
  }

  Widget _buildSaveButton(String? userId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _saveTransaction(userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedType == TransactionType.income
              ? Colors.green
              : Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Add ${_selectedType == TransactionType.income ? 'Income' : 'Expense'}',
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction(String? userId) async {
    // Validate
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isRecurring && _selectedRecurrence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recurrence frequency'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        type: _selectedType,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        isRecurring: _isRecurring,
        recurrenceFrequency: _selectedRecurrence,
        paymentMethod: _selectedPaymentMethod,
        location: _selectedLocation,
        createdAt: DateTime.now(),
        isSynced: false,
        currency: 'USD',
      );

      final box = Hive.box<TransactionModel>('transactions');
      await box.add(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedType == TransactionType.income ? 'Income' : 'Expense'} added successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
