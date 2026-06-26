import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/family_model.dart';
import '../../models/user_profile.dart';
import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedFamilyId;
  FamilyModel? _selectedFamily;
  List<String> _allMemberEmails = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    setState(() {
      _isLoading = true;
    });

    // Load all user emails for member search
    final userBox = Hive.box<UserProfile>('userProfile');
    _allMemberEmails = userBox.values
        .where((user) => user.email != null)
        .map((user) => user.email!)
        .toList();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateFamilyDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: Hive.box<FamilyModel>('families').listenable(),
              builder: (context, Box<FamilyModel> box, _) {
                final families = box.values.toList();
                
                if (families.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: families.length,
                  itemBuilder: (context, index) {
                    final family = families[index];
                    final isMember = family.memberIds?.contains(userId) ?? false;
                    final isAdmin = family.adminId == userId;
                    
                    return _buildFamilyCard(family, isMember, isAdmin);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinFamilyDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Family Groups',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new family or join an existing one',
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateFamilyDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Family'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _showJoinFamilyDialog,
                icon: const Icon(Icons.group_add),
                label: const Text('Join Family'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(FamilyModel family, bool isMember, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            family.displayName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          family.displayName,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              family.description ?? 'No description',
              style: AppTheme.captionStyle,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${family.memberCount} members',
                  style: AppTheme.captionStyle,
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 12),
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
                ],
                if (isMember && !isAdmin) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Member',
                      style: AppTheme.captionStyle.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: isMember
            ? IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                onPressed: () => _leaveFamily(family),
                tooltip: 'Leave Family',
              )
            : ElevatedButton(
                onPressed: () => _joinFamily(family),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Join'),
              ),
        children: [
          if (isMember) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Members List
                  Text(
                    'Members',
                    style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildMembersList(family),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersList(FamilyModel family) {
    final userBox = Hive.box<UserProfile>('userProfile');
    final members = family.memberIds?.map((id) {
      return userBox.get(id);
    }).where((user) => user != null).toList() ?? [];

    if (members.isEmpty) {
      return Text(
        'No members yet',
        style: AppTheme.captionStyle,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final user = members[index] as UserProfile;
        final isAdmin = family.adminId == user.id;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              user.initials,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            user.displayName,
            style: AppTheme.bodyStyle,
          ),
          subtitle: Text(
            user.email ?? 'No email',
            style: AppTheme.captionStyle,
          ),
          trailing: isAdmin
              ? Container(
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
                )
              : null,
        );
      },
    );
  }

  Future<void> _showCreateFamilyDialog() async {
    _familyNameController.clear();
    _descriptionController.clear();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family'),
        content: SingleChildScrollView(
          child: Column(
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

  Future<void> _createFamily() async {
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

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    final userBox = Hive.box<UserProfile>('userProfile');
    final currentUser = userBox.get(userId);

    final family = FamilyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _familyNameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      createdBy: userId,
      adminId: userId,
      memberIds: [userId!],
      createdAt: DateTime.now(),
      isActive: true,
      familyCode: _generateFamilyCode(),
      currency: 'USD',
    );

    final box = Hive.box<FamilyModel>('families');
    await box.add(family);

    // Update user profile with family ID
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(familyId: family.id);
      await userBox.put(userId, updatedUser);
    }

    // Create notification for family creation
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'Family Created',
      message: 'You have created the family "${family.name}"',
      type: NotificationType.family,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await Hive.box<NotificationModel>('notifications').add(notification);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showJoinFamilyDialog() async {
    _inviteCodeController.clear();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Family'),
        content: TextField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            labelText: 'Family Code *',
            hintText: 'Enter the family code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _joinFamilyByCode,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinFamilyByCode() async {
    if (_inviteCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a family code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final box = Hive.box<FamilyModel>('families');
    FamilyModel? foundFamily;
    
    for (var family in box.values) {
      if (family.familyCode == _inviteCodeController.text.trim()) {
        foundFamily = family;
        break;
      }
    }

    if (foundFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid family code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _joinFamily(foundFamily);
  }

  Future<void> _joinFamily(FamilyModel family) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    final userBox = Hive.box<UserProfile>('userProfile');
    final currentUser = userBox.get(userId);

    final updatedFamily = family.copyWith(
      memberIds: [...?family.memberIds, userId!],
    );
    await updatedFamily.save();

    // Update user profile with family ID
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(familyId: family.id);
      await userBox.put(userId, updatedUser);
    }

    // Create notification
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'Joined Family',
      message: 'You have joined the family "${family.name}"',
      type: NotificationType.family,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await Hive.box<NotificationModel>('notifications').add(notification);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined "${family.displayName}" successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _leaveFamily(FamilyModel family) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: Text(
          'Are you sure you want to leave "${family.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      final userBox = Hive.box<UserProfile>('userProfile');
      final currentUser = userBox.get(userId);

      final updatedFamily = family.copyWith(
        memberIds: family.memberIds?.where((id) => id != userId).toList(),
      );
      await updatedFamily.save();

      // Update user profile
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(familyId: null);
        await userBox.put(userId, updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left "${family.displayName}"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final String code = String.fromCharCodes(
      List.generate(8, (index) {
        final charIndex = (random + index * 7) % chars.length;
        return chars.codeUnitAt(charIndex);
      }),
    );
    return code;
  }
}
