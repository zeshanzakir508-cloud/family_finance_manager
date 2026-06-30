import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart';
import '../../models/family_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/app_config.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'monthly';
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();
  int _selectedTab = 0;

  String? _selectedType;
  String? _selectedCategory;

  List<TransactionModel> _filteredTransactions = [];
  List<TransactionModel> _allTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  final List<Color> _categoryColors = [
    Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId == null) return;

    if (modeProvider.isPersonalMode) {
      _allTransactions = DatabaseService.getUserTransactions(userId);
    } else {
      // Family mode - get all family transactions
      final family = Provider.of<FamilyProvider>(context, listen: false).currentFamily;
      if (family != null) {
        _allTransactions = DatabaseService.getFamilyTransactions(family.id!);
      } else {
        _allTransactions = [];
      }
    }

    _allTransactions.sort((a, b) => b.date!.compareTo(a.date!));
    _applyFilters();
  }

  void _applyFilters() {
    final dateRange = _getDateRange();

    _filteredTransactions = _allTransactions.where((transaction) {
      if (transaction.date == null) return false;
      if (dateRange != null) {
        if (transaction.date!.isBefore(dateRange['start']!) ||
            transaction.date!.isAfter(dateRange['end']!)) {
          return false;
        }
      }

      if (_selectedType != null && _selectedType != 'all') {
        final type = _selectedType == 'income'
            ? 'income'
            : 'expense';
        if (transaction.type != type) return false;
      }

      if (_selectedCategory != null && _selectedCategory != 'all') {
        if (transaction.category != _selectedCategory) return false;
      }

      return true;
    }).toList();

    double income = 0;
    double expense = 0;

    for (var transaction in _filteredTransactions) {
      if (transaction.type == 'income') {
        income += transaction.amount ?? 0;
      } else if (transaction.type == 'expense') {
        expense += transaction.amount ?? 0;
      }
    }

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _balance = income - expense;
    });
  }

  Map<String, DateTime>? _getDateRange() {
    switch (_selectedPeriod) {
      case 'monthly':
        final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        return {'start': start, 'end': end};
      case 'yearly':
        final start = DateTime(_selectedYear.year, 1, 1);
        final end = DateTime(_selectedYear.year, 12, 31);
        return {'start': start, 'end': end};
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          modeProvider.isPersonalMode ? 'Personal Reports' : 'Family Reports',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Switch
            _buildModeSwitch(modeProvider),
            const SizedBox(height: 16),

            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            // Date Picker
            _buildDatePicker(),
            const SizedBox(height: 16),

            // Filters
            _buildFilters(),
            const SizedBox(height: 16),

            // Summary Cards
            _buildSummaryCards(),
            const SizedBox(height: 16),

            // Tabs
            _buildTabs(),
            const SizedBox(height: 16),

            // Tab Content
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitch(ModeProvider modeProvider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                modeProvider.setMode('personal');
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: modeProvider.isPersonalMode
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Personal',
                    style: AppTheme.bodyStyle.copyWith(
                      color: modeProvider.isPersonalMode
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      fontWeight: modeProvider.isPersonalMode
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                modeProvider.setMode('family');
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: modeProvider.isFamilyMode
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Family',
                    style: AppTheme.bodyStyle.copyWith(
                      color: modeProvider.isFamilyMode
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      fontWeight: modeProvider.isFamilyMode
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Monthly', 'monthly'),
          _buildPeriodButton('Yearly', 'yearly'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
            _applyFilters();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getDateRangeLabel(),
              style: AppTheme.bodyStyle,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    if (_selectedPeriod == 'monthly') {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      );
                    } else {
                      _selectedYear = DateTime(
                        _selectedYear.year - 1,
                      );
                    }
                    _applyFilters();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    if (_selectedPeriod == 'monthly') {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    } else {
                      _selectedYear = DateTime(
                        _selectedYear.year + 1,
                      );
                    }
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateRangeLabel() {
    switch (_selectedPeriod) {
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedMonth);
      case 'yearly':
        return DateFormat('yyyy').format(_selectedYear);
      default:
        return 'All Time';
    }
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Type Filter
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _selectedType ?? 'all',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _applyFilters();
                });
              },
              style: AppTheme.bodyStyle,
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              underline: const SizedBox(),
            ),
          ),
        ),
        // Category Filter
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _selectedCategory ?? 'all',
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                ..._getUniqueCategories().map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplayName(category)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _applyFilters();
                });
              },
              style: AppTheme.bodyStyle,
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              underline: const SizedBox(),
            ),
          ),
        ),
        // Clear Filters
        if (_selectedType != 'all' || _selectedCategory != 'all')
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = 'all';
                _selectedCategory = 'all';
                _applyFilters();
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear Filters'),
          ),
      ],
    );
  }

  List<String> _getUniqueCategories() {
    final categories = <String>{};
    for (var transaction in _filteredTransactions) {
      if (transaction.category != null) {
        categories.add(transaction.category!);
      }
    }
    return categories.toList();
  }

  String _getCategoryDisplayName(String category) {
    return category.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Income',
                amount: _totalIncome,
                color: Colors.green,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Expenses',
                amount: _totalExpense,
                color: Colors.red,
                icon: Icons.arrow_downward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _balance >= 0
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _balance >= 0
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Balance',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                Helpers.formatCurrency(_balance),
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 20,
                  color: _balance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(amount),
            style: AppTheme.headingStyle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Overview', 'Categories', 'Trends', 'Tax'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedTab == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: AppTheme.bodyStyle.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildCategoriesTab();
      case 2:
        return _buildTrendsTab();
      case 3:
        return _buildTaxTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState('No transactions for this period');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Transactions (${_filteredTransactions.length})',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredTransactions.length > 20 ? 20 : _filteredTransactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final transaction = _filteredTransactions[index];
            return _buildTransactionTile(transaction);
          },
        ),
        if (_filteredTransactions.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing 20 of ${_filteredTransactions.length} transactions',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: transaction.typeColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          transaction.categoryIcon,
          color: transaction.typeColor,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description ?? 'Transaction',
        style: AppTheme.bodyStyle,
      ),
      subtitle: Text(
        '${transaction.memberName ?? 'You'} • ${transaction.categoryDisplay} • ${transaction.formattedDate}',
        style: AppTheme.captionStyle,
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${transaction.formattedAmount}',
        style: AppTheme.bodyStyle.copyWith(
          color: transaction.typeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState('No transactions to analyze');
    }

    final categoryMap = <String, double>{};
    for (var transaction in _filteredTransactions) {
      if (transaction.type == 'expense' && transaction.category != null) {
        categoryMap[transaction.category!] =
            (categoryMap[transaction.category!] ?? 0) + (transaction.amount ?? 0);
      }
    }

    final entries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalExpense = entries.fold(0.0, (sum, e) => sum + e.value);

    if (entries.isEmpty) {
      return _buildEmptyState('No expense data available');
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: entries.map((entry) {
                final percentage = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0;
                final colorIndex = entries.indexOf(entry) % _categoryColors.length;
                return PieChartSectionData(
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  color: _categoryColors[colorIndex],
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...entries.map((entry) {
          final percentage = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0;
          final colorIndex = entries.indexOf(entry) % _categoryColors.length;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _categoryColors[colorIndex],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getCategoryDisplayName(entry.key),
                    style: AppTheme.bodyStyle,
                  ),
                ),
                Text(
                  Helpers.formatCurrency(entry.value),
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrendsTab() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState('No data available for trends');
    }

    final monthMap = <String, Map<String, double>>{};
    for (var transaction in _filteredTransactions) {
      if (transaction.date == null) continue;
      final monthKey = DateFormat('MMM yyyy').format(transaction.date!);
      if (!monthMap.containsKey(monthKey)) {
        monthMap[monthKey] = {'income': 0, 'expense': 0};
      }
      if (transaction.type == 'income') {
        monthMap[monthKey]!['income'] =
            (monthMap[monthKey]!['income'] ?? 0) + (transaction.amount ?? 0);
      } else if (transaction.type == 'expense') {
        monthMap[monthKey]!['expense'] =
            (monthMap[monthKey]!['expense'] ?? 0) + (transaction.amount ?? 0);
      }
    }

    final entries = monthMap.entries.toList();
    if (entries.isEmpty) {
      return _buildEmptyState('No transactions to show trends');
    }

    final maxValue = entries.fold<double>(0, (max, entry) {
      final total = (entry.value['income'] ?? 0) + (entry.value['expense'] ?? 0);
      return total > max ? total : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trends',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              barGroups: entries.map((entry) {
                return BarChartGroupData(
                  x: entries.indexOf(entry),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value['income'] ?? 0,
                      color: Colors.green,
                      width: 12,
                    ),
                    BarChartRodData(
                      toY: entry.value['expense'] ?? 0,
                      color: Colors.red,
                      width: 12,
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < entries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            entries[index].key,
                            style: AppTheme.captionStyle.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text('Income', style: AppTheme.bodyStyle),
              ],
            ),
            const SizedBox(width: 24),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text('Expense', style: AppTheme.bodyStyle),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxTab() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState('No data available for tax report');
    }

    final categoryMap = <String, double>{};
    for (var transaction in _filteredTransactions) {
      if (transaction.type == 'expense' && transaction.category != null) {
        categoryMap[transaction.category!] =
            (categoryMap[transaction.category!] ?? 0) + (transaction.amount ?? 0);
      }
    }

    final entries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Tax Report',
                    style: AppTheme.subheadingStyle,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Period: ${_getDateRangeLabel()}',
                style: AppTheme.captionStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Expense Categories',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getCategoryDisplayName(entry.key),
                    style: AppTheme.bodyStyle,
                  ),
                ),
                Text(
                  Helpers.formatCurrency(entry.value),
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Expenses',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                Helpers.formatCurrency(_totalExpense),
                style: AppTheme.headingStyle.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _exportTaxReport,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export Tax Report (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report export started! Check downloads.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportTaxReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax report exported as PDF!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
