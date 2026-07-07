// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mode_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/common/custom_bottom_nav.dart';
import 'dashboard/personal_dashboard.dart';
import 'dashboard/family_dashboard.dart';
import 'transactions/transaction_list_screen.dart';
import 'budget/budget_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const TransactionListScreen(),
    const BudgetScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final modeProvider = context.watch<ModeProvider>();

    // Load data based on mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.isAuthenticated) {
        if (modeProvider.isPersonalMode) {
          context.read<TransactionProvider>().loadTransactions(authProvider.userId);
        } else {
          final familyId = authProvider.user?.familyId;
          if (familyId != null) {
            context.read<TransactionProvider>().loadFamilyTransactions(familyId);
          }
        }
        context.read<BudgetProvider>().loadCurrentMonthBudget(authProvider.userId);
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
          ),
          BottomNavItem(
            icon: Icons.receipt_long,
            label: 'Transactions',
          ),
          BottomNavItem(
            icon: Icons.speed,
            label: 'Budget',
          ),
          BottomNavItem(
            icon: Icons.analytics,
            label: 'Reports',
          ),
          BottomNavItem(
            icon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD TAB (Switches based on mode)
// ============================================================

class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.watch<ModeProvider>();

    if (modeProvider.isFamilyMode) {
      return const FamilyDashboard();
    } else {
      return const PersonalDashboard();
    }
  }
}
