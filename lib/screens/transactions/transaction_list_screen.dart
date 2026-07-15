// lib/screens/transactions/transaction_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/mode_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/transaction_card.dart';
import 'widgets/transaction_filters.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    // ✅ FIXED: AuthProvider → AppAuthProvider
    final auth = context.read<AppAuthProvider>();
    final mode = context.read<ModeProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    if (auth.isAuthenticated) {
      if (mode.isPersonalMode) {
        await transactionProvider.loadTransactions(auth.userId);
      } else {
        final familyId = auth.user?.familyId;
        if (familyId != null) {
          await transactionProvider.loadFamilyTransactions(familyId);
        }
      }
    }
  }

  Future<void> _refreshTransactions() async {
    await _loadTransactions();
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAddOption(
                    icon: Icons.add_circle,
                    label: 'Add Income',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddIncomeScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAddOption(
                    icon: Icons.remove_circle,
                    label: 'Add Expense',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddExpenseScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_off,
              color: _showFilters ? Colors.blue : null,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search_transactions');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters)
            TransactionFilters(
              onApply: (filters) {
                // ✅ FIXED: Using setCategoryFilter, setTypeFilter, setDateRange methods
                transactionProvider.setCategoryFilter(filters['category']);
                transactionProvider.setTypeFilter(filters['type']);
                transactionProvider.setDateRange(
                  filters['startDate'],
                  filters['endDate'],
                );
                setState(() {});
              },
              onClear: () {
                // ✅ FIXED: Using clearFilters method
                transactionProvider.clearFilters();
                setState(() {});
              },
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTransactions,
              child: _buildContent(
                context,
                transactionProvider,
                currencyProvider.currentCurrency,
                isDark,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TransactionProvider provider,
    String currency,
    bool isDark,
  ) {
    // ✅ FIXED: Using isLoading getter
    if (provider.isLoading) {
      return const LoadingWidget();
    }

    // ✅ FIXED: Using error getter
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
              'Failed to load transactions',
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
              onPressed: _refreshTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // ✅ FIXED: Using transactions getter
    final transactions = provider.transactions;

    if (transactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No transactions yet',
        description: 'Add your first transaction to get started!',
        buttonText: 'Add Transaction',
        onPressed: _showAddTransactionSheet,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 4),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionCard(
          transaction: transaction,
          currency: currency,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/transaction_detail',
              arguments: transaction.id,
            );
          },
          onEdit: () {
            Navigator.pushNamed(
              context,
              '/edit_transaction',
              arguments: transaction.id,
            );
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Transaction'),
                content: const Text(
                  'Are you sure you want to delete this transaction?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              // ✅ FIXED: Using deleteTransaction method
              await provider.deleteTransaction(transaction.id!);
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'Transaction deleted successfully',
                );
              }
            }
          },
        );
      },
    );
  }
}
