// lib/screens/budget/widgets/budget_card.dart
import 'package:flutter/material.dart';
import '../../../models/budget_model.dart';

class BudgetCard extends StatelessWidget {
  final BudgetCategory category;
  final String currency;
  final VoidCallback? onTap;

  const BudgetCard({
    Key? key,
    required this.category,
    required this.currency,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = category.progressPercentage;
    final isOverBudget = category.isOverBudget;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverBudget
                ? Colors.red.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
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
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$currency ${category.allocated.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                      color: isOverBudget
                          ? Colors.red
                          : progress > 0.8
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isOverBudget ? Colors.red : Colors.green,
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
                  'Spent: $currency ${category.spent.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Remaining: $currency ${category.remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: category.remaining >= 0 ? Colors.green[600] : Colors.red[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
