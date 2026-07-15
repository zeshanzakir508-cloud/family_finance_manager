// lib/screens/family/family_members_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../models/family_model.dart'; // ✅ FIXED: Changed from family_member_model.dart
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({Key? key}) : super(key: key);

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>(); // ✅ Fixed
    final familyProvider = context.watch<FamilyProvider>();
    final family = familyProvider.currentFamily;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (family == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Members')),
        body: const Center(child: Text('No family found')),
      );
    }

    final members = family.members;
    final isAdmin = family.isAdmin(authProvider.userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                Navigator.pushNamed(context, '/add_member');
              },
            ),
        ],
      ),
      body: members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Members Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite family members to join',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAdmin)
                    CustomButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_member');
                      },
                      text: 'Add Member',
                      type: ButtonType.primary,
                      size: ButtonSize.medium,
                      icon: Icons.person_add,
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isCurrentUser = member.userId == authProvider.userId;
                final isMemberAdmin = member.isAdmin;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMemberAdmin
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      child: Text(
                        member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMemberAdmin ? Colors.amber[700] : Colors.blue[700],
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isMemberAdmin)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (member.email != null && member.email!.isNotEmpty)
                          Text(
                            member.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        Text(
                          'Joined: ${_formatDate(member.joinedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    trailing: isAdmin && !isCurrentUser
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'remove') {
                                _removeMember(member.userId);
                              } else if (value == 'make_admin') {
                                _makeAdmin(member.userId);
                              } else if (value == 'remove_admin') {
                                _removeAdmin(member.userId);
                              }
                            },
                            itemBuilder: (context) => [
                              if (isMemberAdmin)
                                const PopupMenuItem(
                                  value: 'remove_admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 18),
                                      SizedBox(width: 8),
                                      Text('Remove Admin'),
                                    ],
                                  ),
                                ),
                              if (!isMemberAdmin)
                                const PopupMenuItem(
                                  value: 'make_admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 18),
                                      SizedBox(width: 8),
                                      Text('Make Admin'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_remove, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Remove', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : null,
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  Future<void> _removeMember(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        final familyProvider = context.read<FamilyProvider>();
        final family = familyProvider.currentFamily;

        if (family == null) throw Exception('No family found');

        final updatedMembers = family.members.where((m) => m.userId != userId).toList();
        final updatedMemberIds = List<String>.from(family.memberIds ?? []);
        updatedMemberIds.remove(userId);

        await FirebaseFirestore.instance
            .collection('families')
            .doc(family.id)
            .update({
          'members': updatedMembers.map((m) => m.toJson()).toList(),
          'memberIds': updatedMemberIds,
        });

        await familyProvider.refreshData();

        if (mounted) {
          CustomSnackBar.show(
            context,
            'Member removed successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Failed to remove member: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _makeAdmin(String userId) async {
    setState(() => _isLoading = true);

    try {
      final familyProvider = context.read<FamilyProvider>();
      final family = familyProvider.currentFamily;

      if (family == null) throw Exception('No family found');

      final updatedMembers = family.members.map((m) {
        if (m.userId == userId) {
          return m.copyWith(role: 'admin');
        }
        return m;
      }).toList();

      await FirebaseFirestore.instance
          .collection('families')
          .doc(family.id)
          .update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });

      await familyProvider.refreshData();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Member promoted to Admin',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to make admin: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAdmin(String userId) async {
    setState(() => _isLoading = true);

    try {
      final familyProvider = context.read<FamilyProvider>();
      final family = familyProvider.currentFamily;

      if (family == null) throw Exception('No family found');

      final updatedMembers = family.members.map((m) {
        if (m.userId == userId) {
          return m.copyWith(role: 'member');
        }
        return m;
      }).toList();

      await FirebaseFirestore.instance
          .collection('families')
          .doc(family.id)
          .update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });

      await familyProvider.refreshData();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Admin privileges removed',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to remove admin: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
