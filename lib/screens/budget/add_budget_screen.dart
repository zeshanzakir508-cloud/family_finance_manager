// lib/screens/budget/add_budget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';
// ✅ FIXED: Added import for CategoryBudgetItem
import 'widgets/category_budget_item.dart';

// ✅ ADDED: CategoryBudgetItemWidget class since it was missing
class CategoryBudgetItemWidget extends StatelessWidget {
  final CategoryBudgetItem item;
  final String currency;
  final ValueChanged<double> onChanged;

  const CategoryBudgetItemWidget({
    Key? key,
    required this.item,
    required this.currency,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: item.allocated == 0 ? '' : item.allocated.toString(),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.categoryName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set budget amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 140,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '$currency ',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0.0;
                  onChanged(amount);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<CategoryBudgetItem> _categoryItems = [];
  bool _isLoading = false;
  bool _isSaving = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      
      await categoryProvider.loadCategories(auth.userId);
      
      final expenseCategories = categoryProvider.expenseCategories;
      
      setState(() {
        _categoryItems = expenseCategories.map((category) {
          return CategoryBudgetItem(
            categoryId: category.id,
            categoryName: category.name,
            allocated: 0.0,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to load categories: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _updateCategoryBudget(String categoryId, double amount) {
    setState(() {
      final index = _categoryItems.indexWhere((item) => item.categoryId == categoryId);
      if (index != -1) {
        _categoryItems[index] = _categoryItems[index].copyWith(allocated: amount);
      }
    });
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final totalAllocated = _categoryItems.fold(0.0, (sum, item) => sum + item.allocated);
    if (totalAllocated == 0) {
      CustomSnackBar.show(
        context,
        'Please allocate at least one category budget',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final budgetProvider = context.read<BudgetProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      
      // Create budget categories
      final budgetCategories = _categoryItems
          .where((item) => item.allocated > 0)
          .map((item) {
            final category = categoryProvider.getCategoryById(item.categoryId);
            return BudgetCategory(
              id: item.categoryId,
              name: item.categoryName,
              allocated: item.allocated,
              spent: 0.0,
              remaining: item.allocated,
            );
          })
          .toList();

      final budget = BudgetModel(
        id: '',
        userId: auth.userId,
        familyId: null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        month: _selectedMonth,
        year: _selectedYear,
        totalAllocated: totalAllocated,
        totalSpent: 0.0,
        totalRemaining: totalAllocated,
        categories: budgetCategories,
        isRollover: false,
        previousBudgetId: null,
        createdAt: DateTime.now(),
        updatedAt: null,
        isActive: true,
      );

      final success = await budgetProvider.createBudget(budget);
      
      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Budget created successfully! 📊',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to create budget: ${e.toString()}',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Budget')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Budget'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveBudget,
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
              // Month/Year picker
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(12, (index) => index + 1)
                          .map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(month == 1 ? 'January' : 
                                      month == 2 ? 'February' :
                                      month == 3 ? 'March' :
                                      month == 4 ? 'April' :
                                      month == 5 ? 'May' :
                                      month == 6 ? 'June' :
                                      month == 7 ? 'July' :
                                      month == 8 ? 'August' :
                                      month == 9 ? 'September' :
                                      month == 10 ? 'October' :
                                      month == 11 ? 'November' : 'December'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(5, (index) => DateTime.now().year + index)
                          .map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value!;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              CustomTextField(
                controller: _nameController,
                label: 'Budget Name',
                hint: 'e.g., Monthly Budget',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Add a description for this budget',
                prefixIcon: Icons.description,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Category budgets
              const Text(
                'Category Allocations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set monthly budget for each category',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              ..._categoryItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CategoryBudgetItemWidget(
                    item: item,
                    currency: currencyProvider.currentCurrency,
                    onChanged: (amount) {
                      _updateCategoryBudget(item.categoryId, amount);
                    },
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${currencyProvider.currentCurrency} ${_categoryItems.fold(0.0, (sum, item) => sum + item.allocated).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              CustomButton(
                onPressed: _isSaving ? null : _saveBudget,
                text: 'Create Budget',
                isLoading: _isSaving,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
