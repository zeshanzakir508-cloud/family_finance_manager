// lib/screens/budget/budget_rollover_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/budget_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class BudgetRolloverScreen extends StatefulWidget {
  final String budgetId;

  const BudgetRolloverScreen({
    Key? key,
    required this.budgetId,
  }) : super(key: key);

  @override
  State<BudgetRolloverScreen> createState() => _BudgetRolloverScreenState();
}

class _BudgetRolloverScreenState extends State<BudgetRolloverScreen> {
  BudgetModel? _budget;
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, bool> _categorySelections = {};

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  void _loadBudget() {
    final budgetProvider = context.read<BudgetProvider>();
    final budget = budgetProvider.budgets.firstWhere(
      (b) => b.id == widget.budgetId,
      orElse: () => throw Exception('Budget not found'),
    );
    setState(() {
      _budget = budget;
      _isLoading = false;
      // Default: select all categories with remaining amount > 0
      for (var category in budget.categories) {
        if (category.remaining > 0) {
          _categorySelections[category.id] = true;
        }
      }
    });
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      _categorySelections[categoryId] = !(_categorySelections[categoryId] ?? false);
    });
  }

  Future<void> _rolloverBudget() async {
    final selectedCategories = _categorySelections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedCategories.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please select at least one category to rollover',
        isError: true,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final budgetProvider = context.read<BudgetProvider>();
      final newBudget = await budgetProvider.rolloverBudget(widget.budgetId);
      
      if (newBudget != null && mounted) {
        CustomSnackBar.show(
          context,
          'Budget rolled over successfully! 📊',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to rollover budget: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rollover Budget')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_budget == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rollover Budget')),
        body: const Center(child: Text('Budget not found')),
      );
    }

    final budget = _budget!;
    final totalRemaining = budget.totalRemaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rollover Budget'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _rolloverBudget,
            child: Text(
              'Rollover',
              style: TextStyle(
                color: _isProcessing ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info section
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[850] : Colors.grey[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${budget.monthName} ${budget.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${currencyProvider.currentCurrency} ${totalRemaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: totalRemaining >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select categories to rollover to next month:',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Category list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budget.categories.length,
              itemBuilder: (context, index) {
                final category = budget.categories[index];
                final isSelected = _categorySelections[category.id] ?? false;
                final canRollover = category.remaining > 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: isSelected && canRollover,
                      onChanged: canRollover
                          ? (_) => _toggleCategory(category.id)
                          : null,
                    ),
                    title: Text(
                      category.name,
                      style: TextStyle(
                        color: !canRollover ? Colors.grey[500] : null,
                      ),
                    ),
                    subtitle: Text(
                      canRollover
                          ? 'Remaining: ${currencyProvider.currentCurrency} ${category.remaining.toStringAsFixed(2)}'
                          : 'No remaining amount',
                      style: TextStyle(
                        color: canRollover ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    trailing: Text(
                      canRollover
                          ? '${currencyProvider.currentCurrency} ${category.remaining.toStringAsFixed(2)}'
                          : '0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: canRollover ? Colors.green : Colors.grey[400],
                      ),
                    ),
                    onTap: canRollover
                        ? () => _toggleCategory(category.id)
                        : null,
                  ),
                );
              },
            ),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            final allSelected = _categorySelections.values.every((v) => v);
                            for (var key in _categorySelections.keys) {
                              _categorySelections[key] = !allSelected;
                            }
                          });
                        },
                        child: Text(
                          _categorySelections.values.every((v) => v)
                              ? 'Deselect All'
                              : 'Select All',
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomButton(
                        onPressed: _isProcessing ? null : _rolloverBudget,
                        text: 'Rollover Selected',
                        isLoading: _isProcessing,
                        type: ButtonType.primary,
                        size: ButtonSize.medium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
