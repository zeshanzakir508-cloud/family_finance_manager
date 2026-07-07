// lib/screens/goals/widgets/goal_progress_circle.dart
import 'package:flutter/material.dart';

class GoalProgressCircle extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  const GoalProgressCircle({
    Key? key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 4,
    required this.backgroundColor,
    required this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor,
              color: progressColor,
            ),
          ),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }
}
