// lib/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/report_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;

  final List<ReportType> _reportTypes = [
    ReportType.spendingBreakdown,
    ReportType.incomeVsExpense,
    ReportType.monthlyTrends,
    ReportType.categoryWise,
    ReportType.budgetPerformance,
    ReportType.cashFlow,
    ReportType.profitLoss,
    ReportType.yearOverYear,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final reportProvider = context.read<ReportProvider>();
    await reportProvider.loadSavedReports(auth.userId);
    setState(() => _isLoading = false);
  }

  Future<void> _refreshData() async {
    await _loadReports();
  }

  void _showGenerateReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Generate Report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._reportTypes.map((type) {
                return ListTile(
                  leading: Icon(
                    _getReportIcon(type),
                    color: _getReportColor(type),
                  ),
                  title: Text(_getReportName(type)),
                  subtitle: Text(_getReportDescription(type)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _generateReport(type);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateReport(ReportType type) async {
    final auth = context.read<AuthProvider>();
    final reportProvider = context.read<ReportProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    // Get date range (default: last 30 days)
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    ReportModel? report;

    switch (type) {
      case ReportType.spendingBreakdown:
        report = await reportProvider.generateSpendingBreakdown(
          userId: auth.userId,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      case ReportType.incomeVsExpense:
        report = await reportProvider.generateIncomeVsExpense(
          userId: auth.userId,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      case ReportType.monthlyTrends:
        report = await reportProvider.generateMonthlyTrends(
          userId: auth.userId,
          year: DateTime.now().year,
        );
        break;
      case ReportType.categoryWise:
        report = await reportProvider.generateCategoryWiseSpending(
          userId: auth.userId,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      case ReportType.cashFlow:
        report = await reportProvider.generateCashFlow(
          userId: auth.userId,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      default:
        // TODO: Implement other report types
        CustomSnackBar.show(
          context,
          'Report type not implemented yet',
          isError: true,
        );
        return;
    }

    if (report != null && mounted) {
      final id = await reportProvider.saveReport(report);
      if (id != null) {
        CustomSnackBar.show(
          context,
          'Report generated successfully! 📊',
        );
        await _refreshData();
      }
    }
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.spendingBreakdown:
        return Icons.pie_chart;
      case ReportType.incomeVsExpense:
        return Icons.show_chart;
      case ReportType.monthlyTrends:
        return Icons.trending_up;
      case ReportType.categoryWise:
        return Icons.category;
      case ReportType.budgetPerformance:
        return Icons.speed;
      case ReportType.cashFlow:
        return Icons.assessment;
      case ReportType.profitLoss:
        return Icons.attach_money;
      case ReportType.yearOverYear:
        return Icons.calendar_today;
    }
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

  String _getReportName(ReportType type) {
    switch (type) {
      case ReportType.spendingBreakdown:
        return 'Spending Breakdown';
      case ReportType.incomeVsExpense:
        return 'Income vs Expense';
      case ReportType.monthlyTrends:
        return 'Monthly Trends';
      case ReportType.categoryWise:
        return 'Category-wise Spending';
      case ReportType.budgetPerformance:
        return 'Budget Performance';
      case ReportType.cashFlow:
        return 'Cash Flow';
      case ReportType.profitLoss:
        return 'Profit/Loss';
      case ReportType.yearOverYear:
        return 'Year-over-Year';
    }
  }

  String _getReportDescription(ReportType type) {
    switch (type) {
      case ReportType.spendingBreakdown:
        return 'View spending by category';
      case ReportType.incomeVsExpense:
        return 'Compare income and expenses';
      case ReportType.monthlyTrends:
        return 'Track monthly spending patterns';
      case ReportType.categoryWise:
        return 'Detailed category analysis';
      case ReportType.budgetPerformance:
        return 'Monitor budget progress';
      case ReportType.cashFlow:
        return 'Analyze cash flow over time';
      case ReportType.profitLoss:
        return 'View profit/loss summary';
      case ReportType.yearOverYear:
        return 'Compare year-over-year trends';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Reports'),
            Tab(text: 'Favorites'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showGenerateReportDialog,
            tooltip: 'Generate Report',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildReportList(
              context,
              reportProvider.savedReports,
              currencyProvider.currentCurrency,
              isDark,
              false,
            ),
            _buildReportList(
              context,
              reportProvider.favoriteReports,
              currencyProvider.currentCurrency,
              isDark,
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(
    BuildContext context,
    List<ReportModel> reports,
    String currency,
    bool isDark,
    bool isFavorites,
  ) {
    if (reports.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.analytics,
        title: isFavorites ? 'No Favorite Reports' : 'No Reports',
        description: isFavorites
            ? 'Your favorite reports will appear here'
            : 'Generate your first report to get started',
        buttonText: isFavorites ? null : 'Generate Report',
        onPressed: isFavorites ? null : _showGenerateReportDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                        Row(
                          children: [
                            Icon(
                              _getReportIcon(report.type),
                              color: _getReportColor(report.type),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              report.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (report.description?.isNotEmpty ?? false)
                          Text(
                            report.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      report.isFavorite ? Icons.star : Icons.star_border,
                      color: report.isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      // ✅ FIXED: Using context.read<ReportProvider>()
                      context.read<ReportProvider>().toggleFavorite(report.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.dateRange,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${report.durationInDays} days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () {
                        // ✅ FIXED: Using context.read<ReportProvider>()
                        context.read<ReportProvider>().setCurrentReport(report);
                        Navigator.pushNamed(
                          context,
                          '/report_detail',
                          arguments: report.id,
                        );
                      },
                      text: 'View Report',
                      type: ButtonType.outline,
                      size: ButtonSize.small,
                      icon: Icons.visibility,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Share report
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showReportOptions(report);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportOptions(ReportModel report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Report'),
              onTap: () {
                Navigator.pop(context);
                context.read<ReportProvider>().setCurrentReport(report);
                Navigator.pushNamed(
                  context,
                  '/report_detail',
                  arguments: report.id,
                );
              },
            ),
            ListTile(
              leading: Icon(
                report.isFavorite ? Icons.star : Icons.star_border,
              ),
              title: Text(report.isFavorite ? 'Remove Favorite' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                context.read<ReportProvider>().toggleFavorite(report.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export PDF'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Export PDF
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export CSV'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Export CSV
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Report', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(report);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Delete "${report.name}" report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<ReportProvider>().deleteReport(report.id);
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'Report deleted successfully',
                );
                await _refreshData();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
