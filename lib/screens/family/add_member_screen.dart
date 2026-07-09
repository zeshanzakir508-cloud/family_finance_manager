// lib/screens/family/add_member_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/family_model.dart';
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
  final _messageController = TextEditingController();
  
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Implement add member
  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final familyProvider = context.read<FamilyProvider>();
      final family = familyProvider.currentFamily;

      if (family == null) {
        throw Exception('No family found');
      }

      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final role = _isAdmin ? 'admin' : 'member';

      // Check if user exists
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String userId;
      String displayName = name;

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        userId = userDoc.id;
        final userData = userDoc.data();
        displayName = userData['displayName'] ?? name;
      } else {
        // Create new user profile
        final newUserRef = FirebaseFirestore.instance.collection('users').doc();
        userId = newUserRef.id;
        
        await newUserRef.set({
          'uid': userId,
          'email': email,
          'displayName': name,
          'username': email.split('@').first,
          'role': 'member',
          'familyId': family.id,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'photoUrl': '',
          'settings': {
            'currency': 'USD',
            'theme': 'system',
            'notifications': true,
          },
        });
      }

      // Check if user already in family
      if (family.memberIds.contains(userId)) {
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

      // Add member to family
      final newMember = FamilyMember(
        userId: userId,
        displayName: displayName,
        email: email,
        role: role,
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
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Update user's familyId
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'familyId': family.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh family data
      await familyProvider.refreshData();

      if (mounted) {
        CustomSnackBar.show(
          context,
          '$displayName added to family as ${_isAdmin ? "Admin" : "Member"}! 🎉',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add,
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
                            'Add Family Member',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Add a new member to your family',
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

              // Name
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter member\'s full name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Email
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

              // Role selection
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Member'),
                            value: false,
                            groupValue: _isAdmin,
                            onChanged: (value) {
                              setState(() {
                                _isAdmin = false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Admin'),
                            value: true,
                            groupValue: _isAdmin,
                            onChanged: (value) {
                              setState(() {
                                _isAdmin = true;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Message
              CustomTextField(
                controller: _messageController,
                label: 'Personal Message (Optional)',
                hint: 'Add a welcome message',
                prefixIcon: Icons.message,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Admins can manage members and family settings. '
                        'Members can view and add transactions.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Add Button
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
