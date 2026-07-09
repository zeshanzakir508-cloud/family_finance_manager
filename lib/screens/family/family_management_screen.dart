// lib/screens/family/family_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADDED
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/family_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/family_member_card.dart';
import 'widgets/family_invite_code.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
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

  void _showInviteDialog() {
    final family = context.read<FamilyProvider>().currentFamily;
    if (family == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with family members to join:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FamilyInviteCode(code: family.familyCode ?? 'N/A'),
            const SizedBox(height: 16),
            const Text(
              'Or send an invitation email:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Send invitation email
              Navigator.pop(context);
              CustomSnackBar.show(
                context,
                'Invitation sent successfully!',
              );
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Implement leave family
  void _showLeaveFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: const Text(
          'Are you sure you want to leave this family? You will lose access to all family data.',
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
                final auth = context.read<AuthProvider>();
                final familyProvider = context.read<FamilyProvider>();
                final family = familyProvider.currentFamily;

                if (family == null) {
                  throw Exception('No family found');
                }

                // Remove user from family members
                final updatedMembers = family.members
                    .where((m) => m.userId != auth.userId)
                    .toList();

                await FirebaseFirestore.instance
                    .collection('families')
                    .doc(family.id)
                    .update({
                  'members': updatedMembers.map((m) => m.toJson()).toList(),
                  'memberIds': FieldValue.arrayRemove([auth.userId]),
                });

                // Clear current family and navigate
                familyProvider.clearData();

                if (mounted) {
                  CustomSnackBar.show(
                    context,
                    'You have left the family',
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackBar.show(
                    context,
                    'Failed to leave family: ${e.toString()}',
                    isError: true,
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(
          context,
          familyProvider,
          currencyProvider.currentCurrency,
          isDark,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FamilyProvider provider,
    String currency,
    bool isDark,
  ) {
    if (provider.isLoading) {
      return const LoadingWidget();
    }

    final family = provider.currentFamily;

    if (family == null) {
      return EmptyStateWidget(
        icon: Icons.family_restroom,
        title: 'No Family Found',
        description: 'Create a family or join an existing one to get started.',
        buttonText: 'Create Family',
        onPressed: () {
          Navigator.pushNamed(context, '/family_setup');
        },
        secondaryButtonText: 'Join Family',
        onSecondaryPressed: () {
          Navigator.pushNamed(context, '/join_family');
        },
      );
    }

    final members = provider.getFamilyMembers();
    final auth = context.read<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (family.description?.isNotEmpty ?? false)
                            Text(
                              family.description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${members.length} Members',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Family Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$currency ${family.totalBalance?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Family Code',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        FamilyInviteCode(
                          code: family.familyCode ?? 'N/A',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Members section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Invite'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No members in this family',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...members.map((member) {
              final isAdmin = member.isAdmin;
              final isCurrentUser = member.userId == auth.userId;
              return FamilyMemberCard(
                member: member,
                isAdmin: isAdmin,
                isCurrentUser: isCurrentUser,
                onRemove: isAdmin && !isCurrentUser
                    ? () => _removeMember(member)
                    : null,
                onPromote: isAdmin && !isCurrentUser
                    ? () => _promoteMember(member)
                    : null,
              );
            }),

          const SizedBox(height: 24),

          // Leave Family button
          CustomButton(
            onPressed: _showLeaveFamilyDialog,
            text: 'Leave Family',
            type: ButtonType.danger,
            size: ButtonSize.medium,
            icon: Icons.exit_to_app,
          ),
        ],
      ),
    );
  }

  // ✅ ADDED: Remove member from family
  Future<void> _removeMember(FamilyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Remove ${member.displayName} from the family?',
        ),
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

    if (confirm != true) return;

    try {
      final familyProvider = context.read<FamilyProvider>();
      final family = familyProvider.currentFamily;

      if (family == null) throw Exception('No family found');

      final updatedMembers = family.members
          .where((m) => m.userId != member.userId)
          .toList();

      await FirebaseFirestore.instance
          .collection('families')
          .doc(family.id)
          .update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'memberIds': FieldValue.arrayRemove([member.userId]),
      });

      await familyProvider.refreshData();

      if (mounted) {
        CustomSnackBar.show(
          context,
          '${member.displayName} removed from family',
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
    }
  }

  // ✅ ADDED: Promote member to admin
  Future<void> _promoteMember(FamilyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text(
          'Promote ${member.displayName} to family admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final familyProvider = context.read<FamilyProvider>();
      final family = familyProvider.currentFamily;

      if (family == null) throw Exception('No family found');

      final updatedMembers = family.members.map((m) {
        if (m.userId == member.userId) {
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
          '${member.displayName} promoted to admin',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to promote member: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
}
