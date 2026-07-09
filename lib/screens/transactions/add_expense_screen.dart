// lib/screens/transactions/add_expense_screen.dart
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

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
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
      final expenseCategories = categoryProvider.expenseCategories;
      if (expenseCategories.isNotEmpty) {
        setState(() {
          _selectedCategory = expenseCategories.first.id;
        });
      }
    }
  }

  Future<void> _saveExpense() async {
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
        category: category?.name ?? 'Expense',
        description: _descriptionController.text.trim(),
        type: 'expense',
        date: _selectedDate,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        isFamilyTransaction: mode.isFamilyMode,
      );

      final success = await transactionProvider.addTransaction(transaction);
      
      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Expense added successfully! 💳',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to add expense: ${e.toString()}',
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
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
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
                categories: categoryProvider.expenseCategories,
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
                hint: 'e.g., Grocery, Rent, Transport',
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
                onPressed: _isLoading ? null : _saveExpense,
                text: 'Add Expense',
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
