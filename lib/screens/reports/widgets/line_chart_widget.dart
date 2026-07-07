// lib/screens/reports/widgets/line_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currency;
  final bool isDark;
  final bool showNet;
  final bool showCumulative;

  const LineChartWidget({
    Key? key,
    required this.data,
    required this.currency,
    required this.isDark,
    this.showNet = false,
    this.showCumulative = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final sortedKeys = keys.toList()..sort();

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
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: sortedKeys.length.toDouble() - 1,
                minY: _getMinY(),
                maxY: _getMaxY(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedKeys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _getLabel(sortedKeys[index]),
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
                lineTouchData: LineTouchData(enabled: true),
                lineBarsData: _getLineBars(sortedKeys),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  double _getMinY() {
    double min = 0;
    final sortedKeys = data.keys.toList()..sort();
    for (var key in sortedKeys) {
      final value = data[key];
      if (value is Map<String, double>) {
        final net = (value['income'] ?? 0) - (value['expense'] ?? 0);
        min = min < net ? min : net;
        if (showCumulative) {
          // Calculate cumulative
        }
      } else if (value is double) {
        min = min < value ? min : value;
      }
    }
    return min * 1.2;
  }

  double _getMaxY() {
    double max = 0;
    final sortedKeys = data.keys.toList()..sort();
    for (var key in sortedKeys) {
      final value = data[key];
      if (value is Map<String, double>) {
        final net = (value['income'] ?? 0) - (value['expense'] ?? 0);
        max = max > net ? max : net;
        if (showCumulative) {
          // Calculate cumulative
        }
      } else if (value is double) {
        max = max > value ? max : value;
      }
    }
    return max * 1.2;
  }

  List<LineChartBarData> _getLineBars(List<String> sortedKeys) {
    final bars = <LineChartBarData>[];

    if (showNet) {
      // Net line
      final spots = <FlSpot>[];
      for (int i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        final value = data[key];
        if (value is Map<String, double>) {
          final net = (value['income'] ?? 0) - (value['expense'] ?? 0);
          spots.add(FlSpot(i.toDouble(), net));
        }
      }
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      );
    } else if (showCumulative) {
      // Cumulative line
      final spots = <FlSpot>[];
      double cumulative = 0;
      for (int i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        final value = data[key];
        if (value is Map<String, double>) {
          final net = (value['income'] ?? 0) - (value['expense'] ?? 0);
          cumulative += net;
          spots.add(FlSpot(i.toDouble(), cumulative));
        }
      }
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
      );
    } else {
      // Income and expense lines
      final incomeSpots = <FlSpot>[];
      final expenseSpots = <FlSpot>[];
      for (int i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        final value = data[key];
        if (value is Map<String, double>) {
          incomeSpots.add(FlSpot(i.toDouble(), value['income'] ?? 0));
          expenseSpots.add(FlSpot(i.toDouble(), value['expense'] ?? 0));
        }
      }
      bars.add(
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
      );
      bars.add(
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withOpacity(0.1),
          ),
        ),
      );
    }

    return bars;
  }

  String _getLabel(String key) {
    try {
      final parts = key.split('-');
      final month = int.parse(parts[1]);
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return monthNames[month - 1];
    } catch (_) {
      if (key.length > 10) return key.substring(0, 8) + '...';
      return key;
    }
  }

  Widget _buildLegend() {
    if (showNet) {
      return _buildLegendItem('Net', Colors.blue);
    } else if (showCumulative) {
      return _buildLegendItem('Cumulative', Colors.green);
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Income', Colors.green),
          const SizedBox(width: 16),
          _buildLegendItem('Expense', Colors.red),
        ],
      );
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
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
