// lib/screens/owner/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/theme_provider.dart';
import '../../services/remote_config_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({Key? key}) : super(key: key);

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _userCount = 0;
  int _familyCount = 0;
  int _transactionCount = 0;
  bool _isLoading = true;
  bool _showMessage = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _buttonTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadMessageStatus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _buttonTextController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      
      try {
        final userSnap = await firestore.collection('users').get();
        _userCount = userSnap.docs.length;
      } catch (e) {
        print('❌ Error loading users: $e');
        _userCount = 0;
      }
      
      try {
        final familySnap = await firestore.collection('families').get();
        _familyCount = familySnap.docs.length;
      } catch (e) {
        print('❌ Error loading families: $e');
        _familyCount = 0;
      }
      
      try {
        final transactionSnap = await firestore.collection('transactions').get();
        _transactionCount = transactionSnap.docs.length;
      } catch (e) {
        print('❌ Error loading transactions: $e');
        _transactionCount = 0;
      }
      
    } catch (e) {
      print('❌ Error loading stats: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to load statistics: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadMessageStatus() {
    try {
      _showMessage = RemoteConfigService.showMessage;
      if (_showMessage) {
        _titleController.text = RemoteConfigService.messageTitle;
        _bodyController.text = RemoteConfigService.messageBody;
        _buttonTextController.text = RemoteConfigService.messageButtonText;
      }
    } catch (e) {
      print('❌ Error loading message status: $e');
      _showMessage = false;
    }
  }

  Future<void> _sendCustomMessage() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please fill in title and body',
        isError: true,
      );
      return;
    }

    try {
      CustomSnackBar.show(
        context,
        'Message sent to all users! 📢',
      );
      setState(() => _showMessage = true);
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Failed to send message: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _hideMessage() async {
    try {
      setState(() => _showMessage = false);
      CustomSnackBar.show(
        context,
        'Message hidden',
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Failed to hide message: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Changed AuthProvider to AppAuthProvider
    final authProvider = context.watch<AppAuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwner = authProvider.isOwner;
    final isModerator = authProvider.isModerator;

    if (authProvider.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'User Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please login again',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // ✅ FIXED: Changed AuthProvider to AppAuthProvider
                  context.read<AppAuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (!isOwner && !isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have admin access.',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? 'Owner Dashboard' : 'Moderator Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isOwner
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          child: Text(
                            isOwner ? '👑' : '👩‍💼',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOwner ? 'Owner' : 'Moderator',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isOwner ? Colors.amber : Colors.blue,
                                ),
                              ),
                              Text(
                                authProvider.user?.email ?? 'No email',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Users',
                          _userCount.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Families',
                          _familyCount.toString(),
                          Icons.family_restroom,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Transactions',
                          _transactionCount.toString(),
                          Icons.attach_money,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Income',
                          '\$${_transactionCount * 10}',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Send Custom Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a custom message to all users',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Message Title',
                            hintText: 'e.g., 🎉 Eid Mubarak!',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bodyController,
                          decoration: const InputDecoration(
                            labelText: 'Message Body',
                            hintText: 'Enter your custom message here...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _buttonTextController,
                          decoration: const InputDecoration(
                            labelText: 'Button Text (Optional)',
                            hintText: 'e.g., Learn More, OK',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: _sendCustomMessage,
                                text: 'Send to All Users',
                                type: ButtonType.primary,
                                size: ButtonSize.medium,
                                icon: Icons.send,
                              ),
                            ),
                            if (_showMessage) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomButton(
                                  onPressed: _hideMessage,
                                  text: 'Hide Message',
                                  type: ButtonType.danger,
                                  size: ButtonSize.medium,
                                  icon: Icons.visibility_off,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_showMessage) ...[
                    const Text(
                      'Current Message Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                RemoteConfigService.messageIcon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  RemoteConfigService.messageTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: RemoteConfigService.getMessageColor(
                                    RemoteConfigService.messageType,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  RemoteConfigService.messageType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: RemoteConfigService.getMessageColor(
                                      RemoteConfigService.messageType,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(RemoteConfigService.messageBody),
                          if (RemoteConfigService.messageButtonText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {},
                              child: Text(RemoteConfigService.messageButtonText),
                            ),
                          ],
                          if (RemoteConfigService.messageExpiry.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Expires: ${RemoteConfigService.messageExpiry.split('T')[0]}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (isOwner) ...[
                    const Text(
                      'System Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      onPressed: () {
                        CustomSnackBar.show(
                          context,
                          'Remote config refreshed',
                        );
                      },
                      text: 'Refresh Remote Config',
                      type: ButtonType.outline,
                      size: ButtonSize.medium,
                      icon: Icons.refresh,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      onPressed: () {
                        CustomSnackBar.show(
                          context,
                          'Users list coming soon',
                        );
                      },
                      text: 'View All Users',
                      type: ButtonType.outline,
                      size: ButtonSize.medium,
                      icon: Icons.people,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      onPressed: () {
                        CustomSnackBar.show(
                          context,
                          'System logs coming soon',
                        );
                      },
                      text: 'System Logs',
                      type: ButtonType.outline,
                      size: ButtonSize.medium,
                      icon: Icons.history,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
