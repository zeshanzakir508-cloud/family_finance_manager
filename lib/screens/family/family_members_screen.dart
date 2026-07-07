// lib/screens/family/family_members_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/family_member_card.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({Key? key}) : super(key: key);

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final familyProvider = context.read<FamilyProvider>();
    await familyProvider.refreshData();
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _showRemoveMemberDialog(String userId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $memberName from the family?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // TODO: Implement remove member
                CustomSnackBar.show(
                  context,
                  '$memberName removed from family',
                );
              } catch (e) {
                CustomSnackBar.show(
                  context,
                  'Failed to remove member: ${e.toString()}',
                  isError: true,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showPromoteDialog(String userId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text(
          'Promote $memberName to family admin? They will be able to manage members and family settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // TODO: Implement promote member
                CustomSnackBar.show(
                  context,
                  '$memberName promoted to admin',
                );
              } catch (e) {
                CustomSnackBar.show(
                  context,
                  'Failed to promote: ${e.toString()}',
                  isError: true,
                );
              }
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(context, '/add_member');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(
          context,
          familyProvider,
          authProvider.userId,
          isDark,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FamilyProvider provider,
    String currentUserId,
    bool isDark,
  ) {
    if (provider.isLoading) {
      return const LoadingWidget();
    }

    final family = provider.currentFamily;
    if (family == null) {
      return EmptyStateWidget(
        icon: Icons.family_restroom,
        title: 'No Family',
        description: 'Create or join a family to see members.',
        buttonText: 'Create Family',
        onPressed: () {
          Navigator.pushNamed(context, '/family_setup');
        },
      );
    }

    final members = provider.getFamilyMembers();
    final isAdmin = members.any((m) => m.userId == currentUserId && m.isAdmin);

    if (members.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people,
        title: 'No Members',
        description: 'This family has no members yet.',
        buttonText: 'Invite Members',
        onPressed: () {
          Navigator.pushNamed(context, '/invite_family');
        },
      );
    }

    // Separate members into admins and regular members
    final admins = members.where((m) => m.isAdmin).toList();
    final regularMembers = members.where((m) => !m.isAdmin).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                members.length.toString(),
                Icons.people,
              ),
              _buildStatItem(
                'Admins',
                admins.length.toString(),
                Icons.admin_panel_settings,
              ),
              _buildStatItem(
                'Members',
                regularMembers.length.toString(),
                Icons.person,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Admins section
        if (admins.isNotEmpty) ...[
          const Text(
            'Admins',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...admins.map((member) {
            final isCurrentUser = member.userId == currentUserId;
            return FamilyMemberCard(
              member: member,
              isAdmin: true,
              isCurrentUser: isCurrentUser,
              onRemove: isAdmin && !isCurrentUser
                  ? () => _showRemoveMemberDialog(member.userId, member.displayName)
                  : null,
              onPromote: null, // Already admin
            );
          }),
          const SizedBox(height: 16),
        ],

        // Regular members section
        if (regularMembers.isNotEmpty) ...[
          const Text(
            'Members',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...regularMembers.map((member) {
            final isCurrentUser = member.userId == currentUserId;
            return FamilyMemberCard(
              member: member,
              isAdmin: false,
              isCurrentUser: isCurrentUser,
              onRemove: isAdmin && !isCurrentUser
                  ? () => _showRemoveMemberDialog(member.userId, member.displayName)
                  : null,
              onPromote: isAdmin && !isCurrentUser
                  ? () => _showPromoteDialog(member.userId, member.displayName)
                  : null,
            );
          }),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
    );
  }
}
