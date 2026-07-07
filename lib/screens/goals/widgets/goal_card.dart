// lib/screens/goals/widgets/goal_card.dart
import 'package:flutter/material.dart';
import '../../../models/goal_model.dart';
import 'goal_progress_circle.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String currency;
  final VoidCallback? onTap;

  const GoalCard({
    Key? key,
    required this.goal,
    required this.currency,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = goal.progress;
    final isCompleted = goal.isAchieved;
    final isOverdue = goal.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withOpacity(0.3)
                : isOverdue
                    ? Colors.red.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Progress circle
            GoalProgressCircle(
              progress: progress,
              size: 60,
              strokeWidth: 4,
              backgroundColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              progressColor: isCompleted
                  ? Colors.green
                  : isOverdue
                      ? Colors.red
                      : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (isOverdue && !isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Overdue',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.category ?? 'Goal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currency} ${goal.currentAmount?.toStringAsFixed(2) ?? '0.00'} / ${currency} ${goal.targetAmount?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.green
                              : isOverdue
                                  ? Colors.red
                                  : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                      color: isCompleted
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                    ),
                  ),
                  if (goal.deadline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Deadline: ${goal.deadline!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? Colors.red[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
