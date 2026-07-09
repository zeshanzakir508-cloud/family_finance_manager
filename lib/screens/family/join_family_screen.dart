// lib/screens/family/join_family_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADDED
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/family_model.dart'; // ✅ ADDED
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({Key? key}) : super(key: key);

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Implement join family with code
  Future<void> _joinFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final familyCode = _codeController.text.trim().toUpperCase();

      // Find family by code
      final query = await FirebaseFirestore.instance
          .collection('families')
          .where('familyCode', isEqualTo: familyCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'No family found with code: $familyCode',
            isError: true,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final familyDoc = query.docs.first;
      final familyData = familyDoc.data();
      final familyId = familyDoc.id;

      // Check if user is already a member
      final memberIds = List<String>.from(familyData['memberIds'] ?? []);
      if (memberIds.contains(auth.userId)) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'You are already a member of this family',
            isError: true,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Add user to family
      final newMember = FamilyMember(
        userId: auth.userId,
        displayName: auth.userName,
        email: auth.userEmail,
        role: 'member',
        joinedAt: DateTime.now(),
        isActive: true,
      );

      final updatedMembers = List<Map<String, dynamic>>.from(familyData['members'] ?? []);
      updatedMembers.add(newMember.toJson());

      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .update({
        'members': updatedMembers,
        'memberIds': FieldValue.arrayUnion([auth.userId]),
      });

      // Update family provider
      final familyProvider = context.read<FamilyProvider>();
      await familyProvider.refreshData();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Successfully joined ${familyData['name']}! 🎉',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to join family: ${e.toString()}',
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
        title: const Text('Join Family'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _joinFamily,
            child: Text(
              'Join',
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people,
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
                            'Join a Family',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Enter the family code to join',
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
              const SizedBox(height: 32),

              // Family code input
              CustomTextField(
                controller: _codeController,
                label: 'Family Code',
                hint: 'e.g., ABC123',
                prefixIcon: Icons.code,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a family code';
                  }
                  if (value.length != 6) {
                    return 'Family code must be 6 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _joinFamily(),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-character code shared by your family admin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

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
                        'You will be added as a member of this family. '
                        'Family admins can manage your access.',
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

              // Join Button
              CustomButton(
                onPressed: _isLoading ? null : _joinFamily,
                text: 'Join Family',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.people,
              ),
              const SizedBox(height: 12),

              // Create Family link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have a family?',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/family_setup');
                    },
                    child: const Text('Create One'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
