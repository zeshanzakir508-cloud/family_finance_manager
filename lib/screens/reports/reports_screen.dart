import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/mode_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'monthly';
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();

  List<TransactionModel> _filteredTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

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

    List<TransactionModel> allTransactions;

    if (modeProvider.isPersonalMode) {
      allTransactions = DatabaseService.getUserTransactions(userId);
    } else {
      allTransactions = DatabaseService.getAllTransactions();
    }

    _applyFilters(allTransactions);
  }

  void _applyFilters(List<TransactionModel> allTransactions) {
    final dateRange = _getDateRange();

    _filteredTransactions = allTransactions.where((transaction) {
      if (transaction.date == null) return false;
      if (dateRange != null) {
        if (transaction.date!.isBefore(dateRange['start']!) ||
            transaction.date!.isAfter(dateRange['end']!)) {
          return false;
        }
      }
      return true;
    }).toList();

    double income = 0;
    double expense = 0;

    for (var transaction in _filteredTransactions) {
      if (transaction.type == 'income') {
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModeSwitch(modeProvider),
            const SizedBox(height: 16),
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 16),
            _buildTransactionList(),
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
          _buildPeriodButton('monthly', 'Monthly'),
          _buildPeriodButton('yearly', 'Yearly'),
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
            _loadData();
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
          const Icon(
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
                    _loadData();
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
                    _loadData();
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
      default:
        return 'All Time';
    }
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

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No transactions found',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Try adding some transactions first',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions (${_filteredTransactions.length})',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredTransactions.length > 10 ? 10 : _filteredTransactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final transaction = _filteredTransactions[index];
            return _buildTransactionTile(transaction);
          },
        ),
        if (_filteredTransactions.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing 10 of ${_filteredTransactions.length} transactions',
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
        '${transaction.memberName ?? 'You'} • ${transaction.categoryDisplay}',
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
}
