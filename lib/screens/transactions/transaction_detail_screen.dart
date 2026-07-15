// lib/screens/transactions/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/transaction_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  void _loadTransaction() {
    final transactionProvider = context.read<TransactionProvider>();
    // ✅ FIXED: Using allTransactions getter
    final transaction = transactionProvider.allTransactions
        .firstWhere((t) => t.id == widget.transactionId);
    
    setState(() {
      _transaction = transaction;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
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
              const Text('Transaction not found'),
            ],
          ),
        ),
      );
    }

    final transaction = _transaction!;
    final isIncome = transaction.isIncome;
    final color = isIncome ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit_transaction',
                arguments: transaction.id,
              ).then((_) => _loadTransaction());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isIncome ? 'Income' : 'Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${currencyProvider.currentCurrency} ${transaction.amount?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildDetailItem(
              icon: Icons.category,
              label: 'Category',
              value: transaction.category ?? 'Uncategorized',
            ),
            _buildDetailItem(
              icon: Icons.description,
              label: 'Description',
              value: transaction.description ?? 'No description',
            ),
            _buildDetailItem(
              icon: Icons.calendar_today,
              label: 'Date',
              value: transaction.date?.toLocal().toString().split(' ')[0] ?? '',
            ),
            if (transaction.notes?.isNotEmpty ?? false)
              _buildDetailItem(
                icon: Icons.note,
                label: 'Notes',
                value: transaction.notes!,
              ),
            _buildDetailItem(
              icon: Icons.access_time,
              label: 'Created At',
              value: transaction.createdAt?.toLocal().toString() ?? '',
            ),
            if (transaction.isFamilyTransaction == true)
              _buildDetailItem(
                icon: Icons.family_restroom,
                label: 'Type',
                value: 'Family Transaction',
              ),
            if (transaction.tags?.isNotEmpty ?? false)
              _buildDetailItem(
                icon: Icons.local_offer,
                label: 'Tags',
                value: transaction.tags!.join(', '),
              ),
            if (transaction.isRecurring == true)
              _buildDetailItem(
                icon: Icons.repeat,
                label: 'Recurring',
                value: transaction.recurringInterval ?? 'Yes',
              ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/edit_transaction',
                        arguments: transaction.id,
                      ).then((_) => _loadTransaction());
                    },
                    text: 'Edit',
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                    icon: Icons.edit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      _showDeleteConfirmation();
                    },
                    text: 'Delete',
                    type: ButtonType.danger,
                    size: ButtonSize.medium,
                    icon: Icons.delete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[300]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
