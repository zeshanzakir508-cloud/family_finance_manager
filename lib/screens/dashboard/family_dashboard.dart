import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/mode_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart';
import '../../models/family_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  List<TransactionModel> _familyTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  FamilyModel? _family;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;

    if (family != null) {
      _family = family;
      _familyTransactions = DatabaseService.getFamilyTransactions(family.id!);
      _familyTransactions.sort((a, b) => b.date!.compareTo(a.date!));

      double income = 0;
      double expense = 0;
      for (var t in _familyTransactions) {
        if (t.type == 'income') {
          income += t.amount ?? 0;
        } else {
          expense += t.amount ?? 0;
        }
      }
      _totalIncome = income;
      _totalExpense = expense;
      _balance = income - expense;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final modeProvider = Provider.of<ModeProvider>(context);

    if (_family == null) {
      return _buildNoFamilyState();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_family?.name ?? 'Family Dashboard'),
        actions: [
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
              _buildModeSwitch(modeProvider),
              const SizedBox(height: 16),
              _buildFamilyInfo(),
              const SizedBox(height: 24),
              _buildStats(),
              const SizedBox(height: 24),
              _buildMemberBalances(),
              const SizedBox(height: 24),
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

  Widget _buildNoFamilyState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Family Found',
              style: AppTheme.headingStyle.copyWith(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a family or join an existing one',
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/family-management');
              },
              icon: const Icon(Icons.family_restroom),
              label: const Text('Go to Family Management'),
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
                Navigator.pushReplacementNamed(context, '/personal-dashboard');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: modeProvider.isPersonalMode
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: modeProvider.isPersonalMode
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
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
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                modeProvider.setMode('family');
                Navigator.pushReplacementNamed(context, '/family-dashboard');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: modeProvider.isFamilyMode
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.family_restroom,
                      color: modeProvider.isFamilyMode
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal,
            Colors.teal.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _family?.name ?? 'Family',
                style: AppTheme.headingStyle.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_family?.memberCount ?? 0}/${Constants.maxFamilyMembers} members',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Balance: ${Helpers.formatCurrency(_balance)}',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Income',
            amount: _totalIncome,
            color: Colors.green,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Expenses',
            amount: _totalExpense,
            color: Colors.red,
            icon: Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
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

  Widget _buildMemberBalances() {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final members = familyProvider.familyMembers;

    if (members.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Member Balances',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        ...members.map((member) {
          final memberTransactions = _familyTransactions
              .where((t) => t.memberId == member.id)
              .toList();
          double income = 0;
          double expense = 0;
          for (var t in memberTransactions) {
            if (t.type == 'income') {
              income += t.amount ?? 0;
            } else {
              expense += t.amount ?? 0;
            }
          }
          final balance = income - expense;
          final isAdmin = _family?.adminId == member.id;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.displayName,
                    style: AppTheme.bodyStyle,
                  ),
                ),
                if (isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Admin',
                      style: AppTheme.captionStyle.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  Helpers.formatCurrency(balance),
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final recent = _familyTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Family Transactions',
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
                  'No family transactions yet',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the + button to add your first family transaction!',
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
                  '${transaction.memberName ?? 'Unknown'} • ${transaction.categoryDisplay}',
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _handleNavigation(index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Dashboard',
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
      ],
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 
