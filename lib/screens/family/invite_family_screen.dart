// lib/screens/family/invite_family_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
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
      // TODO: Implement send invite
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Invitation sent successfully! 📧',
        );
        _emailController.clear();
        _messageController.clear();
        Navigator.pop(context);
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
              // Family info
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
                          code: family.familyCode ?? 'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share invite code
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
                      family.familyCode ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // TODO: Copy to clipboard
                        CustomSnackBar.show(
                          context,
                          'Code copied to clipboard!',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Or send email invite
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

              // Email input
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

              // Personal message
              CustomTextField(
                controller: _messageController,
                label: 'Personal Message (Optional)',
                hint: 'Add a personal message to your invite',
                prefixIcon: Icons.message,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Send button
              CustomButton(
                onPressed: _isLoading ? null : _sendInvite,
                text: 'Send Invitation',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.send,
              ),
              const SizedBox(height: 12),

              // Share via other apps
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
                    icon: Icons.whatsapp,
                    color: Colors.green,
                    onTap: () {
                      // TODO: Share via WhatsApp
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildShareButton(
                    icon: Icons.message,
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Share via SMS
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildShareButton(
                    icon: Icons.more_horiz,
                    color: Colors.grey,
                    onTap: () {
                      // TODO: Share via other apps
                    },
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
