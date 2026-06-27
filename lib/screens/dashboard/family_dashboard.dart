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
          const Icon(Icons.family_restroom_outlined, size: 64),
          const SizedBox(height: 16),
          const Text('No Family Found'),
          const SizedBox(height: 8),
          const Text('Create a family or join an existing one'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/family-management');
            },
            icon: const Icon(Icons.family_restroom),
            label: const Text('Go to Family Management'),
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
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 8),
                  const Text('Personal'),
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
                  const Icon(Icons.family_restroom, size: 18),
                  const SizedBox(width: 8),
                  const Text('Family'),
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
        colors: [Colors.teal, Colors.teal.shade700],
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
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_family?.memberCount ?? 0}/${Constants.maxFamilyMembers} members',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              'Balance: ${Helpers.formatCurrency(_balance)}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
        child: _buildStatCard('Income', _totalIncome, Colors.green, Icons.arrow_upward),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard('Expenses', _totalExpense, Colors.red, Icons.arrow_downward),
      ),
    ],
  );
}

Widget _buildStatCard(String title, double amount, Color color, IconData icon) {
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
            Text(title),
          ],
        ),
        const SizedBox(height: 8),
        Text(Helpers.formatCurrency(amount)),
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
      const Text('Member Balances'),
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
                child: Text(member.initials),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(member.displayName)),
              if (isAdmin) const Text('Admin'),
              const SizedBox(width: 8),
              Text(
                Helpers.formatCurrency(balance),
                style: TextStyle(
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
            const Text('Recent Family Transactions'),
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
          const Center(child: Text('No family transactions yet'))
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
                Text(transaction.description ?? 'No description'),
                Text('${transaction.memberName ?? 'Unknown'} • ${transaction.categoryDisplay}'),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${transaction.formattedAmount}',
            style: TextStyle(color: transaction.typeColor),
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
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart_outline),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.family_restroom_outlined),
          label: 'Family',
        ),
      ],
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
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
    }
  }
}
