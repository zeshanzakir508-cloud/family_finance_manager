import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
// import '../../services/notification_service.dart'; // ✅ COMMENTED OUT
import '../../models/user_model.dart';
import '../../models/family_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedTab = 0;
  List<UserModel> _users = [];
  List<FamilyModel> _families = [];
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _tabs = ['Overview', 'Users', 'Families', 'Announcements'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _users = DatabaseService.getAllUsers();
      _families = DatabaseService.getAllFamilies();
      _transactions = DatabaseService.getAllTransactions();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Stats Cards
                    _buildStatsCards(),
                    const SizedBox(height: 8),

                    // Tabs
                    _buildTabs(),
                    const SizedBox(height: 8),

                    // Tab Content
                    Expanded(
                      child: _buildTabContent(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatsCards() {
    final totalIncome = _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0));
    final totalExpense = _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0));

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildStatCard('Users', _users.length.toString(), Icons.people),
          _buildStatCard('Families', _families.length.toString(), Icons.family_restroom),
          _buildStatCard('Income', '\$${totalIncome.toStringAsFixed(0)}', Icons.trending_up, color: Colors.green),
          _buildStatCard('Expense', '\$${totalExpense.toStringAsFixed(0)}', Icons.trending_down, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Icon(icon, color: color ?? AppTheme.primaryColor, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        return _buildUsersTab();
      case 2:
        return _buildFamiliesTab();
      case 3:
        return _buildAnnouncementsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_transactions.isEmpty)
            const Text('No recent transactions'),
          ..._transactions.take(10).map((t) {
            return ListTile(
              leading: Icon(
                t.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
                color: t.type == 'income' ? Colors.green : Colors.red,
              ),
              title: Text(t.description ?? 'Transaction'),
              subtitle: Text('${t.memberName ?? 'User'} • ${t.formattedDate}'),
              trailing: Text(
                '${t.type == 'income' ? '+' : '-'}\$${t.amount?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  color: t.type == 'income' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user.initials,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.displayName ?? 'Unknown'),
            subtitle: Text(user.email ?? ''),
            trailing: Text(user.role ?? 'member'),
          ),
        );
      },
    );
  }

  Widget _buildFamiliesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _families.length,
      itemBuilder: (context, index) {
        final family = _families[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                family.name != null && family.name!.isNotEmpty
                    ? family.name![0].toUpperCase()
                    : 'F',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(family.name ?? 'Family'),
            subtitle: Text('Code: ${family.familyCode} • Members: ${family.memberCount}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteFamily(family),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteFamily(FamilyModel family) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: Text('Are you sure you want to delete "${family.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await family.delete();
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAnnouncementsTab() {
    final announcementController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send Announcement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Send a message to all users'),
          const SizedBox(height: 16),
          TextField(
            controller: announcementController,
            decoration: const InputDecoration(
              hintText: 'Enter announcement...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _sendAnnouncement(announcementController.text);
                announcementController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Announcement'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Total Users', _users.length.toString()),
                  _buildStatRow('Total Families', _families.length.toString()),
                  _buildStatRow('Total Transactions', _transactions.length.toString()),
                  _buildStatRow('Total Income', '\$${_transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + (t.amount ?? 0)).toStringAsFixed(2)}'),
                  _buildStatRow('Total Expense', '\$${_transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + (t.amount ?? 0)).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _sendAnnouncement(String message) async {
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // ✅ COMMENTED OUT - Fix later
      // for (var user in _users) {
      //   await NotificationService.showNotification(
      //     id: DateTime.now().millisecondsSinceEpoch.hashCode + user.id.hashCode,
      //     title: '📢 Announcement',
      //     body: message,
      //     payload: 'announcement',
      //   );
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement feature coming soon!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending announcement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
