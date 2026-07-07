// lib/screens/dashboard/widgets/transaction_list_widget.dart
import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../transactions/widgets/transaction_card.dart';

class TransactionListWidget extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const TransactionListWidget({
    Key? key,
    required this.transactions,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 4),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionCard(
          transaction: transaction,
          currency: currency,
          onTap: () {
            // Navigate to transaction detail
          },
        );
      },
    );
  }
}
