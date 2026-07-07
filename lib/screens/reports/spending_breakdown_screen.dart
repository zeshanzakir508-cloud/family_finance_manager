// lib/screens/reports/spending_breakdown_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/pie_chart_widget.dart';

class SpendingBreakdownScreen extends StatefulWidget {
  const SpendingBreakdownScreen({Key? key}) : super(key: key);

  @override
  State<SpendingBreakdownScreen> createState() => _SpendingBreakdownScreenState();
}

class _SpendingBreakdownScreenState extends State<SpendingBreakdownScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  Map<String, double>? _categoryData;
  double _totalSpending = 0.0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _generateReport();
  }

  Future<void> _generateReport() async {
    if (_selectedDateRange == null) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      // Get expense transactions
      final allTransactions = transactionProvider.allTransactions;
      final expenses = allTransactions.where((t) {
        final date = t.date ?? DateTime.now();
        return t.isExpense &&
            date.isAfter(_selectedDateRange!.start) &&
            date.isBefore(_selectedDateRange!.end);
      }).toList();

      _transactionCount = expenses.length;

      // Group by category
      final categoryMap = <String, double>{};
      for (var t in expenses) {
        final category = t.category ?? 'Other';
        categoryMap[category] = (categoryMap[category] ?? 0.0) + (t.amount ?? 0.0);
      }

      _categoryData = categoryMap;
      _totalSpending = categoryMap.values.fold(0.0, (sum, v) => sum + v);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackBar.show(
        context,
        'Failed to generate report: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _showDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Breakdown'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(
              context,
              currencyProvider.currentCurrency,
              isDark,
            ),
    );
  }

  Widget _buildContent(BuildContext context, String currency, bool isDark) {
    if (_categoryData == null || _categoryData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No expense data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No expenses found for the selected period',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: _showDatePicker,
              text: 'Change Date Range',
              type: ButtonType.outline,
              size: ButtonSize.medium,
              icon: Icons.calendar_today,
            ),
          ],
        ),
      );
    }

    final sortedEntries = _categoryData!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${_transactionCount} transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue,
                  Colors.blue.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spending',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency ${_totalSpending.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pie chart
          PieChartWidget(
            data: _categoryData!,
            currency: currency,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Category list
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...sortedEntries.map((entry) {
            final percentage = _totalSpending > 0
                ? (entry.value / _totalSpending * 100)
                : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$currency ${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 4,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                      color: _getCategoryColor(entry.key),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
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
    ];
    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }
}
