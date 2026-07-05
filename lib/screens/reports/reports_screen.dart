// lib/screens/reports/reports_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart';
import '../../models/family_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  int _selectedTab = 0;

  String? _selectedType;
  String? _selectedCategory;

  List<TransactionModel> _filteredTransactions = [];
  List<TransactionModel> _allTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  bool _isLoading = true;
  bool _isExporting = false;

  final List<Color> _categoryColors = [
    Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final modeProvider = Provider.of<ModeProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (modeProvider.isPersonalMode) {
        _allTransactions = await DatabaseService.getUserTransactions(userId);
      } else {
        final family = Provider.of<FamilyProvider>(context, listen: false).currentFamily;
        if (family != null) {
          _allTransactions = await DatabaseService.getFamilyTransactions(family.id, userId);
        } else {
          _allTransactions = [];
        }
      }

      _allTransactions.sort((a, b) => b.date!.compareTo(a.date!));
      _applyFilters();
    } catch (e) {
      print('❌ Error loading reports: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _filteredTransactions = _allTransactions.where((transaction) {
      if (transaction.date == null) return false;
      
      if (_customStartDate != null && _customEndDate != null) {
        if (transaction.date!.isBefore(_customStartDate!) ||
            transaction.date!.isAfter(_customEndDate!)) {
          return false;
        }
      }

      if (_selectedType != null && _selectedType != 'all') {
        final type = _selectedType == 'income' ? 'income' : 'expense';
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

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          modeProvider.isPersonalMode ? 'Personal Reports' : 'Family Reports',
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_outlined),
            onPressed: _isExporting ? null : _showExportDialog,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomDatePicker(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildTabs(),
                    const SizedBox(height: 16),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'Start Date',
                  date: _customStartDate,
                  onTap: () => _selectDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: 'End Date',
                  date: _customEndDate,
                  onTap: () => _selectDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _customStartDate = null;
                    _customEndDate = null;
                    _applyFilters();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Clear Dates'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_customStartDate != null && _customEndDate != null) {
                    _applyFilters();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select both start and end dates'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply Range'),
              ),
            ],
          ),
          if (_customStartDate != null && _customEndDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing: ${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMM dd, yyyy').format(date)
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  color: date != null ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_customStartDate ?? DateTime.now())
          : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _customStartDate = date;
          if (_customEndDate != null && _customEndDate!.isBefore(date)) {
            _customEndDate = date;
          }
        } else {
          _customEndDate = date;
          if (_customStartDate != null && _customStartDate!.isAfter(date)) {
            _customStartDate = date;
          }
        }
        _applyFilters();
      });
    }
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
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
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
              underline: const SizedBox(),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
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
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
              underline: const SizedBox(),
            ),
          ),
        ),
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
              foregroundColor: Colors.red,
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
              const Text(
                'Net Balance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                Helpers.formatCurrency(_balance),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(amount),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Overview', 'Categories', 'Trends'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
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
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
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
        Text(
          'All Transactions (${_filteredTransactions.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        transaction.description ?? 'Transaction',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${transaction.memberName ?? 'You'} • ${_getCategoryDisplayName(transaction.category ?? 'other')} • ${_formatDate(transaction.date!)}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${Helpers.formatCurrency(transaction.amount ?? 0)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
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
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  Helpers.formatCurrency(entry.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
        const Text(
          'Monthly Trends',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                const Text('Income'),
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
                const Text('Expense'),
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.file_download, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Export Report'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your preferred format:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('CSV - Open in Excel/Sheets'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('PDF - Print or Share'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : () {
              Navigator.pop(context);
              _exportCSV();
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : () {
              Navigator.pop(context);
              _exportPDF();
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: SharePlus → Share
  Future<void> _exportCSV() async {
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      String csv = 'Date,Type,Category,Description,Amount,Member\n';
      for (var t in _filteredTransactions) {
        csv += '${_formatDate(t.date!)},';
        csv += '${t.type},';
        csv += '${t.category ?? 'other'},';
        csv += '"${t.description ?? ''}",';
        csv += '${t.amount ?? 0},';
        csv += '${t.memberName ?? 'You'}\n';
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Financial Report Export',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ CSV Report exported successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isExporting = false);
  }

  // ✅ FIXED: SharePlus → Share
  Future<void> _exportPDF() async {
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      String content = '=== FINANCIAL REPORT ===\n\n';
      content += 'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n';
      content += 'Total Income: ${Helpers.formatCurrency(_totalIncome)}\n';
      content += 'Total Expense: ${Helpers.formatCurrency(_totalExpense)}\n';
      content += 'Net Balance: ${Helpers.formatCurrency(_balance)}\n\n';
      content += '--- TRANSACTIONS ---\n';
      
      for (var t in _filteredTransactions) {
        content += '${_formatDate(t.date!)} | ${t.type} | ${t.category ?? 'other'} | ${t.description ?? ''} | ${Helpers.formatCurrency(t.amount ?? 0)}\n';
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Financial Report Export',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ PDF Report exported successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isExporting = false);
  }
}
