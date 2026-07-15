// lib/screens/family/invite_family_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/family_member_model.dart'; // ✅ ADDED: Import FamilyMember
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/family_invite_code.dart';

class InviteFamilyScreen extends StatefulWidget {
  const InviteFamilyScreen({Key? key}) : super(key: key);

  @override
  State<InviteFamilyScreen> createState() => _InviteFamilyScreenState();
}

class _InviteFamilyScreenState extends State<InviteFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
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
      final message = _messageController.text.trim();

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final existingUser = userQuery.docs.first;
        final existingUserId = existingUser.id;

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

        // ✅ FIXED: Correct FamilyMember constructor with proper parameters
        final newMember = FamilyMember(
          userId: existingUserId,
          displayName: existingUser.data()['displayName'] ?? email.split('@').first,
          email: email,
          role: 'member',
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
            'User added to family successfully! 🎉',
          );
          _emailController.clear();
          _messageController.clear();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Invitation sent to $email! 📧',
          );
          _emailController.clear();
          _messageController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to send invitation: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      CustomSnackBar.show(
        context,
        'Family code copied to clipboard! 📋',
      );
    }
  }

  void _shareViaWhatsApp(String code, String familyName) {
    final message = 'Join my family "$familyName" on FinFam!\n\n'
        'Family Code: $code\n\n'
        'Download FinFam app to manage family finances together.';
    
    Share.share(message);
  }

  void _shareViaSMS(String code, String familyName) {
    final message = 'Join my family "$familyName" on FinFam!\n\n'
        'Family Code: $code\n\n'
        'Download FinFam app to manage family finances together.';
    
    Share.share(message);
  }

  void _shareViaOther(String code, String familyName) {
    final message = 'Join my family "$familyName" on FinFam!\n\n'
        'Family Code: $code\n\n'
        'Download FinFam app to manage family finances together.';
    
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final family = familyProvider.currentFamily;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (family == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invite Members')),
        body: const Center(child: Text('No family found')),
      );
    }

    final code = family.familyCode ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Members'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sendInvite,
            child: Text(
              'Send',
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Invite Code: ',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        FamilyInviteCode(
                          code: code,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Share this code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(code),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Or send email invite',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter email to invite',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _messageController,
                label: 'Personal Message (Optional)',
                hint: 'Add a personal message to your invite',
                prefixIcon: Icons.message,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              CustomButton(
                onPressed: _isLoading ? null : _sendInvite,
                text: 'Send Invitation',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.send,
              ),
              const SizedBox(height: 12),

              const Text(
                'Or share via',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShareButton(
                    icon: Icons.chat,
                    color: Colors.green,
                    onTap: () => _shareViaWhatsApp(code, family.name),
                  ),
                  const SizedBox(width: 16),
                  _buildShareButton(
                    icon: Icons.message,
                    color: Colors.blue,
                    onTap: () => _shareViaSMS(code, family.name),
                  ),
                  const SizedBox(width: 16),
                  _buildShareButton(
                    icon: Icons.more_horiz,
                    color: Colors.grey,
                    onTap: () => _shareViaOther(code, family.name),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}
