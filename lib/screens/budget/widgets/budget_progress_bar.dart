// lib/screens/budget/widgets/budget_progress_bar.dart
import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double progress;
  final bool isOverBudget;
  final String label;
  final double height;
  final Color? color;

  const BudgetProgressBar({
    Key? key,
    required this.progress,
    required this.isOverBudget,
    this.label = '',
    this.height = 10,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ??
        (isOverBudget
            ? Colors.red
            : progress > 0.8
                ? Colors.orange
                : Colors.green);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: progressColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: height,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
            color: progressColor,
          ),
        ),
      ],
    );
  }
}
