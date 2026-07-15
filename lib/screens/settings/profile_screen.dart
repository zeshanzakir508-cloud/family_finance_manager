// lib/screens/settings/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/currency_provider.dart';
import '../../providers/mode_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  double _balance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      // ✅ FIXED: AuthProvider → AppAuthProvider
      final auth = context.read<AppAuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      if (auth.isAuthenticated) {
        await transactionProvider.loadTransactions(auth.userId);
        
        setState(() {
          _totalIncome = transactionProvider.totalIncome;
          _totalExpense = transactionProvider.totalExpense;
          _balance = transactionProvider.balance;
        });
      }
    } catch (e) {
      print('❌ Error loading user stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: AuthProvider → AppAuthProvider
    final authProvider = context.watch<AppAuthProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final modeProvider = context.watch<ModeProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
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
              const Text('Failed to load profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  authProvider.refreshUser();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final balance = transactionProvider.balance;
    final totalIncome = transactionProvider.totalIncome;
    final totalExpense = transactionProvider.totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          IconButton(
            icon: Icon(
              transactionProvider.isLoading ? Icons.refresh : Icons.refresh,
            ),
            onPressed: _loadUserStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.role?.toUpperCase() ?? 'Member',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getRoleColor(user.role),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Balance',
                    '${currencyProvider.currentCurrency} ${balance.toStringAsFixed(2)}',
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Income',
                    '${currencyProvider.currentCurrency} ${totalIncome.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Expense',
                    '${currencyProvider.currentCurrency} ${totalExpense.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    icon: Icons.person,
                    label: 'Full Name',
                    value: user.displayName ?? 'Not set',
                  ),
                  _buildInfoTile(
                    icon: Icons.email,
                    label: 'Email',
                    value: user.email ?? 'Not set',
                  ),
                  _buildInfoTile(
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: user.username ?? 'Not set',
                  ),
                  _buildInfoTile(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: user.phoneNumber ?? 'Not set',
                  ),
                  _buildInfoTile(
                    icon: Icons.currency_exchange,
                    label: 'Currency',
                    value: user.currency ?? 'USD',
                  ),
                  _buildInfoTile(
                    icon: Icons.family_restroom,
                    label: 'Mode',
                    value: modeProvider.isPersonalMode ? 'Personal' : 'Family',
                  ),
                  _buildInfoTile(
                    icon: Icons.calendar_today,
                    label: 'Member Since',
                    value: user.createdAt != null
                        ? user.createdAt!.toLocal().toString().split(' ')[0]
                        : 'N/A',
                  ),
                  _buildInfoTile(
                    icon: Icons.verified,
                    label: 'Email Verified',
                    value: user.emailVerified == true ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/edit_profile');
                    },
                    text: 'Edit Profile',
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                    icon: Icons.edit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/change_password');
                    },
                    text: 'Change Password',
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                    icon: Icons.lock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'owner':
        return Colors.amber;
      case 'moderator':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
