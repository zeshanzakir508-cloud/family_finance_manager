import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

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

  Future<void> _loadTransaction() async {
    final box = Hive.box<TransactionModel>('transactions');
    final transaction = box.values.firstWhere(
      (t) => t.id == widget.transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );
    
    setState(() {
      _transaction = transaction;
      _isLoading = false;
    });
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _transaction?.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaction Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Transaction not found'),
        ),
      );
    }

    final transaction = _transaction!;
    final isIncome = transaction.type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit transaction coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [Colors.green, Colors.green.shade700]
                      : [Colors.red, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isIncome ? 'Income' : 'Expense',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.formattedAmount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(transaction.date!),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailTile(
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: transaction.description ?? 'No description',
                    ),
                    const Divider(),
                    _buildDetailTile(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: transaction.categoryDisplayName,
                    ),
                    const Divider(),
                    _buildDetailTile(
                      icon: isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      label: 'Type',
                      value: transaction.typeString,
                      valueColor: transaction.typeColor,
                    ),
                    if (transaction.paymentMethod != null) ...[
                      const Divider(),
                      _buildDetailTile(
                        icon: Icons.payment_outlined,
                        label: 'Payment Method',
                        value: transaction.paymentMethod!,
                      ),
                    ],
                    if (transaction.location != null) ...[
                      const Divider(),
                      _buildDetailTile(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: transaction.location!,
                      ),
                    ],
                    if (transaction.isRecurringTransaction) ...[
                      const Divider(),
                      _buildDetailTile(
                        icon: Icons.repeat_outlined,
                        label: 'Recurring',
                        value: transaction.recurrenceDisplay ?? 'Yes',
                      ),
                    ],
                    if (transaction.notes != null) ...[
                      const Divider(),
                      _buildDetailTile(
                        icon: Icons.note_outlined,
                        label: 'Notes',
                        value: transaction.notes!,
                        isMultiLine: true,
                      ),
                    ],
                    const Divider(),
                    _buildDetailTile(
                      icon: Icons.access_time_outlined,
                      label: 'Created At',
                      value: DateFormat('MMM d, yyyy • h:mm a').format(
                        transaction.createdAt ?? DateTime.now(),
                      ),
                    ),
                    if (transaction.updatedAt != null) ...[
                      const Divider(),
                      _buildDetailTile(
                        icon: Icons.update_outlined,
                        label: 'Last Updated',
                        value: DateFormat('MMM d, yyyy • h:mm a').format(
                          transaction.updatedAt!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit transaction coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 22,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.captionStyle,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyStyle.copyWith(
                  color: valueColor ?? AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: isMultiLine ? null : 1,
                overflow: isMultiLine ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
