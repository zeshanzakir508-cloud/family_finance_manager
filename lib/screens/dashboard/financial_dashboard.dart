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
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/app_config.dart';
import '../owner/owner_dashboard.dart';

class FinancialDashboard extends StatefulWidget {
  const FinancialDashboard({super.key});

  @override
  State<FinancialDashboard> createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<FinancialDashboard> {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  String _userName = 'User';
  int _selectedPeriod = 1; // 0: Week, 1: Month, 2: Year
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _selectedChartTab = 0; // 0: Spending, 1: Income vs Expense

  // Colors for categories
  final List<Color> _categoryColors = [
    const Color(0xFF1A73E8),  // Blue
    const Color(0xFF34A853),  // Green
    const Color(0xFFEA4335),  // Red
    const Color(0xFFFBBC04),  // Yellow
    const Color(0xFF9C27B0),  // Purple
    const Color(0xFFFF6B6B),  // Coral
    const Color(0xFF4ECDC4),  // Teal
    const Color(0xFFFF9F43),  // Orange
    const Color(0xFF6C5CE7),  // Indigo
    const Color(0xFF00B894),  // Mint
  ];

  // Transaction category icons mapping
  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Utilities': Icons.electric_bolt,
    'Rent': Icons.home,
    'Healthcare': Icons.health_and_safety,
    'Education': Icons.school,
    'Salary': Icons.attach_money,
    'Investment': Icons.trending_up,
    'Gift': Icons.card_giftcard,
    'Travel': Icons.flight,
    'Insurance': Icons.security,
    'Groceries': Icons.shopping_cart,
    'Dining': Icons.restaurant,
    'Clothing': Icons.checkroom,
    'Electronics': Icons.computer,
    'Transfer': Icons.swap_horiz,
  };

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
  }

  void _loadData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    final userId = authService.userId;

    if (userId != null) {
      final user = DatabaseService.getUser(userId);
      if (user != null) {
        _userName = user.displayName;
      }

      // Get transactions based on mode
      if (modeProvider.isPersonalMode) {
        _transactions = DatabaseService.getUserTransactions(userId);
      } else {
        final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
        final family = familyProvider.currentFamily;
        if (family != null) {
          _transactions = DatabaseService.getFamilyTransactions(family.id!);
        } else {
          _transactions = [];
        }
      }

      _transactions.sort((a, b) => b.date!.compareTo(a.date!));
      _applyFilters();
      setState(() {});
    }
  }

  void _applyFilters() {
    final now = DateTime(_selectedYear, _selectedMonth);
    final dateRange = _getDateRange(now);

    _filteredTransactions = _transactions.where((transaction) {
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

    for (var t in _filteredTransactions) {
      if (t.type == 'income') {
        income += t.amount ?? 0;
      } else if (t.type == 'expense') {
        expense += t.amount ?? 0;
      }
    }

    _totalIncome = income;
    _totalExpense = expense;
    _balance = income - expense;
  }

  Map<String, DateTime>? _getDateRange(DateTime now) {
    switch (_selectedPeriod) {
      case 0: // Week
        final start = now.subtract(Duration(days: 7));
        final end = now;
        return {'start': start, 'end': end};
      case 1: // Month
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return {'start': start, 'end': end};
      case 2: // Year
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return {'start': start, 'end': end};
      default:
        return null;
    }
  }

  bool get _isOwner {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.userEmail == AppConfig.ownerEmail;
  }

  bool get _isModerator {
    final authService = Provider.of<AuthService>(context, listen: false);
    return AppConfig.isModerator(authService.userEmail);
  }

  bool get _hasAdminAccess {
    return _isOwner || _isModerator;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final modeProvider = Provider.of<ModeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinFam'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_hasAdminAccess)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerDashboard()),
                );
              },
              tooltip: 'Admin Panel',
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting
              _buildUserGreeting(),
              const SizedBox(height: 16),

              // Mode Switch
              _buildModeSwitch(modeProvider),
              const SizedBox(height: 16),

              // Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: 16),

              // Summary Cards
              _buildSummaryCards(),
              const SizedBox(height: 24),

              // Balance Card
              _buildBalanceCard(),
              const SizedBox(height: 24),

              // Charts Tabs
              _buildChartTabs(),
              const SizedBox(height: 16),

              // Chart Content
              _buildChartContent(),
              const SizedBox(height: 24),

              // Recent Transactions
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-transaction');
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserGreeting() {
    final date = DateTime.now();
    final currentMonth = DateFormat('MMMM yyyy').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $_userName! 👋',
            style: AppTheme.headingStyle.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                currentMonth,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: modeProvider.isPersonalMode
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '👤 Personal',
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: modeProvider.isFamilyMode
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '👨‍👩‍👦 Family',
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
          _buildPeriodButton('Week', 0),
          _buildPeriodButton('Month', 1),
          _buildPeriodButton('Year', 2),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = index;
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Income',
            amount: _totalIncome,
            color: Colors.green,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Expenses',
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
      padding: const EdgeInsets.all(12),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTheme.captionStyle,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Helpers.formatCurrency(amount),
            style: AppTheme.headingStyle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isPositive = _balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Balance',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Helpers.formatCurrency(_balance),
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 24,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPositive ? '✅ Positive' : '⚠️ Negative',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTabs() {
    final tabs = ['Spending', 'Income vs Expense'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedChartTab == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedChartTab = index;
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

  Widget _buildChartContent() {
    if (_filteredTransactions.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: const Center(
          child: Text(
            'No data to show charts\nAdd some transactions first',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_selectedChartTab == 0) {
      return _buildSpendingPieChart();
    } else {
      return _buildIncomeExpenseBarChart();
    }
  }

  Widget _buildSpendingPieChart() {
    // Group by category for expenses only
    final Map<String, double> categoryMap = {};
    for (var t in _filteredTransactions) {
      if (t.type == 'expense' && t.category != null) {
        categoryMap[t.category!] =
            (categoryMap[t.category!] ?? 0) + (t.amount ?? 0);
      }
    }

    final entries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: const Center(
          child: Text(
            'No expense data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final totalExpense = entries.fold(0.0, (sum, e) => sum + e.value);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: entries.map((entry) {
                  final percentage = (entry.value / totalExpense) * 100;
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
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: entries.map((entry) {
                final colorIndex = entries.indexOf(entry) % _categoryColors.length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _categoryColors[colorIndex].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _categoryColors[colorIndex],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryDisplayName(entry.key),
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseBarChart() {
    // Group by month for the selected year
    final Map<int, Map<String, double>> monthlyData = {};

    for (var t in _filteredTransactions) {
      if (t.date == null) continue;
      final month = t.date!.month;
      if (!monthlyData.containsKey(month)) {
        monthlyData[month] = {'income': 0, 'expense': 0};
      }
      if (t.type == 'income') {
        monthlyData[month]!['income'] = (monthlyData[month]!['income'] ?? 0) + (t.amount ?? 0);
      } else if (t.type == 'expense') {
        monthlyData[month]!['expense'] = (monthlyData[month]!['expense'] ?? 0) + (t.amount ?? 0);
      }
    }

    final maxValue = monthlyData.values.fold<double>(0, (max, data) {
      final total = (data['income'] ?? 0) + (data['expense'] ?? 0);
      return total > max ? total : max;
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barGroups: monthlyData.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key - 1,
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
                  if (index >= 0 && index < 12) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _months[index],
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
    );
  }

  String _getCategoryDisplayName(String category) {
    return category.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  IconData _getCategoryIcon(String category) {
    return _categoryIcons[category] ?? Icons.category;
  }

  Widget _buildRecentTransactions() {
    final recent = _filteredTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTheme.subheadingStyle,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/reports');
              },
              child: Text(
                'See All',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'No transactions yet',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the + button to add your first transaction!',
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          )
        else
          ...recent.map((transaction) {
            return _buildTransactionTile(transaction);
          }).toList(),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    final icon = _getCategoryIcon(transaction.category ?? 'Other');
    final color = isIncome ? Colors.green : Colors.red;

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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
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
                  '${_getCategoryDisplayName(transaction.category ?? 'Other')} • ${transaction.formattedDate}',
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${transaction.formattedAmount}',
            style: AppTheme.bodyStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            Navigator.pushNamed(context, '/add-transaction');
            break;
          case 2:
            Navigator.pushNamed(context, '/reports');
            break;
          case 3:
            Navigator.pushNamed(context, '/family-management');
            break;
          case 4:
            Navigator.pushNamed(context, '/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart_outline),
          activeIcon: Icon(Icons.pie_chart),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.family_restroom_outlined),
          activeIcon: Icon(Icons.family_restroom),
          label: 'Family',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
