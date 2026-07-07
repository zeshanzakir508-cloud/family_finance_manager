// lib/screens/reports/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/report_model.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/pie_chart_widget.dart';
import 'widgets/bar_chart_widget.dart';
import 'widgets/line_chart_widget.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    final reportProvider = context.read<ReportProvider>();
    final report = reportProvider.savedReports.firstWhere(
      (r) => r.id == widget.reportId,
      orElse: () => throw Exception('Report not found'),
    );
    reportProvider.setCurrentReport(report);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final report = reportProvider.currentReport;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: const LoadingWidget(),
      );
    }

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: const Center(child: Text('Report not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(report.name),
        actions: [
          IconButton(
            icon: Icon(
              report.isFavorite ? Icons.star : Icons.star_border,
              color: report.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              reportProvider.toggleFavorite(report.id);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export_pdf') {
                // TODO: Export PDF
                CustomSnackBar.show(
                  context,
                  'PDF export coming soon',
                );
              } else if (value == 'export_csv') {
                // TODO: Export CSV
                CustomSnackBar.show(
                  context,
                  'CSV export coming soon',
                );
              } else if (value == 'share') {
                // TODO: Share
                CustomSnackBar.show(
                  context,
                  'Share coming soon',
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (report.description?.isNotEmpty ?? false)
                              Text(
                                report.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getReportColor(report.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getReportTypeDisplay(report.type),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getReportColor(report.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.dateRange,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${report.durationInDays} days',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated: ${report.generatedAt.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Report content based on type
            _buildReportContent(report, currencyProvider.currentCurrency, isDark),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      // TODO: Export PDF
                    },
                    text: 'Export PDF',
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                    icon: Icons.picture_as_pdf,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      // TODO: Export CSV
                    },
                    text: 'Export CSV',
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                    icon: Icons.table_chart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(ReportModel report, String currency, bool isDark) {
    final data = report.data;

    switch (report.type) {
      case ReportType.spendingBreakdown:
        return _buildSpendingBreakdown(data, currency, isDark);
      case ReportType.incomeVsExpense:
        return _buildIncomeExpense(data, currency, isDark);
      case ReportType.monthlyTrends:
        return _buildMonthlyTrends(data, currency, isDark);
      case ReportType.categoryWise:
        return _buildCategoryWise(data, currency, isDark);
      case ReportType.cashFlow:
        return _buildCashFlow(data, currency, isDark);
      default:
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Report content not available'),
          ),
        );
    }
  }

  Widget _buildSpendingBreakdown(Map<String, dynamic> data, String currency, bool isDark) {
    final categories = data['categories'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Spending',
                '$currency ${data['totalExpense']?.toStringAsFixed(2) ?? '0.00'}',
                Colors.red,
              ),
              _buildSummaryItem(
                'Transactions',
                '${data['transactionCount'] ?? 0}',
                Colors.blue,
              ),
              _buildSummaryItem(
                'Categories',
                '${data['categoryCount'] ?? 0}',
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pie chart
        if (categories != null && categories.isNotEmpty)
          PieChartWidget(
            data: categories,
            currency: currency,
            isDark: isDark,
          ),
        const SizedBox(height: 16),

        // Top categories list
        const Text(
          'Top Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._getTopCategories(categories, 5).map((entry) {
          final percentage = data['totalExpense'] > 0
              ? (entry.value / data['totalExpense'] * 100)
              : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$currency ${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIncomeExpense(Map<String, dynamic> data, String currency, bool isDark) {
    final netAmount = (data['netAmount'] ?? 0.0).toDouble();
    final isPositive = netAmount >= 0;

    return Column(
      children: [
        // Net amount
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
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isPositive ? '+' : ''}$currency $netAmount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Income vs Expense
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${(data['totalIncome'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${data['incomeCount'] ?? 0} transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Expense',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${(data['totalExpense'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '${data['expenseCount'] ?? 0} transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bar chart
        BarChartWidget(
          data: {
            'Income': data['totalIncome'] ?? 0.0,
            'Expense': data['totalExpense'] ?? 0.0,
          },
          currency: currency,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMonthlyTrends(Map<String, dynamic> data, String currency, bool isDark) {
    final monthlyData = data['monthlyData'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Best Month',
                data['bestMonth'] ?? '-',
                Colors.green,
              ),
              _buildSummaryItem(
                'Worst Month',
                data['worstMonth'] ?? '-',
                Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Line chart
        if (monthlyData != null)
          LineChartWidget(
            data: monthlyData,
            currency: currency,
            isDark: isDark,
          ),
        const SizedBox(height: 16),

        // Monthly table
        const Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...monthlyData?.entries.toList() ?? [].map((entry) {
          final values = entry.value as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    entry.key,
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
                        'Income: $currency ${(values['income'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expense: $currency ${(values['expense'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Net: $currency ${(values['net'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (values['net'] ?? 0.0) >= 0
                              ? Colors.green
                              : Colors.red,
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
    );
  }

  Widget _buildCategoryWise(Map<String, dynamic> data, String currency, bool isDark) {
    final categories = data['categories'] as Map<String, dynamic>?;

    return Column(
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Spending',
                '$currency ${data['totalSpending']?.toStringAsFixed(2) ?? '0.00'}',
                Colors.red,
              ),
              _buildSummaryItem(
                'Categories',
                '${data['categoryCount'] ?? 0}',
                Colors.blue,
              ),
              _buildSummaryItem(
                'Transactions',
                '${data['transactionCount'] ?? 0}',
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category list with details
        if (categories != null)
          ...categories.entries.map((entry) {
            final values = entry.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$currency ${(values['total'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${values['count'] ?? 0} transactions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Avg: $currency ${(values['average'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Max: $currency ${(values['max'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCashFlow(Map<String, dynamic> data, String currency, bool isDark) {
    final monthlyData = data['monthlyData'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Final Balance',
                '$currency ${(data['finalBalance'] ?? 0.0).toStringAsFixed(2)}',
                (data['finalBalance'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
              ),
              _buildSummaryItem(
                'Period',
                '${data['duration'] ?? 0} days',
                Colors.blue,
              ),
              _buildSummaryItem(
                'Transactions',
                '${data['transactionCount'] ?? 0}',
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cash flow trend
        if (monthlyData != null)
          LineChartWidget(
            data: monthlyData,
            currency: currency,
            isDark: isDark,
            showNet: true,
          ),
        const SizedBox(height: 16),

        // Monthly cash flow
        const Text(
          'Monthly Cash Flow',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...monthlyData?.entries.toList() ?? [].map((entry) {
          final values = entry.value as Map<String, dynamic>;
          final net = (values['net'] ?? 0.0).toDouble();
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    entry.key,
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
                        'Income: $currency ${(values['income'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expense: $currency ${(values['expense'] ?? 0.0).toStringAsFixed(2)}',
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
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, double>> _getTopCategories(Map<String, dynamic>? categories, int limit) {
    if (categories == null) return [];
    final entries = categories.entries
        .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.spendingBreakdown:
        return Colors.blue;
      case ReportType.incomeVsExpense:
        return Colors.green;
      case ReportType.monthlyTrends:
        return Colors.orange;
      case ReportType.categoryWise:
        return Colors.purple;
      case ReportType.budgetPerformance:
        return Colors.teal;
      case ReportType.cashFlow:
        return Colors.cyan;
      case ReportType.profitLoss:
        return Colors.red;
      case ReportType.yearOverYear:
        return Colors.indigo;
    }
  }

  String _getReportTypeDisplay(ReportType type) {
    switch (type) {
      case ReportType.spendingBreakdown:
        return 'Spending';
      case ReportType.incomeVsExpense:
        return 'Income/Expense';
      case ReportType.monthlyTrends:
        return 'Trends';
      case ReportType.categoryWise:
        return 'Categories';
      case ReportType.budgetPerformance:
        return 'Budget';
      case ReportType.cashFlow:
        return 'Cash Flow';
      case ReportType.profitLoss:
        return 'Profit/Loss';
      case ReportType.yearOverYear:
        return 'Year-over-Year';
    }
  }
}
