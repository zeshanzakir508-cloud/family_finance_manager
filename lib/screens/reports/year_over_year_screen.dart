// lib/screens/reports/year_over_year_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../models/transaction_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/bar_chart_widget.dart';

class YearOverYearScreen extends StatefulWidget {
  const YearOverYearScreen({Key? key}) : super(key: key);

  @override
  State<YearOverYearScreen> createState() => _YearOverYearScreenState();
}

class _YearOverYearScreenState extends State<YearOverYearScreen> {
  int _selectedYear = DateTime.now().year;
  int _compareYear = DateTime.now().year - 1;
  bool _isLoading = false;
  
  Map<String, Map<String, double>> _currentYearData = {};
  Map<String, Map<String, double>> _compareYearData = {};
  double _currentYearTotal = 0.0;
  double _compareYearTotal = 0.0;
  double _yearChange = 0.0;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: AuthProvider → AppAuthProvider
      final auth = context.read<AppAuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      final allTransactions = transactionProvider.allTransactions;
      
      _currentYearData = await _getYearlyData(allTransactions, _selectedYear);
      _currentYearTotal = _calculateTotal(_currentYearData);
      
      _compareYearData = await _getYearlyData(allTransactions, _compareYear);
      _compareYearTotal = _calculateTotal(_compareYearData);
      
      if (_compareYearTotal != 0) {
        _yearChange = ((_currentYearTotal - _compareYearTotal) / _compareYearTotal) * 100;
      } else {
        _yearChange = _currentYearTotal > 0 ? 100 : 0;
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

  Future<Map<String, Map<String, double>>> _getYearlyData(
    List<TransactionModel> transactions,
    int year,
  ) async {
    final yearlyData = <String, Map<String, double>>{};
    
    for (int month = 1; month <= 12; month++) {
      final monthKey = '$year-${month.toString().padLeft(2, '0')}';
      yearlyData[monthKey] = {'income': 0.0, 'expense': 0.0};
      
      for (var t in transactions) {
        if (t.date != null && t.date!.year == year && t.date!.month == month) {
          if (t.isIncome) {
            yearlyData[monthKey]!['income'] = 
                (yearlyData[monthKey]!['income'] ?? 0.0) + (t.amount ?? 0.0);
          } else if (t.isExpense) {
            yearlyData[monthKey]!['expense'] = 
                (yearlyData[monthKey]!['expense'] ?? 0.0) + (t.amount ?? 0.0);
          }
        }
      }
    }
    
    return yearlyData;
  }

  double _calculateTotal(Map<String, Map<String, double>> data) {
    double total = 0.0;
    for (var entry in data.entries) {
      total += (entry.value['income'] ?? 0.0) - (entry.value['expense'] ?? 0.0);
    }
    return total;
  }

  String _formatMonth(int month) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Year-over-Year Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport,
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
    final hasData = _currentYearData.isNotEmpty && _compareYearData.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildYearSelector('Current Year', _selectedYear, (year) {
                  setState(() {
                    _selectedYear = year;
                  });
                  _generateReport();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildYearSelector('Compare Year', _compareYear, (year) {
                  setState(() {
                    _compareYear = year;
                  });
                  _generateReport();
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      '$_selectedYear',
                      '$currency ${_currentYearTotal.toStringAsFixed(2)}',
                      Colors.blue,
                    ),
                    _buildSummaryItem(
                      '$_compareYear',
                      '$currency ${_compareYearTotal.toStringAsFixed(2)}',
                      Colors.grey,
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Change: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_yearChange >= 0 ? '+' : ''}${_yearChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _yearChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (hasData) ...[
            BarChartWidget(
              data: _currentYearData,
              compareData: _compareYearData,
              currency: currency,
              isDark: isDark,
              showYearOverYear: true,
            ),
            const SizedBox(height: 16),

            const Text(
              'Monthly Comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ..._currentYearData.entries.toList().map((entry) {
              final month = int.parse(entry.key.split('-')[1]);
              final currentValues = entry.value;
              final compareValues = _compareYearData[entry.key] ?? {'income': 0.0, 'expense': 0.0};
              
              final currentNet = (currentValues['income'] ?? 0.0) - (currentValues['expense'] ?? 0.0);
              final compareNet = (compareValues['income'] ?? 0.0) - (compareValues['expense'] ?? 0.0);
              final diff = currentNet - compareNet;
              final diffPercent = compareNet != 0 ? (diff / compareNet) * 100 : 0;

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
                      width: 50,
                      child: Text(
                        _formatMonth(month),
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
                            '$_selectedYear: $currency ${currentNet.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_compareYear: $currency ${compareNet.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: diff >= 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${diff >= 0 ? '+' : ''}${diffPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: diff >= 0 ? Colors.green : Colors.red,
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
          ] else ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data for selected years',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try selecting different years',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearSelector(String label, int year, ValueChanged<int> onChanged) {
    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: year,
            isExpanded: true,
            underline: const SizedBox(),
            items: List.generate(10, (index) => DateTime.now().year - index)
                .map((y) => DropdownMenuItem(
                      value: y,
                      child: Text(y.toString()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
