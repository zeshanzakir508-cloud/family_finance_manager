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
import '../../utils/app_config.dart';

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
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);
    final userId = authService.userId;
    final isPersonalMode = modeProvider.isPersonalMode;

    // Get limit info
    final createdCount = familyProvider.getCreatedFamiliesCount(userId ?? '');
    final joinedCount = familyProvider.getJoinedFamiliesCount(userId ?? '');
    final canCreate = familyProvider.canUserCreateFamily(userId ?? '');
    final canJoin = familyProvider.canUserJoinFamily(userId ?? '');
    final remainingCreate = familyProvider.getRemainingCreateLimit(userId ?? '');
    final remainingJoin = familyProvider.getRemainingJoinLimit(userId ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Management'),
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
                  _buildModeSwitch(modeProvider),
                  const SizedBox(height: 16),

                  // Limits Info Card
                  _buildLimitsInfoCard(
                    createdCount: createdCount,
                    joinedCount: joinedCount,
                    canCreate: canCreate,
                    canJoin: canJoin,
                    remainingCreate: remainingCreate,
                    remainingJoin: remainingJoin,
                  ),
                  const SizedBox(height: 16),

                  if (isPersonalMode)
                    _buildPersonalModeView(userId)
                  else
                    _buildFamilyModeView(familyProvider, userId),
                ],
              ),
            ),
    );
  }

  Widget _buildLimitsInfoCard({
    required int createdCount,
    required int joinedCount,
    required bool canCreate,
    required bool canJoin,
    required int remainingCreate,
    required int remainingJoin,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLimitItem(
            icon: Icons.create,
            label: 'Created',
            count: createdCount,
            max: AppConfig.maxFamiliesCreated,
            remaining: remainingCreate,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.blue.withOpacity(0.2),
          ),
          _buildLimitItem(
            icon: Icons.group_add,
            label: 'Joined',
            count: joinedCount,
            max: AppConfig.maxFamiliesJoined,
            remaining: remainingJoin,
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem({
    required IconData icon,
    required String label,
    required int count,
    required int max,
    required int remaining,
  }) {
    final isAvailable = remaining > 0;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: isAvailable ? Colors.blue : Colors.grey),
            const SizedBox(width: 4),
            Text(
              '$count/$max',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isAvailable ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isAvailable ? Colors.blue : Colors.grey,
          ),
        ),
        if (remaining > 0)
          Text(
            '$remaining left',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green,
            ),
          ),
      ],
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
                Navigator.pushReplacementNamed(context, '/financial-dashboard');
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
                Navigator.pushReplacementNamed(context, '/financial-dashboard');
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
    final createdCount = Provider.of<FamilyProvider>(context).getCreatedFamiliesCount(userId ?? '');
    final canCreate = Provider.of<FamilyProvider>(context).canUserCreateFamily(userId ?? '');

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
                  Navigator.pushReplacementNamed(context, '/financial-dashboard');
                },
                child: const Text('Switch to Family Mode'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: canCreate ? _showCreateFamilyDialog : null,
                child: Text(
                  canCreate ? 'Create Family' : 'Limit Reached (${AppConfig.maxFamiliesCreated} max)',
                ),
              ),
              if (!canCreate)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'You have created maximum families',
                    style: AppTheme.captionStyle.copyWith(color: Colors.red),
                  ),
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
      final canCreate = familyProvider.canUserCreateFamily(userId ?? '');
      final canJoin = familyProvider.canUserJoinFamily(userId ?? '');

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
                  onPressed: canCreate ? _showCreateFamilyDialog : null,
                  child: Text(
                    canCreate ? 'Create Family' : 'Limit Reached',
                  ),
                ),
                if (!canCreate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'You have created maximum families (${AppConfig.maxFamiliesCreated})',
                      style: AppTheme.captionStyle.copyWith(color: Colors.red),
                    ),
                  ),
                OutlinedButton(
                  onPressed: canJoin ? _showJoinFamilyDialog : null,
                  child: Text(
                    canJoin ? 'Join Family' : 'Limit Reached',
                  ),
                ),
                if (!canJoin)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'You have joined maximum families (${AppConfig.maxFamiliesJoined})',
                      style: AppTheme.captionStyle.copyWith(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final remainingSlots = familyProvider.getRemainingMemberSlots(family.id!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${family.memberCount}/${AppConfig.maxMembersPerFamily}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${family.memberCount} members',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (remainingSlots > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$remainingSlots slots left',
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

        Text(
          'Members',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        if (members.isEmpty)
          const Text(
            'No members yet',
            style: TextStyle(color: Colors.grey),
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
          }).toList(),
        const SizedBox(height: 8),

        if (isAdmin)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: remainingSlots > 0 ? _showAddMemberDialog : null,
                  icon: const Icon(Icons.person_add),
                  label: Text(
                    remainingSlots > 0 ? 'Add Member' : 'Family Full',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: remainingSlots > 0
                        ? AppTheme.primaryColor
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showTransferAdminDialog,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Transfer Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

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

  // ... rest of the methods (showCreateFamilyDialog, createFamily, joinFamily, etc.)
  // Keep all existing dialog methods from previous version
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
            const SizedBox(height: 8),
            Consumer<FamilyProvider>(
              builder: (context, familyProvider, child) {
                final remaining = familyProvider.getRemainingCreateLimit(
                  Provider.of<AuthService>(context, listen: false).userId ?? '',
                );
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'You can create $remaining more family${remaining > 1 ? 'ies' : ''}',
                    style: AppTheme.captionStyle.copyWith(
                      color: remaining > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
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
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showJoinFamilyDialog() {
    _inviteCodeController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inviteCodeController,
              decoration: const InputDecoration(
                labelText: 'Family Code *',
                hintText: 'Enter the family code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Consumer<FamilyProvider>(
              builder: (context, familyProvider, child) {
                final remaining = familyProvider.getRemainingJoinLimit(
                  Provider.of<AuthService>(context, listen: false).userId ?? '',
                );
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'You can join $remaining more family${remaining > 1 ? 'ies' : ''}',
                    style: AppTheme.captionStyle.copyWith(
                      color: remaining > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _joinFamily,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _joinFamily() async {
    if (_inviteCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a family code'),
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
      await familyProvider.joinFamily(
        _inviteCodeController.text.trim().toUpperCase(),
        userId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined family successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/financial-dashboard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddMemberDialog() {
    _memberEmailController.clear();

    final remainingSlots = Provider.of<FamilyProvider>(context, listen: false)
        .getRemainingMemberSlots(
          Provider.of<FamilyProvider>(context, listen: false).currentFamily?.id ?? '',
        );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _memberEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                hintText: 'Enter member\'s email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                remainingSlots > 0
                    ? '$remainingSlots slots available'
                    : 'Family is full (${AppConfig.maxMembersPerFamily} members)',
                style: AppTheme.captionStyle.copyWith(
