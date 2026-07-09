// lib/screens/reports/widgets/pie_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String currency;
  final bool isDark;

  const PieChartWidget({
    Key? key,
    required this.data,
    required this.currency,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepPurple,
      Colors.lime,
    ];

    final total = data.values.fold(0.0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sortedEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  // ✅ FIXED: Proper division with total
                  final percentage = total > 0 ? (value / total * 100) : 0;
                  final color = colors[index % colors.length];

                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    // ✅ FIXED: Removed badgePosition parameter
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value.key;
              final value = entry.value.value;
              final percentage = total > 0 ? (value / total * 100) : 0;
              final color = colors[index % colors.length];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$name (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
