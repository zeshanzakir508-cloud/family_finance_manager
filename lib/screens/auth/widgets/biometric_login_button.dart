// lib/screens/auth/widgets/biometric_login_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/biometric_service.dart';
import '../../../providers/auth_provider.dart';

class BiometricLoginButton extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;
  final bool showText;

  const BiometricLoginButton({
    Key? key,
    this.onSuccess,
    this.onFailure,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final biometricService = BiometricService();
    final isEnabled = biometricService.isFingerprintEnabled;
    final isAvailable = biometricService.isAvailable;

    if (!isEnabled || !isAvailable) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            final success = await authProvider.authenticateWithBiometric();
            if (success) {
              onSuccess?.call();
            } else {
              onFailure?.call();
            }
          } catch (e) {
            onFailure?.call();
          }
        },
        icon: const Icon(Icons.fingerprint, size: 28),
        label: Text(
          showText ? 'Login with Fingerprint' : '',
          style: const TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
