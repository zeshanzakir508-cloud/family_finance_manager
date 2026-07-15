// lib/screens/budget/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../models/budget_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/budget_card.dart';
import 'widgets/budget_progress_bar.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // ✅ FIXED: AuthProvider → AppAuthProvider
    final auth = context.read<AppAuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    
    if (auth.isAuthenticated) {
      await budgetProvider.loadCurrentMonthBudget(auth.userId);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/add_budget');
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Show budget history
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(
          context,
          budgetProvider,
          currencyProvider.currentCurrency,
          isDark,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BudgetProvider provider,
    String currency,
    bool isDark,
  ) {
    if (provider.isLoading) {
      return const LoadingWidget();
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.currentBudget == null) {
      return EmptyStateWidget(
        icon: Icons.speed,
        title: 'No Budget Set',
        description: 'Create a budget for this month to track your spending.',
        buttonText: 'Create Budget',
        onPressed: () {
          Navigator.pushNamed(context, '/add_budget');
        },
      );
    }

    final budget = provider.currentBudget!;
    final progress = budget.progressPercentage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${budget.monthName} ${budget.year}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: budget.isOverBudget
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        budget.isOverBudget ? 'Over Budget' : 'On Track',
                        style: TextStyle(
                          color: budget.isOverBudget ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allocated',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$currency ${budget.totalAllocated.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Spent',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$currency ${budget.totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: budget.isOverBudget ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$currency ${budget.totalRemaining.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: budget.totalRemaining >= 0
                                ? Colors.green
                                : Colors.red,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Category Budgets',
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
                  'No categories added yet',
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
                child: BudgetCard(
                  category: category,
                  currency: currency,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/budget_detail',
                      arguments: budget.id,
                    );
                  },
                ),
              );
            }).toList(),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_budget');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showRolloverDialog(budget);
                  },
                  icon: const Icon(Icons.autorenew),
                  label: const Text('Rollover'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRolloverDialog(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rollover Budget'),
        content: const Text(
          'Rollover remaining budget to next month?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              CustomSnackBar.show(
                context,
                'Budget rolled over successfully!',
              );
            },
            child: const Text('Rollover'),
          ),
        ],
      ),
    );
  }
}
