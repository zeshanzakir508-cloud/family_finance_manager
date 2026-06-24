import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction_model.dart';
import '../../models/user_profile.dart';
import '../../utils/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'monthly'; // monthly, yearly, custom
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();
  int _selectedTab = 0; // 0: Overview, 1: Categories, 2: Trends

  // Filters
  String? _selectedType; // income, expense, all
  String? _selectedCategory;

  late List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final box = Hive.box<TransactionModel>('transactions');
    _allTransactions = box.values.toList();
    _applyFilters();
  }

  void _applyFilters() {
    final now = DateTime.now();
    final dateRange = _getDateRange();

    _filteredTransactions = _allTransactions.where((transaction) {
      // Date filter
      if (transaction.date == null) return false;
      if (dateRange != null) {
        if (transaction.date!.isBefore(dateRange['start']!) ||
            transaction.date!.isAfter(dateRange['end']!)) {
          return false;
        }
      }

      // Type filter
      if (_selectedType != null && _selectedType != 'all') {
        final type = _selectedType == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        if (transaction.type != type) return false;
      }

      // Category filter
      if (_selectedCategory != null && _selectedCategory != 'all') {
        if (transaction.category != _selectedCategory) return false;
      }

      return true;
    }).toList();

    // Calculate totals
    double income = 0;
    double expense = 0;

    for (var transaction in _filteredTransactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount ?? 0;
      } else {
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
      case 'custom':
        // Custom range - you can implement date pickers
        return null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          _buildPeriodButton('monthly', 'Monthly'),
          _buildPeriodButton('yearly', 'Yearly'),
          _buildPeriodButton('custom', 'Custom'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
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
          if (_selectedPeriod == 'monthly' || _selectedPeriod == 'yearly')
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
        ],
      ),
    );
  }

  String _getDateRangeLabel() {
    switch (_selectedPeriod) {
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedMonth);
      case 'yearly':
        return DateFormat('yyyy').format(_selectedYear);
      case 'custom':
        return 'Custom Range';
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
        DropdownButtonHideUnderline(
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
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        // Category Filter
        DropdownButtonHideUnderline(
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
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
    return Row(
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
            title: 'Total Expense',
            amount: _totalExpense,
            color: Colors.red,
            icon: Icons.arrow_downward,
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
            '\$${amount.toStringAsFixed(2)}',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Overview', 'Categories', 'Trends'];
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
              padding: const EdgeInsets.symmetric(vertical: 12),
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
        // Balance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _balance >= 0
                  ? [Colors.green, Colors.green.shade700]
                  : [Colors.red, Colors.red.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Net Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredTransactions.length} transactions',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Transactions
        Text(
          'Recent Transactions',
          style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        ..._filteredTransactions.take(5).map((transaction) {
          return _buildTransactionItem(transaction);
        }),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'No description',
                  style: AppTheme.bodyStyle,
                ),
                Text(
                  transaction.categoryDisplayName,
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${transaction.formattedAmount}',
            style: AppTheme.bodyStyle.copyWith(
              color: transaction.typeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState('No transactions to analyze');
    }

    // Group by category
    final categoryMap = <String, double>{};
    for (var transaction in _filteredTransactions) {
      if (transaction.category != null) {
        categoryMap[transaction.category!] =
            (categoryMap[transaction.category!] ?? 0) + (transaction.amount ?? 0);
      }
    }

    final entries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: entries.take(6).map((entry) {
                final total = _totalIncome + _totalExpense;
                final percentage = total > 0 ? (entry.value / total) : 0;
                return PieChartSectionData(
                  value: entry.value,
                  title: '${(percentage * 100).toStringAsFixed(1)}%',
                  color: _getColorForCategory(entry.key),
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

        // Category List
        ...entries.map((entry) {
          final total = _totalIncome + _totalExpense;
          final percentage = total > 0 ? (entry.value / total) : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(entry.key),
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
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${(percentage * 100).toStringAsFixed(1)}%)',
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getColorForCategory(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.lime,
    ];
    final index = category.hashCode % colors.length;
    return colors[index];
  }

  Widget _buildTrendsTab() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState('No data available for trends');
    }

    // Group by month
    final monthMap = <String, Map<String, double>>{};
    for (var transaction in _filteredTransactions) {
      if (transaction.date == null) continue;
      final monthKey = DateFormat('MMM yyyy').format(transaction.date!);
      if (!monthMap.containsKey(monthKey)) {
        monthMap[monthKey] = {'income': 0, 'expense': 0};
      }
      if (transaction.type == TransactionType.income) {
        monthMap[monthKey]!['income'] =
            (monthMap[monthKey]!['income'] ?? 0) + (transaction.amount ?? 0);
      } else {
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
          style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Bar Chart
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

        // Legend
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
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
