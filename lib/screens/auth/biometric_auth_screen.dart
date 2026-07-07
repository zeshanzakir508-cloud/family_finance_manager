// lib/screens/auth/biometric_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/biometric_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/auth_header.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({Key? key}) : super(key: key);

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  bool _isLoading = false;
  bool _isAvailable = false;
  bool _isEnabled = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final biometricService = BiometricService();
    _isAvailable = await biometricService.checkAvailability();
    _isEnabled = await biometricService.isFingerprintAvailable();
    
    // Check if fingerprint is supported
    final isFingerprintSupported = await biometricService.isFingerprintSupported();
    if (isFingerprintSupported) {
      _biometricType = 'Fingerprint';
    } else {
      final types = await biometricService.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) {
        _biometricType = 'Face ID';
      } else if (types.contains(BiometricType.iris)) {
        _biometricType = 'Iris';
      }
    }
    
    setState(() {});
  }

  Future<void> _authenticate() async {
    if (!_isAvailable) {
      CustomSnackBar.show(
        context,
        'Biometric authentication is not available on this device',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.authenticateWithBiometric();
      
      if (success) {
        // Enable fingerprint if not already
        if (!_isEnabled) {
          await authProvider.setFingerprintEnabled(true);
        }
        
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Biometric authentication successful!',
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Authentication failed. Please try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipBiometric() async {
    // Navigate to home without biometric
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: 'Secure Your Account',
                subtitle: 'Enable biometric authentication for quick access',
              ),
              const SizedBox(height: 48),
              // Biometric Icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAvailable
                      ? Icons.fingerprint
                      : Icons.fingerprint_off,
                  size: 56,
                  color: _isAvailable
                      ? theme.primaryColor
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              // Status text
              Text(
                _isAvailable
                    ? '$_biometricType Available'
                    : 'Biometric Not Available',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isAvailable
                    ? 'Use your $_biometricType to login quickly and securely.'
                    : 'Your device does not support biometric authentication. '
                        'You can use email/password to login.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isAvailable) ...[
                CustomButton(
                  onPressed: _authenticate,
                  text: 'Enable $_biometricType Login',
                  isLoading: _isLoading,
                  type: ButtonType.primary,
                  size: ButtonSize.large,
                  icon: Icons.fingerprint,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onPressed: _skipBiometric,
                  text: 'Skip for Now',
                  type: ButtonType.outline,
                  size: ButtonSize.large,
                ),
              ] else ...[
                CustomButton(
                  onPressed: _skipBiometric,
                  text: 'Continue to App',
                  type: ButtonType.primary,
                  size: ButtonSize.large,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'You can change this later in Settings',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
