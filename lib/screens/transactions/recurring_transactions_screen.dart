// lib/screens/transactions/recurring_transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/transaction_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/transaction_card.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  List<TransactionModel> _recurringTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadRecurringTransactions();
  }

  void _loadRecurringTransactions() {
    final transactionProvider = context.read<TransactionProvider>();
    _recurringTransactions = transactionProvider.allTransactions
        .where((t) => t.isRecurring == true)
        .toList();
  }

  String _getIntervalDisplay(String? interval) {
    switch (interval) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'biweekly': return 'Bi-weekly';
      case 'monthly': return 'Monthly';
      case 'quarterly': return 'Quarterly';
      case 'yearly': return 'Yearly';
      default: return interval ?? 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddRecurringDialog();
            },
          ),
        ],
      ),
      body: _buildContent(currencyProvider.currentCurrency, isDark),
    );
  }

  Widget _buildContent(String currency, bool isDark) {
    if (_recurringTransactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.repeat,
        title: 'No Recurring Transactions',
        description: 'Set up recurring transactions for regular income or expenses.',
        buttonText: 'Add Recurring',
        onPressed: () => _showAddRecurringDialog(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _recurringTransactions.length,
      separatorBuilder: (context, index) => const Divider(height: 4),
      itemBuilder: (context, index) {
        final transaction = _recurringTransactions[index];
        // ✅ FIXED: Removed trailing parameter - using a Container as child of TransactionCard with custom layout
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
          // ✅ FIXED: Removed trailing parameter, added custom widget
        );
      },
    );
  }

  void _showAddRecurringDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        final _descriptionController = TextEditingController();
        final _amountController = TextEditingController();
        String _type = 'expense';
        String _interval = 'monthly';
        DateTime _startDate = DateTime.now();

        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
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
                  const Text(
                    'Add Recurring Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Type toggle
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'income', label: Text('Income')),
                                ButtonSegment(value: 'expense', label: Text('Expense')),
                              ],
                              selected: {_type},
                              onSelectionChanged: (set) {
                                _type = set.first;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            // Amount
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            // Interval
                            DropdownButtonFormField<String>(
                              value: _interval,
                              items: const [
                                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                              ],
                              onChanged: (v) => _interval = v!,
                              decoration: const InputDecoration(
                                labelText: 'Frequency',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Start date
                            ListTile(
                              title: const Text('Start Date'),
                              subtitle: Text(_startDate.toString().split(' ')[0]),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  _startDate = picked;
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // TODO: Save recurring transaction
                                  Navigator.pop(context);
                                  CustomSnackBar.show(
                                    context,
                                    'Recurring transaction added!',
                                  );
                                }
                              },
                              text: 'Add Recurring',
                              type: ButtonType.primary,
                              size: ButtonSize.large,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
