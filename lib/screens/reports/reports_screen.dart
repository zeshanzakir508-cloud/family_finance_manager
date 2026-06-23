import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_theme.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Week', 'Month', 'Year', 'All'];
  int _selectedChartIndex = 0;
  final List<String> _chartTypes = ['Pie', 'Bar', 'Category'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedPeriod = value);
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final transactions = box.values.toList();

          if (transactions.isEmpty) {
            return _buildEmptyState();
          }

          final filteredTransactions = _filterByPeriod(transactions);
          final totalIncome = _calculateTotal(filteredTransactions, true);
          final totalExpense = _calculateTotal(filteredTransactions, false);
          final balance = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(totalIncome, totalExpense, balance),
                const SizedBox(height: 20),
                _buildChartTypeSelector(),
                const SizedBox(height: 16),
                _buildChart(filteredTransactions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: AppTheme.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No data to show',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some transactions to see reports',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionModel> _filterByPeriod(List<TransactionModel> transactions) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return transactions.where((t) => t.date.isAfter(weekAgo)).toList();
      case 'Month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return transactions.where((t) => t.date.isAfter(monthAgo)).toList();
      case 'Year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return transactions.where((t) => t.date.isAfter(yearAgo)).toList();
      case 'All':
      default:
        return transactions;
    }
  }

  double _calculateTotal(List<TransactionModel> transactions, bool income) {
    return transactions
        .where((t) => t.type == (income ? TransactionType.income : TransactionType.expense))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Widget _buildSummaryCards(double income, double expense, double balance) {
    return Row(
      children: [
        _buildSummaryCard('Income', income, AppTheme.success, Icons.trending_up),
        const SizedBox(width: 10),
        _buildSummaryCard('Expense', expense, AppTheme.error, Icons.trending_down),
        const SizedBox(width: 10),
        _buildSummaryCard('Balance', balance, balance >= 0 ? AppTheme.primary : AppTheme.error, Icons.account_balance_wallet),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              NumberFormat('#,##0.00').format(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: _chartTypes.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedChartIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(List<TransactionModel> transactions) {
    switch (_selectedChartIndex) {
      case 0:
        return _buildPieChart(transactions);
      case 1:
        return _buildBarChart(transactions);
      case 2:
        return _buildCategoryBreakdown(transactions);
      default:
        return _buildPieChart(transactions);
    }
  }

  Widget _buildPieChart(List<TransactionModel> transactions) {
    final incomeTotal = _calculateTotal(transactions, true);
    final expenseTotal = _calculateTotal(transactions, false);
    final total = incomeTotal + expenseTotal;

    if (total == 0) {
      return _buildChartEmptyState('No data for pie chart');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Income vs Expense',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: incomeTotal,
                    title: '${((incomeTotal / total) * 100).toStringAsFixed(1)}%',
                    color: AppTheme.success,
                    radius: 90,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: expenseTotal,
                    title: '${((expenseTotal / total) * 100).toStringAsFixed(1)}%',
                    color: AppTheme.error,
                    radius: 90,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                sectionsSpace: 4,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', AppTheme.success),
              const SizedBox(width: 24),
              _buildLegendItem('Expense', AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        )),
      ],
    );
  }

  Widget _buildBarChart(List<TransactionModel> transactions) {
    final Map<String, Map<String, double>> monthlyData = {};

    for (var t in transactions) {
      final key = DateFormat('MMM yyyy').format(t.date);
      if (!monthlyData.containsKey(key)) {
        monthlyData[key] = {'income': 0.0, 'expense': 0.0};
      }
      if (t.type == TransactionType.income) {
        monthlyData[key]!['income'] = (monthlyData[key]!['income'] ?? 0) + t.amount;
      } else {
        monthlyData[key]!['expense'] = (monthlyData[key]!['expense'] ?? 0) + t.amount;
      }
    }

    final sortedKeys = monthlyData.keys.toList()..sort();

    if (sortedKeys.isEmpty) {
      return _buildChartEmptyState('No data for bar chart');
    }

    double maxValue = 0;
    for (var key in sortedKeys) {
      final data = monthlyData[key]!;
      final total = (data['income'] ?? 0) + (data['expense'] ?? 0);
      if (total > maxValue) maxValue = total;
    }
    maxValue = maxValue * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Monthly Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxValue,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < sortedKeys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedKeys[value.toInt()].split(' ')[0],
                              style: const TextStyle(fontSize: 10),
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
                        if (value > 0) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: sortedKeys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final key = entry.value;
                  final data = monthlyData[key]!;
                  final total = (data['income'] ?? 0) + (data['expense'] ?? 0);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['income'] ?? 0,
                        color: AppTheme.success,
                        width: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: total,
                        color: AppTheme.error,
                        width: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', AppTheme.success),
              const SizedBox(width: 24),
              _buildLegendItem('Expense', AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<TransactionModel> transactions) {
    final Map<String, double> categoryTotals = {};
    for (var t in transactions) {
      final key = '${t.type.name}_${t.category}';
      categoryTotals[key] = (categoryTotals[key] ?? 0) + t.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedEntries.take(8).toList();

    if (topCategories.isEmpty) {
      return _buildChartEmptyState('No data for category breakdown');
    }

    final totalAmount = topCategories.fold(0.0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...topCategories.map((entry) {
            final percentage = (entry.value / totalAmount) * 100;
            final isIncome = entry.key.startsWith('income');
            final color = isIncome ? AppTheme.success : AppTheme.error;
            final parts = entry.key.split('_');
            final category = parts.length > 1 ? parts.sublist(1).join('_') : entry.key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: Text(
                              category,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: AppTheme.background,
                            color: color,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}