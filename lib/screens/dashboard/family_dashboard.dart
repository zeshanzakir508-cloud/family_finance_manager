// lib/screens/dashboard/family_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/family_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/mode_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/balance_card.dart';
import 'widgets/spending_chart.dart';
import 'widgets/transaction_list_widget.dart';
import 'widgets/budget_progress_widget.dart';
import 'widgets/quick_actions_widget.dart';

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({Key? key}) : super(key: key);

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AppAuthProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    if (auth.isAuthenticated) {
      await familyProvider.refreshData();
      final family = familyProvider.currentFamily;
      if (family != null) {
        // ✅ Using loadFamilyTransactions method
        await transactionProvider.loadFamilyTransactions(family.id);
      }
      await context.read<BudgetProvider>().loadCurrentMonthBudget(auth.userId);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    // ✅ Using isLoading getter
    if (transactionProvider.isLoading) {
      return const LoadingWidget();
    }

    if (familyProvider.currentFamily == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Family Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a family to get started',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/family_setup');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Family'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/join_family');
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Join Family'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<ModeProvider>().setMode('personal');
              },
              child: const Text('Switch to Personal Mode'),
            ),
          ],
        ),
      );
    }

    final family = familyProvider.currentFamily!;
    // ✅ Using transactions, totalIncome, totalExpense, balance getters
    final transactions = transactionProvider.transactions;
    final totalIncome = transactionProvider.totalIncome;
    final totalExpense = transactionProvider.totalExpense;
    final balance = transactionProvider.balance;
    final currentBudget = budgetProvider.currentBudget;
    final members = familyProvider.getFamilyMembers();

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
                    Row(
                      children: [
                        Text(
                          family.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${members.length} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Family Code: ${family.familyCode ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal[100],
                  child: Text(
                    family.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.teal[700],
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
              title: 'Family Balance',
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
                'Family Spending Breakdown',
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
                  'Recent Family Transactions',
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
                description: 'Add your first family transaction to get started!',
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
