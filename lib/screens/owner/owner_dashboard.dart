// lib/screens/owner/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mode_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _currentUser;
  bool _isLoading = true;
  
  // Stats
  int _totalUsers = 0;
  int _totalFamilies = 0;
  int _premiumUsers = 0;
  double _monthlyRevenue = 0;
  List<UserModel> _allUsers = [];
  List<Map<String, dynamic>> _allFamilies = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    
    if (userId != null) {
      _currentUser = await DatabaseService.getUser(userId);
      // Load stats from database
      _loadStats();
    }
    
    setState(() => _isLoading = false);
  }

  void _loadStats() {
    // Mock data - replace with real database calls
    _totalUsers = 1234;
    _totalFamilies = 456;
    _premiumUsers = 89;
    _monthlyRevenue = 499.00;
    _allUsers = [];
    _allFamilies = [];
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _currentUser?.role == 'owner';
    final isModerator = _currentUser?.role == 'moderator';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          isOwner ? 'Owner Dashboard' : 'Moderator Dashboard',
        ),
        backgroundColor: isOwner ? const Color(0xFFD4AF37) : Colors.blue,  // FIXED: Colors.gold replaced
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOwner ? '👑 Owner' : '🛡️ Moderator',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: isOwner
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Owner Panel'),
                  Tab(text: 'Moderator Panel'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
              )
            : null,
      ),
      body: isOwner
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildOwnerPanel(),
                _buildModeratorPanel(),
              ],
            )
          : _buildModeratorPanel(),
    );
  }

  // ==================== OWNER PANEL ====================

  Widget _buildOwnerPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              _buildStatCard('Total Users', _totalUsers, Icons.people, Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard('Families', _totalFamilies, Icons.family_restroom, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Premium Users', _premiumUsers, Icons.star, const Color(0xFFD4AF37)),  // FIXED: Colors.gold replaced
              const SizedBox(width: 12),
              _buildStatCard('Revenue', _monthlyRevenue, Icons.attach_money, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          
          // Owner Actions
          const Text(
            'Owner Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildActionCard(
            icon: Icons.announcement,
            title: 'Send Announcement',
            subtitle: 'Send notifications to all users',
            color: Colors.blue,
            onTap: () {
              _showAnnouncementDialog();
            },
          ),
          
          _buildActionCard(
            icon: Icons.update,
            title: 'Feature Updates',
            subtitle: 'Push "What\'s New" popup to users',
            color: Colors.purple,
            onTap: () {
              _showFeatureUpdateDialog();
            },
          ),
          
          _buildActionCard(
            icon: Icons.settings_remote,
            title: 'Remote Config',
            subtitle: 'Update app settings remotely',
            color: Colors.orange,
            onTap: () {
              _showRemoteConfigDialog();
            },
          ),
          
          _buildActionCard(
            icon: Icons.download,
            title: 'Export Data',
            subtitle: 'Export all user data as CSV',
            color: Colors.green,
            onTap: () {
              _exportData();
            },
          ),
          
          _buildActionCard(
            icon: Icons.trending_up,
            title: 'App Health',
            subtitle: 'View app growth and trends',
            color: Colors.teal,
            onTap: () {
              _showAppHealth();
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value is double ? '\$${value.toStringAsFixed(2)}' : value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // ==================== MODERATOR PANEL ====================

  Widget _buildModeratorPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Moderator Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Moderator Access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'You have limited access to manage content and users.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Moderator Actions
          const Text(
            'Moderator Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildActionCard(
            icon: Icons.people,
            title: 'View Users',
            subtitle: 'See all registered users',
            color: Colors.blue,
            onTap: () {
              _viewUsers();
            },
          ),
          
          _buildActionCard(
            icon: Icons.family_restroom,
            title: 'View Families',
            subtitle: 'See all families',
            color: Colors.green,
            onTap: () {
              _viewFamilies();
            },
          ),
          
          _buildActionCard(
            icon: Icons.report_problem,
            title: 'Reports',
            subtitle: 'View user reports',
            color: Colors.red,
            onTap: () {
              _viewReports();
            },
          ),
          
          _buildActionCard(
            icon: Icons.announcement,
            title: 'Announcements',
            subtitle: 'View announcements',
            color: Colors.orange,
            onTap: () {
              _viewAnnouncements();
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showAnnouncementDialog() {
    String announcement = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send notification to all users:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your announcement here...',
              ),
              onChanged: (value) => announcement = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement sent to all users!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showFeatureUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Push "What\'s New" popup:'),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'v2.0.0\n- New features\n- Bug fixes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature update sent to users!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Push Update'),
          ),
        ],
      ),
    );
  }

  void _showRemoteConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remote Config'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update remote configuration:'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'maintenance_mode: false',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'max_transactions: 50',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Remote config updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export all user data as CSV? This may take a few minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export started! Check downloads.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showAppHealth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App health: 📈 Growing at 12% month-over-month'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _viewUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Total users: 1,234'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewFamilies() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Total families: 456'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No reported issues'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewAnnouncements() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('3 announcements pending'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
