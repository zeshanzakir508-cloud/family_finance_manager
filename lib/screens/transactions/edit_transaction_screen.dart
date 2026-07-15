// lib/screens/transactions/edit_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
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

class EditTransactionScreen extends StatefulWidget {
  final String transactionId;

  const EditTransactionScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _amount = 0.0;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _transactionType;
  bool _isLoading = true;
  bool _isSaving = false;
  TransactionModel? _transaction;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      
      // ✅ FIXED: Using allTransactions getter
      final transaction = transactionProvider.allTransactions
          .firstWhere((t) => t.id == widget.transactionId);
      
      if (transaction != null) {
        _transaction = transaction;
        _amount = transaction.amount ?? 0.0;
        _selectedCategory = transaction.category;
        _selectedDate = transaction.date ?? DateTime.now();
        _transactionType = transaction.type;
        _descriptionController.text = transaction.description ?? '';
        _notesController.text = transaction.notes ?? '';
        
        final category = categoryProvider.getCategoryByName(transaction.category ?? '');
        if (category != null) {
          _selectedCategory = category.id;
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to load transaction: ${e.toString()}',
          isError: true,
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      CustomSnackBar.show(
        context,
        'Please select a category',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      
      final category = categoryProvider.getCategoryById(_selectedCategory!);
      
      final updates = {
        'amount': _amount,
        'category': category?.name ?? _transaction?.category,
        'description': _descriptionController.text.trim(),
        'date': _selectedDate,
        'notes': _notesController.text.trim(),
      };

      // ✅ FIXED: Using updateTransaction method
      final success = await transactionProvider.updateTransaction(
        widget.transactionId,
        updates,
      );
      
      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Transaction updated successfully! ✅',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to update transaction: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categories = _transactionType == 'income'
        ? categoryProvider.incomeCategories
        : categoryProvider.expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.white,
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _transactionType == 'income'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _transactionType == 'income'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: _transactionType == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _transactionType == 'income' ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _transactionType == 'income'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              AmountInput(
                label: 'Amount',
                currency: currencyProvider.currentCurrency,
                initialAmount: _amount,
                onAmountChanged: (value) {
                  setState(() {
                    _amount = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              CategoryPicker(
                categories: categories,
                selectedId: _selectedCategory,
                onChanged: (id) {
                  setState(() {
                    _selectedCategory = id;
                  });
                },
                label: 'Category',
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter description',
                prefixIcon: Icons.description,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
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
              
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Add any additional notes',
                prefixIcon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              CustomButton(
                onPressed: _isSaving ? null : _saveChanges,
                text: 'Save Changes',
                isLoading: _isSaving,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.save,
              ),
              const SizedBox(height: 12),
              
              CustomButton(
                onPressed: () {
                  _showDeleteConfirmation();
                },
                text: 'Delete Transaction',
                type: ButtonType.danger,
                size: ButtonSize.medium,
                icon: Icons.delete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSaving = true);
              
              try {
                final transactionProvider = context.read<TransactionProvider>();
                // ✅ FIXED: Using deleteTransaction method
                final success = await transactionProvider.deleteTransaction(
                  widget.transactionId,
                );
                
                if (success && mounted) {
                  CustomSnackBar.show(
                    context,
                    'Transaction deleted successfully',
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackBar.show(
                    context,
                    'Failed to delete: ${e.toString()}',
                    isError: true,
                  );
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
