// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mode_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/common/custom_bottom_nav.dart';
import 'dashboard/personal_dashboard.dart';
import 'dashboard/family_dashboard.dart';
import 'transactions/transaction_list_screen.dart';
import 'budget/budget_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'owner/owner_dashboard.dart'; // ✅ ADDED for owner role

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // ✅ ADDED: Proper initialization with error handling
  Future<void> _initializeData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final modeProvider = context.read<ModeProvider>();

      if (authProvider.isAuthenticated) {
        print('✅ HomeScreen: User authenticated: ${authProvider.user?.email}');
        print('✅ HomeScreen: Role: ${authProvider.user?.role}');
        print('✅ HomeScreen: Mode: ${modeProvider.isPersonalMode ? "Personal" : "Family"}');

        // Load data based on mode
        if (modeProvider.isPersonalMode) {
          await context.read<TransactionProvider>().loadTransactions(authProvider.userId);
        } else {
          final familyId = authProvider.user?.familyId;
          if (familyId != null) {
            await context.read<TransactionProvider>().loadFamilyTransactions(familyId);
          } else {
            print('⚠️ HomeScreen: No family ID found for family mode');
          }
        }
        await context.read<BudgetProvider>().loadCurrentMonthBudget(authProvider.userId);

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'User not authenticated';
        });
      }
    } catch (e, stackTrace) {
      print('❌ HomeScreen initialization error: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ✅ ADDED: Get the correct dashboard based on role and mode
  Widget _getDashboard() {
    final authProvider = context.watch<AuthProvider>();
    final modeProvider = context.watch<ModeProvider>();

    // If user is owner, show owner dashboard
    if (authProvider.isOwner) {
      print('✅ HomeScreen: Showing Owner Dashboard');
      return const OwnerDashboard();
    }

    // Otherwise show mode-based dashboard
    if (modeProvider.isFamilyMode) {
      print('✅ HomeScreen: Showing Family Dashboard');
      return const FamilyDashboard();
    } else {
      print('✅ HomeScreen: Showing Personal Dashboard');
      return const PersonalDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // ✅ ADDED: Check authentication
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Please login to continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ ADDED: Loading state
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading your dashboard...',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ ADDED: Error state
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initializeData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
    final authProvider = context.watch<AuthProvider>();
    final modeProvider = context.watch<ModeProvider>();

    // ✅ FIXED: Show owner dashboard if user is owner
    if (authProvider.isOwner) {
      return const OwnerDashboard();
    }

    if (modeProvider.isFamilyMode) {
      return const FamilyDashboard();
    } else {
      return const PersonalDashboard();
    }
  }
}
