// lib/screens/family/family_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../models/family_model.dart'; // ✅ FIXED: Changed from family_member_model.dart
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadFamilyData() {
    final familyProvider = context.read<FamilyProvider>();
    final family = familyProvider.currentFamily;

    if (family != null) {
      _nameController.text = family.name;
      _descriptionController.text = family.description ?? '';
    }
  }

  Future<void> _updateFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AppAuthProvider>(); // ✅ Fixed
      final familyProvider = context.read<FamilyProvider>();
      final family = familyProvider.currentFamily;

      if (family == null) {
        throw Exception('No family found');
      }

      // Check if user is admin
      if (!family.isAdmin(auth.userId)) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Only admins can update family settings',
            isError: true,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      await FirebaseFirestore.instance
          .collection('families')
          .doc(family.id)
          .update({
        'name': name,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await familyProvider.refreshData();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Family updated successfully! ✅',
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to update family: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveFamily() async {
    final confirm = await showDialog<bool>(
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        final auth = context.read<AppAuthProvider>(); // ✅ Fixed
        final familyProvider = context.read<FamilyProvider>();
        final family = familyProvider.currentFamily;

        if (family == null) {
          throw Exception('No family found');
        }

        // Remove user from family
        final updatedMembers = family.members.where((m) => m.userId != auth.userId).toList();
        final updatedMemberIds = List<String>.from(family.memberIds ?? []);
        updatedMemberIds.remove(auth.userId);

        await FirebaseFirestore.instance
            .collection('families')
            .doc(family.id)
            .update({
          'members': updatedMembers.map((m) => m.toJson()).toList(),
          'memberIds': updatedMemberIds,
        });

        // Update user's familyId
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.userId)
            .update({
          'familyId': null,
        });

        await familyProvider.refreshData();

        if (mounted) {
          CustomSnackBar.show(
            context,
            'You have left the family',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Failed to leave family: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFamily() async {
    final auth = context.read<AppAuthProvider>(); // ✅ Fixed
    final familyProvider = context.read<FamilyProvider>();
    final family = familyProvider.currentFamily;

    if (family == null) return;

    // Check if user is admin
    if (!family.isAdmin(auth.userId)) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Only admins can delete the family',
          isError: true,
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: Text(
          'Are you sure you want to delete "${family.name}"?\n\n'
          'This action cannot be undone and all family data will be lost.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        // Remove familyId from all members
        for (var member in family.members) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(member.userId)
              .update({
            'familyId': null,
          });
        }

        // Delete family
        await FirebaseFirestore.instance
            .collection('families')
            .doc(family.id)
            .delete();

        await familyProvider.refreshData();

        if (mounted) {
          CustomSnackBar.show(
            context,
            'Family deleted successfully',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Failed to delete family: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>(); // ✅ Fixed
    final familyProvider = context.watch<FamilyProvider>();
    final family = familyProvider.currentFamily;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (family == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Management')),
        body: const Center(child: Text('No family found')),
      );
    }

    final isAdmin = family.isAdmin(authProvider.userId);
    final memberCount = family.members.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Management'),
        actions: [
          if (isAdmin && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadFamilyData();
                });
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Family Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.family_restroom,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Family',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              family.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Code: ${family.familyCode ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.people,
                        label: '$memberCount Members',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.admin_panel_settings,
                        label: '${family.admins.length} Admins',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.currency_exchange,
                        label: family.currency,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Edit Form
            if (_isEditing && isAdmin) ...[
              const Text(
                'Edit Family Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Family Name',
                      hint: 'Enter family name',
                      prefixIcon: Icons.family_restroom,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a family name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter family description',
                      prefixIcon: Icons.description,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      onPressed: _isLoading ? null : _updateFamily,
                      text: 'Update Family',
                      isLoading: _isLoading,
                      type: ButtonType.primary,
                      size: ButtonSize.large,
                      icon: Icons.save,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Member Management
            const Text(
              'Member Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage family members',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              onPressed: () {
                Navigator.pushNamed(context, '/family_members');
              },
              text: 'View All Members',
              type: ButtonType.outline,
              size: ButtonSize.medium,
              icon: Icons.people,
            ),
            const SizedBox(height: 16),

            // Danger Zone
            const Divider(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These actions are irreversible. Proceed with caution.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    onPressed: _isLoading ? null : _leaveFamily,
                    text: 'Leave Family',
                    type: ButtonType.danger,
                    size: ButtonSize.medium,
                    icon: Icons.exit_to_app,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 8),
                  if (isAdmin)
                    CustomButton(
                      onPressed: _isLoading ? null : _deleteFamily,
                      text: 'Delete Family',
                      type: ButtonType.danger,
                      size: ButtonSize.medium,
                      icon: Icons.delete_forever,
                      isLoading: _isLoading,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
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
