// lib/screens/reports/widgets/bar_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? compareData;
  final String currency;
  final bool isDark;
  final bool showIncomeExpense;
  final bool showYearOverYear;

  const BarChartWidget({
    Key? key,
    required this.data,
    this.compareData,
    required this.currency,
    required this.isDark,
    this.showIncomeExpense = false,
    this.showYearOverYear = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();

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
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < keys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _getLabel(keys[index]),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '$currency${value.toInt()}',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var entry in data.entries) {
      if (showIncomeExpense) {
        final values = entry.value as Map<String, double>;
        max = max > (values['income'] ?? 0) ? max : (values['income'] ?? 0);
        max = max > (values['expense'] ?? 0) ? max : (values['expense'] ?? 0);
      } else if (showYearOverYear && compareData != null) {
        final currentNet = _getNetValue(entry.value);
        final compareNet = _getNetValue(compareData![entry.key] ?? {});
        max = max > currentNet ? max : currentNet;
        max = max > compareNet ? max : compareNet;
      } else {
        final value = entry.value is double
            ? entry.value
            : _getNetValue(entry.value);
        max = max > value ? max : value;
      }
    }
    return max * 1.2;
  }

  double _getNetValue(dynamic value) {
    if (value is double) return value;
    if (value is Map<String, double>) {
      return (value['income'] ?? 0.0) - (value['expense'] ?? 0.0);
    }
    return 0.0;
  }

  List<BarChartGroupData> _getBarGroups() {
    final keys = data.keys.toList();
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = data[key];
      final bars = <BarChartRodData>[];

      if (showIncomeExpense && value is Map<String, double>) {
        // Income and expense bars
        bars.add(
          BarChartRodData(
            toY: value['income'] ?? 0,
            color: Colors.green,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
        bars.add(
          BarChartRodData(
            toY: value['expense'] ?? 0,
            color: Colors.red,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
      } else if (showYearOverYear && compareData != null) {
        // Current year vs compare year
        final currentNet = _getNetValue(value);
        final compareNet = _getNetValue(compareData![key] ?? {});
        bars.add(
          BarChartRodData(
            toY: currentNet,
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
        bars.add(
          BarChartRodData(
            toY: compareNet,
            color: Colors.grey,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
      } else {
        // Single value
        final val = value is double ? value : _getNetValue(value);
        bars.add(
          BarChartRodData(
            toY: val,
            color: _getColorByIndex(i),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
      }

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: bars,
          showingTooltipIndicators: [],
        ),
      );
    }

    return groups;
  }

  String _getLabel(String key) {
    if (key.length > 10) return key.substring(0, 8) + '...';
    return key;
  }

  Color _getColorByIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Widget _buildLegend() {
    if (showIncomeExpense) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Income', Colors.green),
          const SizedBox(width: 16),
          _buildLegendItem('Expense', Colors.red),
        ],
      );
    } else if (showYearOverYear) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Current Year', Colors.blue),
          const SizedBox(width: 16),
          _buildLegendItem('Compare Year', Colors.grey),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
