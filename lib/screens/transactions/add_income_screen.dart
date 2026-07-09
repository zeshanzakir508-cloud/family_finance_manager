// lib/screens/transactions/add_income_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/mode_provider.dart';
import '../../models/transaction_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/category_picker.dart';
import 'widgets/amount_input.dart';
import 'widgets/date_time_picker.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({Key? key}) : super(key: key);

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _amount = 0.0;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final auth = context.read<AuthProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    
    if (auth.isAuthenticated) {
      await categoryProvider.loadCategories(auth.userId);
      
      // Set default category
      final incomeCategories = categoryProvider.incomeCategories;
      if (incomeCategories.isNotEmpty) {
        setState(() {
          _selectedCategory = incomeCategories.first.id;
        });
      }
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      CustomSnackBar.show(
        context,
        'Please select a category',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final mode = context.read<ModeProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      
      final category = categoryProvider.getCategoryById(_selectedCategory!);
      
      final transaction = TransactionModel(
        id: '',
        userId: auth.userId,
        familyId: mode.isFamilyMode ? auth.user?.familyId : null,
        amount: _amount,
        category: category?.name ?? 'Income',
        description: _descriptionController.text.trim(),
        type: 'income',
        date: _selectedDate,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        isFamilyTransaction: mode.isFamilyMode,
      );

      final success = await transactionProvider.addTransaction(transaction);
      
      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Income added successfully! 💰',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to add income: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveIncome,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount - ✅ FIXED: Changed onChanged to onAmountChanged
              AmountInput(
                label: 'Amount',
                currency: currencyProvider.currentCurrency,
                onAmountChanged: (value) {
                  setState(() {
                    _amount = value;
                  });
                },
                // ✅ FIXED: Removed validator from AmountInput (not supported)
                // validator removed
              ),
              const SizedBox(height: 16),
              
              // Category
              CategoryPicker(
                categories: categoryProvider.incomeCategories,
                selectedId: _selectedCategory,
                onChanged: (id) {
                  setState(() {
                    _selectedCategory = id;
                  });
                },
                label: 'Category',
              ),
              const SizedBox(height: 16),
              
              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'e.g., Salary, Freelance, Gift',
                prefixIcon: Icons.description,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Date - ✅ FIXED: Changed onChanged to onDateSelected
              DateTimePicker(
                label: 'Date',
                initialDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Add any additional notes',
                prefixIcon: Icons.note,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              
              // Save Button
              CustomButton(
                onPressed: _isLoading ? null : _saveIncome,
                text: 'Add Income',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
