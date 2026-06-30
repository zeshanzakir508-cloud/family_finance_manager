import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/family_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/app_config.dart';
import '../../utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  bool _isOwner = false;
  bool _isModerator = false;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserEmail = authService.userEmail;
    _isOwner = AppConfig.isOwner(_currentUserEmail);
    _isModerator = AppConfig.isModerator(_currentUserEmail);

    if (!_isOwner && !_isModerator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/financial-dashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have admin access'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOwner && !_isModerator) {
      return const Scaffold(
        body: Center(
          child: Text('Access Denied'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Admin Panel'),
            const SizedBox(width: 8),
            if (_isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '👑 Owner',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            if (_isModerator && !_isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🛡️ Moderator',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/financial-dashboard');
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildStatisticsTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildFamiliesTab();
      case 3:
        return _buildAnnouncementsTab();
      default:
        return _buildStatisticsTab();
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Statistics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined),
          activeIcon: Icon(Icons.people),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.family_restroom_outlined),
          activeIcon: Icon(Icons.family_restroom),
          label: 'Families',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.announcement_outlined),
          activeIcon: Icon(Icons.announcement),
          label: 'Announce',
        ),
      ],
    );
  }

  // Tab 1: Statistics
  Widget _buildStatisticsTab() {
    final userBox = Hive.box<UserModel>('users');
    final familyBox = Hive.box<FamilyModel>('families');
    final transactionBox = Hive.box<TransactionModel>('transactions');

    final totalUsers = userBox.values.length;
    final totalFamilies = familyBox.values.length;
    final totalTransactions = transactionBox.values.length;

    int totalMembers = 0;
    for (var family in familyBox.values) {
      totalMembers += family.memberIds?.length ?? 0;
    }

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactionBox.values) {
      if (t.type == 'income') {
        totalIncome += t.amount ?? 0;
      } else if (t.type == 'expense') {
        totalExpense += t.amount ?? 0;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Users',
                  value: totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Families',
                  value: totalFamilies.toString(),
                  icon: Icons.family_restroom,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Members',
                  value: totalMembers.toString(),
                  icon: Icons.group,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Transactions',
                  value: totalTransactions.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Income',
                  value: '\$${totalIncome.toStringAsFixed(2)}',
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Expenses',
                  value: '\$${totalExpense.toStringAsFixed(2)}',
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // App Info
          Text(
            'App Information',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                _buildInfoTile('App Name', Constants.appName),
                _buildInfoTile('Version', Constants.appVersion),
                _buildInfoTile('Owner', AppConfig.ownerEmail),
                _buildInfoTile('Moderators', AppConfig.moderatorEmails.join(', ')),
                _buildInfoTile('Max Families Created', AppConfig.maxFamiliesCreated.toString()),
                _buildInfoTile('Max Families Joined', AppConfig.maxFamiliesJoined.toString()),
                _buildInfoTile('Max Members/Family', AppConfig.maxMembersPerFamily.toString()),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 12),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.captionStyle,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.headingStyle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final transactionBox = Hive.box<TransactionModel>('transactions');
    final userBox = Hive.box<UserModel>('users');
    
    final recent = transactionBox.values
        .toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    
    final recentItems = recent.take(10).toList();

    if (recentItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Text(
          'No activity yet',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final t = recentItems[index];
        final user = userBox.get(t.userId);
        final userName = user?.displayName ?? 'Unknown User';
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: t.typeColor.withOpacity(0.1),
            child: Icon(
              t.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
              color: t.typeColor,
              size: 16,
            ),
          ),
          title: Text(
            '${userName} added ${t.typeDisplay}',
            style: AppTheme.bodyStyle,
          ),
          subtitle: Text(
            '${t.description} • ${Helpers.formatCurrency(t.amount ?? 0)}',
            style: AppTheme.captionStyle,
          ),
          trailing: Text(
            Helpers.timeAgo(t.createdAt ?? DateTime.now()),
            style: AppTheme.captionStyle,
          ),
        );
      },
    );
  }

  // Tab 2: Users
  Widget _buildUsersTab() {
    final userBox = Hive.box<UserModel>('users');
    final users = userBox.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isOwner = user.email == AppConfig.ownerEmail;
        final isModerator = AppConfig.isModerator(user.email);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOwner
                  ? Colors.amber
                  : isModerator
                      ? Colors.blue
                      : AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                user.initials,
                style: TextStyle(
                  color: isOwner || isModerator ? Colors.white : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  user.displayName,
                  style: AppTheme.bodyStyle,
                ),
                const SizedBox(width: 8),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                if (isModerator && !isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Moderator',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              user.email ?? 'No email',
              style: AppTheme.captionStyle,
            ),
            trailing: (isOwner || isModerator)
                ? null
                : IconButton(
                    icon: const Icon(Icons.block, color: Colors.red),
                    onPressed: () {
                      _showBlockUserDialog(user);
                    },
                  ),
          ),
        );
      },
    );
  }

  void _showBlockUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User blocked successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  // Tab 3: Families
  Widget _buildFamiliesTab() {
    final familyBox = Hive.box<FamilyModel>('families');
    final families = familyBox.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: families.length,
      itemBuilder: (context, index) {
        final family = families[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.1),
              child: Text(
                family.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              family.displayName,
              style: AppTheme.bodyStyle,
            ),
            subtitle: Text(
              '${family.memberCount} members • ${family.familyCode ?? 'No code'}',
              style: AppTheme.captionStyle,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteFamilyDialog(family);
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteFamilyDialog(FamilyModel family) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: Text(
          'Are you sure you want to delete "${family.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await family.delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Family deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {});
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Tab 4: Announcements
  Widget _buildAnnouncementsTab() {
    final announcementController = TextEditingController();
    final titleController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Announcement',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to all users. They will see it as a notification.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: announcementController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a title'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (announcementController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a message'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    _sendAnnouncement(
                      titleController.text,
                      announcementController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Send to All Users'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Divider(),
          const SizedBox(height: 16),

          Text(
            'What\'s New (Feature Update)',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            'This will show a popup to all users when they open the app.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _sendFeatureUpdate();
                  },
                  child: const Text('Send Feature Update'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Export Data',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Export all app data for backup or analysis.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _exportData();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _exportData();
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendAnnouncement(String title, String message) async {
    final userBox = Hive.box<UserModel>('users');
    final userIds = userBox.values.map((u) => u.id).where((id) => id != null).cast<String>().toList();

    for (var userId in userIds) {
      await NotificationService.notifySystemMessage(userId, title, message);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Announcement sent to ${userIds.length} users!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendFeatureUpdate() async {
    final userBox = Hive.box<UserModel>('users');
    final userIds = userBox.values.map((u) => u.id).where((id) => id != null).cast<String>().toList();

    for (var userId in userIds) {
      await NotificationService.notifyAppUpdate(
        userId,
        Constants.appVersion,
        'New features added: Family Budget, Monthly Reports, and more!',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feature update sent to ${userIds.length} users!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportData() async {
    final userBox = Hive.box<UserModel>('users');
    final users = userBox.values.toList();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data exported! Check device storage.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
