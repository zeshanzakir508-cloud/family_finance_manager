// lib/screens/reports/cash_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/line_chart_widget.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({Key? key}) : super(key: key);

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  
  Map<String, Map<String, double>> _monthlyData = {};
  double _finalBalance = 0.0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 90)),
      end: DateTime.now(),
    );
    _generateReport();
  }

  Future<void> _generateReport() async {
    if (_selectedDateRange == null) return;

    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: AuthProvider → AppAuthProvider
      final auth = context.read<AppAuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      final allTransactions = transactionProvider.allTransactions;
      
      final filtered = allTransactions.where((t) {
        final date = t.date ?? DateTime.now();
        return date.isAfter(_selectedDateRange!.start) &&
            date.isBefore(_selectedDateRange!.end);
      }).toList();

      _totalTransactions = filtered.length;
      _monthlyData = {};
      
      double cumulativeBalance = 0.0;

      for (var t in filtered) {
        if (t.date != null) {
          final monthKey = '${t.date!.year}-${t.date!.month.toString().padLeft(2, '0')}';
          if (!_monthlyData.containsKey(monthKey)) {
            _monthlyData[monthKey] = {'income': 0.0, 'expense': 0.0};
          }
          if (t.isIncome) {
            _monthlyData[monthKey]!['income'] = 
                (_monthlyData[monthKey]!['income'] ?? 0.0) + (t.amount ?? 0.0);
          } else if (t.isExpense) {
            _monthlyData[monthKey]!['expense'] = 
                (_monthlyData[monthKey]!['expense'] ?? 0.0) + (t.amount ?? 0.0);
          }
        }
      }

      for (var entry in _monthlyData.entries) {
        final values = entry.value;
        final net = (values['income'] ?? 0.0) - (values['expense'] ?? 0.0);
        cumulativeBalance += net;
      }
      _finalBalance = cumulativeBalance;

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
        title: const Text('Cash Flow Analysis'),
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
    if (_monthlyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No transactions found for the selected period',
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

    final sortedKeys = _monthlyData.keys.toList()..sort();
    final firstMonth = sortedKeys.isNotEmpty ? sortedKeys.first : '';
    final lastMonth = sortedKeys.isNotEmpty ? sortedKeys.last : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _finalBalance >= 0 ? Colors.green : Colors.red,
                  _finalBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Final Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_finalBalance >= 0 ? '+' : ''}$currency ${_finalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_totalTransactions transactions',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'From',
                  value: _formatMonth(firstMonth),
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'To',
                  value: _formatMonth(lastMonth),
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_monthlyData.isNotEmpty)
            LineChartWidget(
              data: _monthlyData,
              currency: currency,
              isDark: isDark,
              showNet: true,
              showCumulative: true,
            ),
          const SizedBox(height: 16),

          const Text(
            'Monthly Cash Flow',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          ..._monthlyData.entries.toList().reversed.map((entry) {
            final values = entry.value;
            final income = values['income'] ?? 0.0;
            final expense = values['expense'] ?? 0.0;
            final net = income - expense;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatMonth(entry.key),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: net >= 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${net >= 0 ? '+' : ''}$currency ${net.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: net >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${monthNames[month - 1]} $year';
    } catch (_) {
      return monthKey;
    }
  }
}
