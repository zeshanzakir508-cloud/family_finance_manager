// lib/screens/family/add_member_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../models/family_model.dart'; // ✅ FIXED: Changed from family_member_model.dart
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({Key? key}) : super(key: key);

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'member';
  bool _isLoading = false;

  final List<String> _roles = ['member', 'admin', 'viewer'];

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AppAuthProvider>(); // ✅ Fixed
      final familyProvider = context.read<FamilyProvider>();
      final family = familyProvider.currentFamily;

      if (family == null) {
        throw Exception('No family found');
      }

      final email = _emailController.text.trim();
      final displayName = _nameController.text.trim();

      // Check if user exists
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'User not found with email: $email',
            isError: true,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final existingUser = userQuery.docs.first;
      final existingUserId = existingUser.id;

      // Check if already a member
      final memberIds = List<String>.from(family.memberIds ?? []);
      if (memberIds.contains(existingUserId)) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'User is already a member of this family',
            isError: true,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // ✅ FIXED: FamilyMember from family_model.dart
      final newMember = FamilyMember(
        userId: existingUserId,
        displayName: displayName.isNotEmpty ? displayName : existingUser.data()['displayName'] ?? email.split('@').first,
        email: email,
        role: _selectedRole,
        joinedAt: DateTime.now(),
        isActive: true,
      );

      final updatedMembers = List<Map<String, dynamic>>.from(
        family.members.map((m) => m.toJson()).toList()
      );
      updatedMembers.add(newMember.toJson());

      await FirebaseFirestore.instance
          .collection('families')
          .doc(family.id)
          .update({
        'members': updatedMembers,
        'memberIds': FieldValue.arrayUnion([existingUserId]),
      });

      await familyProvider.refreshData();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Member added successfully! 🎉',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to add member: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Member'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _addMember,
            child: Text(
              'Add',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Family Member',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Invite someone to join your family',
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
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter member\'s email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _nameController,
                label: 'Display Name (Optional)',
                hint: 'Enter a name for this member',
                prefixIcon: Icons.person,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin: Can manage family settings and members\n'
                        'Member: Can view and participate\n'
                        'Viewer: Can only view',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                onPressed: _isLoading ? null : _addMember,
                text: 'Add Member',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
