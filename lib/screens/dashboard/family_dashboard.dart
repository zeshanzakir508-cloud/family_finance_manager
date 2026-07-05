// lib/screens/dashboard/family_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard>
    with SingleTickerProviderStateMixin {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  FamilyModel? _currentFamily;
  late TabController _tabController;
  DateTime? _lastBackPress;
  String? _userId;

  final List<Color> _categoryColors = [
    Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      _userId = authService.userId;
      
      if (_userId == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please login again';
          _isLoading = false;
        });
        return;
      }

      _currentFamily = familyProvider.currentFamily;
      
      if (_currentFamily == null && familyProvider.families.isNotEmpty) {
        _currentFamily = familyProvider.families.first;
        familyProvider.setCurrentFamily(_currentFamily!);
      }

      if (_currentFamily == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No family found. Please create or join a family.';
          _isLoading = false;
        });
        return;
      }

      try {
        _transactions = await DatabaseService.getFamilyTransactions(
          _currentFamily!.id,
          _userId!,
        );
        _transactions.sort((a, b) => b.date?.compareTo(a.date ?? DateTime.now()) ?? 0);
        _applyFilters();
        setState(() {
          _hasError = false;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load transactions: $e';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredTransactions = _transactions;

    double income = 0;
    double expense = 0;
    for (var t in _filteredTransactions) {
      if (t.type == 'income') {
        income += t.amount ?? 0;
      } else if (t.type == 'expense') {
        expense += t.amount ?? 0;
      }
    }

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _balance = income - expense;
    });
  }

  void _navigateAndRefresh(String route) async {
    final result = await Navigator.pushNamed(context, route);
    if (result == true) {
      _loadData();
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            _currentFamily?.name ?? 'Family Dashboard',
            style: const TextStyle(fontSize: 18),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            _buildRoleBadge(),
            const SizedBox(width: 4),
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.family_restroom,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Family',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.pushNamed(context, '/family-management').then((_) => _loadData());
              },
              tooltip: 'Manage Family',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              tooltip: 'Settings',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Members'),
              Tab(text: 'Transfers'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  // ✅ FIXED: Icons.crown → Icons.star
  Widget _buildRoleBadge() {
    final authService = Provider.of<AuthService>(context);
    final role = authService.getCachedUserRole() ?? 'member';
    
    IconData icon;
    Color color;
    String label;
    
    switch (role) {
      case 'owner':
        icon = Icons.star;
        color = Colors.amber;
        label = '👑';
        break;
      case 'moderator':
        icon = Icons.shield;
        color = Colors.blue;
        label = '🛡️';
        break;
      default:
        return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_errorMessage.contains('No family found'))
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/family-management');
                  },
                  icon: const Icon(Icons.family_restroom),
                  label: const Text('Go to Family Management'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (_currentFamily == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Family Selected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a family from the management screen',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/family-management');
              },
              icon: const Icon(Icons.people),
              label: const Text('Manage Families'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMembersTab(),
          _buildTransfersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCards(),
          const SizedBox(height: 16),
          _buildChartsSection(),
          const SizedBox(height: 16),
          _buildCategoryBreakdown(),
          const SizedBox(height: 16),
          _buildRecentTransactions(),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildBalanceCards() {
    return Row(
      children: [
        _buildBalanceCard(
          'Family Balance',
          _balance,
          Icons.account_balance_wallet,
          _balance >= 0 ? Colors.blue : Colors.red,
        ),
        const SizedBox(width: 12),
        _buildBalanceCard(
          'Income',
          _totalIncome,
          Icons.arrow_upward,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildBalanceCard(
          'Expense',
          _totalExpense,
          Icons.arrow_downward,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              Helpers.formatCurrency(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: amount >= 0 ? Colors.black : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    final categoryData = _getCategoryData();
    final hasData = categoryData.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No spending data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sections: categoryData.entries.map((entry) {
                          final percentage = _totalExpense > 0
                              ? (entry.value / _totalExpense) * 100
                              : 0;
                          final colorIndex = categoryData.keys
                              .toList()
                              .indexOf(entry.key) % _categoryColors.length;
                          return PieChartSectionData(
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            color: _categoryColors[colorIndex],
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categoryData.entries.take(5).map((entry) {
                      final percentage = _totalExpense > 0
                          ? (entry.value / _totalExpense) * 100
                          : 0;
                      final colorIndex = categoryData.keys
                          .toList()
                          .indexOf(entry.key) % _categoryColors.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _categoryColors[colorIndex],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _getCategoryDisplayName(entry.key),
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categoryData = _getCategoryData();
    if (categoryData.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...categoryData.entries.map((entry) {
            final colorIndex = categoryData.keys
                .toList()
                .indexOf(entry.key) % _categoryColors.length;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _categoryColors[colorIndex],
                      borderRadius: BorderRadius.circular(3),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Widget _buildRecentTransactions() {
    final recent = _filteredTransactions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
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
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/reports');
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No transactions yet.\nAdd your first transaction!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recent.map((transaction) {
              final isIncome = transaction.type == 'income';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isIncome ? Colors.green : Colors.red,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description ?? 'Transaction',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${transaction.memberName ?? 'Member'} • ${_getCategoryDisplayName(transaction.category ?? 'other')} • ${transaction.date != null ? DateFormat('MMM dd').format(transaction.date!) : 'No date'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}${Helpers.formatCurrency(transaction.amount ?? 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Add Income',
            color: Colors.green,
            onTap: () => _navigateAndRefresh('/add-income'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Add Expense',
            color: Colors.red,
            onTap: () => _navigateAndRefresh('/add-expense'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.swap_horiz,
            label: 'Transfer',
            color: Colors.orange,
            onTap: () => _navigateAndRefresh('/transfer'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.people,
            label: 'Members',
            color: Colors.purple,
            onTap: () {
              _tabController.animateTo(1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final members = familyProvider.getFamilyMembers();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add-member').then((_) => _loadData());
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Family Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (members.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No family members yet'),
              ),
            )
          else
            ...members.map((member) {
              final balance = 0.0;
              final isPositive = balance >= 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                    child: Text(
                      member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    member.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    member.role == 'admin' ? 'Admin' : 'Member',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Helpers.formatCurrency(balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        'Balance',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          
          if (_currentFamily != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Family Code:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Text(
                      _currentFamily!.familyCode ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransfersTab() {
    final transfers = [
      {'from': 'John', 'to': 'Jane', 'amount': 100, 'status': 'Pending', 'date': DateTime.now()},
      {'from': 'Jane', 'to': 'John', 'amount': 50, 'status': 'Approved', 'date': DateTime.now().subtract(const Duration(days: 2))},
      {'from': 'John', 'to': 'Mike', 'amount': 75, 'status': 'Completed', 'date': DateTime.now().subtract(const Duration(days: 5))},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildTransferStat('Pending', 1, Colors.orange),
              const SizedBox(width: 12),
              _buildTransferStat('Approved', 1, Colors.blue),
              const SizedBox(width: 12),
              _buildTransferStat('Completed', 1, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          
          if (transfers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No transfers yet'),
              ),
            )
          else
            ...transfers.map((transfer) {
              final status = transfer['status'] as String;
              Color statusColor;
              IconData statusIcon;
              
              switch (status) {
                case 'Pending':
                  statusColor = Colors.orange;
                  statusIcon = Icons.pending;
                  break;
                case 'Approved':
                  statusColor = Colors.blue;
                  statusIcon = Icons.check_circle;
                  break;
                case 'Completed':
                  statusColor = Colors.green;
                  statusIcon = Icons.done_all;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.help;
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  title: Text(
                    '${transfer['from']} → ${transfer['to']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(transfer['date'] as DateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Helpers.formatCurrency(transfer['amount'] as double),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTransferStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getCategoryData() {
    final Map<String, double> categoryData = {};
    for (var t in _filteredTransactions) {
      if (t.type == 'expense' && t.category != null) {
        categoryData[t.category!] =
            (categoryData[t.category!] ?? 0) + (t.amount ?? 0);
      }
    }
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  String _getCategoryDisplayName(String category) {
    return category.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
