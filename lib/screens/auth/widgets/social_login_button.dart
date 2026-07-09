// lib/screens/auth/widgets/social_login_button.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SocialProvider {
  google,
  apple,
  facebook,
}

class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final bool showText;

  const SocialLoginButton({
    Key? key,
    required this.provider,
    this.onSuccess,
    this.onError,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleSocialLogin(context),
        icon: _getIcon(),
        label: Text(
          showText ? _getButtonText() : '',
          style: const TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _getTextColor(isDark),
          side: BorderSide(color: _getBorderColor(isDark)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _getIcon() {
    switch (provider) {
      case SocialProvider.google:
        return const Icon(Icons.g_mobiledata, size: 28);
      case SocialProvider.apple:
        return const Icon(Icons.apple, size: 28);
      case SocialProvider.facebook:
        return const Icon(Icons.facebook, size: 28);
    }
  }

  String _getButtonText() {
    switch (provider) {
      case SocialProvider.google:
        return 'Continue with Google';
      case SocialProvider.apple:
        return 'Continue with Apple';
      case SocialProvider.facebook:
        return 'Continue with Facebook';
    }
  }

  Color _getTextColor(bool isDark) {
    switch (provider) {
      case SocialProvider.google:
        return isDark ? Colors.white : Colors.black87;
      case SocialProvider.apple:
        return isDark ? Colors.white : Colors.black87;
      case SocialProvider.facebook:
        return const Color(0xFF1877F2);
    }
  }

  Color _getBorderColor(bool isDark) {
    switch (provider) {
      case SocialProvider.google:
        return isDark ? Colors.grey[600]! : Colors.grey[300]!;
      case SocialProvider.apple:
        return isDark ? Colors.grey[600]! : Colors.grey[300]!;
      case SocialProvider.facebook:
        return const Color(0xFF1877F2);
    }
  }

  Future<void> _handleSocialLogin(BuildContext context) async {
    try {
      // TODO: Implement actual social login
      // This is a placeholder - add actual implementation
      print('🔐 Social login with ${provider.name}');

      // Placeholder - simulate success
      await Future.delayed(const Duration(seconds: 1));

      onSuccess?.call();
    } catch (e) {
      print('❌ Social login failed: $e');
      onError?.call();
    }
  }
}
