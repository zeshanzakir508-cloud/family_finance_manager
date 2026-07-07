// lib/screens/goals/widgets/goal_milestone_widget.dart
import 'package:flutter/material.dart';

class GoalMilestoneWidget extends StatelessWidget {
  final double progress;
  final double target;
  final String currency;

  const GoalMilestoneWidget({
    Key? key,
    required this.progress,
    required this.target,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final milestones = _getMilestones();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Milestones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...milestones.map((milestone) {
            final isReached = progress >= milestone.percentage;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReached
                          ? Colors.green
                          : isDark
                              ? Colors.grey[700]
                              : Colors.grey[300],
                    ),
                    child: Icon(
                      isReached ? Icons.check : Icons.hourglass_empty,
                      size: 14,
                      color: isReached ? Colors.white : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      milestone.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: isReached ? Colors.green : Colors.grey[600],
                        fontWeight: isReached ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${currency} ${(target * milestone.percentage).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isReached ? Colors.green : Colors.grey[500],
                      fontWeight: isReached ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<_Milestone> _getMilestones() {
    return [
      _Milestone(percentage: 0.25, label: '25% - Quarter Way'),
      _Milestone(percentage: 0.50, label: '50% - Half Way'),
      _Milestone(percentage: 0.75, label: '75% - Almost There'),
      _Milestone(percentage: 1.0, label: '100% - Goal Achieved! 🎉'),
    ];
  }
}

class _Milestone {
  final double percentage;
  final String label;

  _Milestone(this.percentage, this.label);
}
