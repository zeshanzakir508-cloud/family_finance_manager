import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/family_provider.dart';
import '../../providers/mode_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController();

  bool _isLoading = false;
  String? _selectedFamilyId;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final userId = authService.userId;
    final isPersonalMode = modeProvider.isPersonalMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPersonalMode ? 'Family Management' : 'Family Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isPersonalMode && familyProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddMemberDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Switch
                  _buildModeSwitch(modeProvider),
                  const SizedBox(height: 16),

                  // Family List or Create/Join
                  if (isPersonalMode)
                    _buildPersonalModeView(userId)
                  else
                    _buildFamilyModeView(familyProvider, userId),
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
                child: Center(
                  child: Text(
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
                child: Center(
                  child: Text(
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalModeView(String? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.family_restroom_outlined,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                'You are in Personal Mode',
                style: AppTheme.subheadingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Switch to Family Mode to manage your family',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final modeProvider = Provider.of<ModeProvider>(context, listen: false);
                  modeProvider.setMode('family');
                  Navigator.pushReplacementNamed(context, '/family-dashboard');
                },
                child: const Text('Switch to Family Mode'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _showCreateFamilyDialog,
                child: const Text('Create Family'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyModeView(FamilyProvider familyProvider, String? userId) {
    final family = familyProvider.currentFamily;
    final members = familyProvider.familyMembers;
    final isAdmin = familyProvider.isAdmin;

    if (family == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.family_restroom_outlined,
                  size: 48,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Family Found',
                  style: AppTheme.subheadingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a family or join an existing one',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showCreateFamilyDialog,
                  child: const Text('Create Family'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _showJoinFamilyDialog,
                  child: const Text('Join Family'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Family Info Card
        Container(
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
                    family.name ?? 'Family',
                    style: AppTheme.headingStyle.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: () {
                        // Edit family name
                      },
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                family.description ?? 'No description',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${family.memberCount}/${Constants.maxFamilyMembers} members',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Admin: ${_getAdminName(members)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Family Code
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Family Code:',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    family.familyCode ?? 'N/A',
                    style: AppTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Family code copied!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Members List
        Text(
          'Members',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        if (members.isEmpty)
          Text(
            'No members yet',
            style: AppTheme.captionStyle,
          )
        else
          ...members.map((member) {
            final isAdminUser = family.adminId == member.id;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.dividerColor),
                ),
              ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: AppTheme.bodyStyle,
                        ),
                        Text(
                          member.email ?? 'No email',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                  if (isAdminUser)
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
                  if (isAdmin && member.id != userId)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removeMember(member.id!),
                      tooltip: 'Remove member',
                    ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),

        if (isAdmin)
          ElevatedButton.icon(
            onPressed: _showAddMemberDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),

        const SizedBox(height: 16),

        // Delete Family (Admin only)
        if (isAdmin)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteFamily,
              icon: const Icon(Icons.delete),
              label: const Text('Delete Family'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }

  String _getAdminName(List<UserModel> members) {
    final admin = members.firstWhere(
      (m) => m.id == Provider.of<FamilyProvider>(context).currentFamily?.adminId,
      orElse: () => UserModel(),
    );
    return admin.displayName;
  }

  void _showCreateFamilyDialog() {
    _familyNameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _familyNameController,
              decoration: const InputDecoration(
                labelText: 'Family Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _createFamily,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createFamily() async {
    if (_familyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a family name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      await familyProvider.createFamily(
        _familyNameController.text.trim(),
        userId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
         
