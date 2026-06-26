import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/family_model.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

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
            onPressed: _showCreateFamilyDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder(
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
          Icon(Icons.family_restroom_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No Family Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Create a new family or join an existing one'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateFamilyDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _showJoinFamilyDialog,
                icon: const Icon(Icons.group_add),
                label: const Text('Join'),
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
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(
            family.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(family.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(family.description ?? 'No description'),
        trailing: isMember
            ? IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                onPressed: () => _leaveFamily(family),
              )
            : ElevatedButton(
                onPressed: () => _joinFamily(family),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 32),
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
                  const Text('Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    final members = family.memberIds?.map((id) => userBox.get(id)).where((user) => user != null).toList() ?? [];

    if (members.isEmpty) {
      return const Text('No members yet');
    }

    return Column(
      children: members.map((user) {
        final u = user as UserProfile;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(u.initials, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          title: Text(u.displayName),
          subtitle: Text(u.email ?? 'No email'),
          trailing: family.adminId == u.id
              ? const Text('Admin', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600))
              : null,
        );
      }).toList(),
    );
  }

  void _showCreateFamilyDialog() {
    _familyNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family'),
        content: TextField(
          controller: _familyNameController,
          decoration: const InputDecoration(labelText: 'Family Name *'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: _createFamily, child: const Text('Create')),
        ],
      ),
    );
  }

  void _createFamily() async {
    if (_familyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a family name'), backgroundColor: Colors.red),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    final userBox = Hive.box<UserProfile>('userProfile');
    final currentUser = userBox.get(userId);

    final family = FamilyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _familyNameController.text.trim(),
      createdBy: userId,
      adminId: userId,
      memberIds: [userId!],
      createdAt: DateTime.now(),
      isActive: true,
      familyCode: _generateFamilyCode(),
      currency: 'USD',
    );

    await Hive.box<FamilyModel>('families').add(family);

    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(familyId: family.id);
      await userBox.put(userId, updatedUser);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family created!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showJoinFamilyDialog() {
    _inviteCodeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Family'),
        content: TextField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(labelText: 'Family Code *'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: _joinFamilyByCode, child: const Text('Join')),
        ],
      ),
    );
  }

  void _joinFamilyByCode() async {
    if (_inviteCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a family code'), backgroundColor: Colors.red),
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
        const SnackBar(content: Text('Invalid family code'), backgroundColor: Colors.red),
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

    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(familyId: family.id);
      await userBox.put(userId, updatedUser);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${family.displayName}"!'), backgroundColor: Colors.green),
      );
    }
  }

  void _leaveFamily(FamilyModel family) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: Text('Leave "${family.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(familyId: null);
        await userBox.put(userId, updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left "${family.displayName}"'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(8, (index) {
        final charIndex = (random + index * 7) % chars.length;
        return chars.codeUnitAt(charIndex);
      }),
    );
  }
}
