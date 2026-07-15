// lib/screens/reports/income_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/bar_chart_widget.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({Key? key}) : super(key: key);

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  int _incomeCount = 0;
  int _expenseCount = 0;
  Map<String, Map<String, double>> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime(DateTime.now().year, 1, 1),
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

      _totalIncome = 0.0;
      _totalExpense = 0.0;
      _incomeCount = 0;
      _expenseCount = 0;
      _monthlyData = {};

      for (var t in filtered) {
        if (t.isIncome) {
          _totalIncome += t.amount ?? 0.0;
          _incomeCount++;
        } else if (t.isExpense) {
          _totalExpense += t.amount ?? 0.0;
          _expenseCount++;
        }

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
        title: const Text('Income vs Expense'),
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
    final totalTransactions = _incomeCount + _expenseCount;

    if (totalTransactions == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No income or expense transactions for the selected period',
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

    final netAmount = _totalIncome - _totalExpense;
    final isPositive = netAmount >= 0;

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
                  isPositive ? Colors.green : Colors.red,
                  isPositive ? Colors.green.shade700 : Colors.red.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  isPositive ? 'Net Profit' : 'Net Loss',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : ''}$currency ${netAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_incomeCount} income, ${_expenseCount} expense',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Income',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currency ${_totalIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '$_incomeCount transactions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Expense',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currency ${_totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '$_expenseCount transactions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_monthlyData.isNotEmpty)
            BarChartWidget(
              data: _monthlyData,
              currency: currency,
              isDark: isDark,
              showIncomeExpense: true,
            ),
          const SizedBox(height: 16),

          const Text(
            'Monthly Breakdown',
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
                        Text(
                          '+$currency ${income.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-$currency ${expense.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              fontSize: 12,
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
