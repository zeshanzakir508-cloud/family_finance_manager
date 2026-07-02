import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/family_provider.dart';
import '../../providers/mode_provider.dart';
import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  bool _isLoading = false;
  List<UserModel> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;
    
    if (family != null && family.memberIds != null) {
      final members = <UserModel>[];
      for (var id in family.memberIds!) {
        final user = await DatabaseService.getUser(id);
        if (user != null) members.add(user);
      }
      setState(() => _members = members);
    }
  }

  Future<void> _deleteFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: const Text(
          'Are you sure? This will delete ALL family data. This action cannot be undone.',
          style: TextStyle(color: Colors.red),
        ),
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
      setState(() => _isLoading = true);
      try {
        final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
        await familyProvider.deleteFamily();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: const Text('Are you sure you want to leave this family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.userId;
        if (userId != null) {
          final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
          await familyProvider.leaveFamily(userId);
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _shareFamilyCode() {
    final family = Provider.of<FamilyProvider>(context, listen: false).currentFamily;
    if (family != null) {
      Share.share(
        'Join my family on FinFam!\n\n'
        'Family: ${family.name}\n'
        'Code: ${family.familyCode}\n\n'
        'Download FinFam and enter this code to join.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final family = familyProvider.currentFamily;
    final authService = Provider.of<AuthService>(context);
    final isAdmin = family != null && family.adminId == authService.userId;

    if (family == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Family Management'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Family Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new family or join one',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/family-create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Family'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/family-join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Join Family'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Family Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, '/add-member'),
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadMembers,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Family Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    family.name ?? 'Family',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Code: ${family.familyCode}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Base Currency: ${family.baseCurrency}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Members: ${family.memberIds?.length ?? 0}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // Edit family dialog
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: _shareFamilyCode,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Members Section
                  Text(
                    'Members (${_members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ..._members.map((member) {
                    final isAdminUser = member.id == family.adminId;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdminUser
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          child: Text(
                            member.initials,
                            style: TextStyle(
                              color: isAdminUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        title: Text(member.displayName ?? 'Unknown'),  // ✅ FIXED
                        subtitle: Text(
                          isAdminUser
                              ? 'Admin'
                              : 'Member',
                          style: TextStyle(
                            color: isAdminUser ? AppTheme.primaryColor : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isAdminUser
                            ? const Icon(Icons.admin_panel_settings, color: Colors.amber)
                            : null,
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Actions
                  if (isAdmin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/add-member'),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Member'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _shareFamilyCode,
                      icon: const Icon(Icons.share),
                      label: const Text('Share Family Code'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.green),
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Leave/Delete
                  if (isAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteFamily,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Family'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _leaveFamily,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Leave Family'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.orange),
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
