// lib/screens/dashboard/widgets/budget_progress_widget.dart
import 'package:flutter/material.dart';
// ✅ FIXED: Removed duplicate import
import '../../../models/budget_model.dart';

class BudgetProgressWidget extends StatelessWidget {
  final BudgetModel budget;
  final String currency;

  const BudgetProgressWidget({
    Key? key,
    required this.budget,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = budget.progressPercentage;

    return Container(
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
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${budget.monthName} ${budget.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: budget.isOverBudget ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    '$currency ${budget.totalSpent.toStringAsFixed(2)} / $currency ${budget.totalAllocated.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  color: budget.isOverBudget
                      ? Colors.red
                      : progress > 0.8
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Top categories
          if (budget.categories.isNotEmpty) ...[
            const Text(
              'Top Categories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...budget.categories.take(3).map((category) {
              final catProgress = category.progressPercentage;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        category.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: catProgress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                          color: category.isOverBudget
                              ? Colors.red
                              : catProgress > 0.8
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(catProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: category.isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
