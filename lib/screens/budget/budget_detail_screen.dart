// lib/screens/budget/budget_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/budget_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/budget_progress_bar.dart';
import 'widgets/category_budget_item.dart';

class BudgetDetailScreen extends StatefulWidget {
  final String budgetId;

  const BudgetDetailScreen({
    Key? key,
    required this.budgetId,
  }) : super(key: key);

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  BudgetModel? _budget;
  bool _isLoading = true;

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
    });
  }

  Future<void> _refreshBudget() async {
    setState(() => _isLoading = true);
    await context.read<BudgetProvider>().refreshBudgets(
          context.read<AuthProvider>().userId,
        );
    _loadBudget();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_budget == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              const Text('Budget not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final budget = _budget!;
    final progress = budget.progressPercentage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit budget
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBudget,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (budget.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        budget.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${budget.monthName} ${budget.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Allocated',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${currencyProvider.currentCurrency} ${budget.totalAllocated.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Spent',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${currencyProvider.currentCurrency} ${budget.totalSpent.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: budget.isOverBudget
                                    ? Colors.red[300]
                                    : Colors.green[300],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Remaining',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${currencyProvider.currentCurrency} ${budget.totalRemaining.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: budget.totalRemaining >= 0
                                    ? Colors.green[300]
                                    : Colors.red[300],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BudgetProgressBar(
                      progress: progress,
                      isOverBudget: budget.isOverBudget,
                      label: '${(progress * 100).toStringAsFixed(0)}%',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category breakdown
              const Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (budget.categories.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No categories in this budget',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                ...budget.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${currencyProvider.currentCurrency} ${category.allocated.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: BudgetProgressBar(
                                  progress: category.progressPercentage,
                                  isOverBudget: category.isOverBudget,
                                  height: 8,
                                  label: '',
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '${(category.progressPercentage * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: category.isOverBudget
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent: ${currencyProvider.currentCurrency} ${category.spent.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Remaining: ${currencyProvider.currentCurrency} ${category.remaining.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: category.remaining >= 0
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () {
                        // Navigate to edit budget
                      },
                      text: 'Edit Budget',
                      type: ButtonType.outline,
                      size: ButtonSize.medium,
                      icon: Icons.edit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      onPressed: () {
                        // Rollover budget
                      },
                      text: 'Rollover',
                      type: ButtonType.outline,
                      size: ButtonSize.medium,
                      icon: Icons.autorenew,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                onPressed: _showDeleteConfirmation,
                text: 'Delete Budget',
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
        title: const Text('Delete Budget'),
        content: const Text(
          'Are you sure you want to delete this budget? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final budgetProvider = context.read<BudgetProvider>();
                final success = await budgetProvider.deleteBudget(widget.budgetId);
                if (success && mounted) {
                  CustomSnackBar.show(
                    context,
                    'Budget deleted successfully',
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
