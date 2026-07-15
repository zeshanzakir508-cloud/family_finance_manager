// lib/screens/dashboard/personal_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/balance_card.dart';
import 'widgets/spending_chart.dart';
import 'widgets/transaction_list_widget.dart';
import 'widgets/budget_progress_widget.dart';
import 'widgets/quick_actions_widget.dart';

class PersonalDashboard extends StatefulWidget {
  const PersonalDashboard({Key? key}) : super(key: key);

  @override
  State<PersonalDashboard> createState() => _PersonalDashboardState();
}

class _PersonalDashboardState extends State<PersonalDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ✅ FIXED: Changed AuthProvider to AppAuthProvider
  Future<void> _loadData() async {
    final auth = context.read<AppAuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final goalProvider = context.read<GoalProvider>();

    if (auth.isAuthenticated) {
      await transactionProvider.loadTransactions(auth.userId);
      await budgetProvider.loadCurrentMonthBudget(auth.userId);
      await goalProvider.loadGoals(auth.userId);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    if (transactionProvider.isLoading) {
      return const LoadingWidget();
    }

    if (transactionProvider.error != null) {
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
              'Failed to load dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              transactionProvider.error!,
              style: TextStyle(
                color: Colors.grey[600],
              ),
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

    final transactions = transactionProvider.transactions;
    final totalIncome = transactionProvider.totalIncome;
    final totalExpense = transactionProvider.totalExpense;
    final balance = transactionProvider.balance;
    final currentBudget = budgetProvider.currentBudget;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome back! 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  child: const Text(
                    'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            BalanceCard(
              balance: balance,
              income: totalIncome,
              expense: totalExpense,
              currency: currencyProvider.currentCurrency,
            ),
            const SizedBox(height: 16),

            if (currentBudget != null)
              BudgetProgressWidget(
                budget: currentBudget,
                currency: currencyProvider.currentCurrency,
              ),
            const SizedBox(height: 16),

            const QuickActionsWidget(),
            const SizedBox(height: 16),

            if (transactions.isNotEmpty) ...[
              const Text(
                'Spending Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SpendingChart(transactions: transactions),
              const SizedBox(height: 16),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all transactions
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (transactions.isNotEmpty)
              TransactionListWidget(
                transactions: transactions.take(5).toList(),
                currency: currencyProvider.currentCurrency,
              )
            else
              EmptyStateWidget(
                icon: Icons.receipt_long,
                title: 'No transactions yet',
                description: 'Add your first transaction to get started!',
                buttonText: 'Add Transaction',
                onPressed: () {
                  // Navigate to add transaction
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
