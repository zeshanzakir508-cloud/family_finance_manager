// lib/screens/dashboard/widgets/spending_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/transaction_model.dart';

class SpendingChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const SpendingChart({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseTransactions = transactions.where((t) => t.isExpense).toList();

    if (expenseTransactions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No expense data available'),
        ),
      );
    }

    // Group by category
    final Map<String, double> categoryTotals = {};
    for (var t in expenseTransactions) {
      final category = t.category ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + (t.amount ?? 0.0);
    }

    // Sort and take top 5
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedEntries.take(5).toList();
    final otherTotal = sortedEntries.skip(5).fold(0.0, (sum, e) => sum + e.value);

    final chartData = <String, double>{};
    for (var entry in topCategories) {
      chartData[entry.key] = entry.value;
    }
    if (otherTotal > 0) {
      chartData['Others'] = otherTotal;
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.grey,
    ];

    final total = chartData.values.fold(0.0, (sum, v) => sum + v);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: _buildSections(chartData, colors, total),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          // Legend
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: chartData.entries.map((entry) {
                  final index = chartData.keys.toList().indexOf(entry.key);
                  final color = colors[index % colors.length];
                  final percentage = total > 0 ? (entry.value / total * 100) : 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    Map<String, double> data,
    List<Color> colors,
    double total,
  ) {
    final sections = <PieChartSectionData>[];

    int index = 0;
    for (var entry in data.entries) {
      final color = colors[index % colors.length];
      final percentage = total > 0 ? (entry.value / total * 100) : 0;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgePosition: PieChartBadgePosition.topCenter,
        ),
      );
      index++;
    }

    return sections;
  }
}
