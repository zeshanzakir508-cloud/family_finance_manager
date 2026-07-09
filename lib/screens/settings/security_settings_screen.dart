// lib/screens/settings/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart'; // ✅ FIXED: Added import for BiometricType
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/biometric_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _fingerprintEnabled = false;
  bool _faceIdEnabled = false;
  bool _pinEnabled = false;
  bool _autoLogout = false;
  bool _isBiometricAvailable = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final biometricService = BiometricService();
      _isBiometricAvailable = await biometricService.checkAvailability();
      
      // ✅ FIXED: Removed () from isFingerprintEnabled (it's a getter, not a method)
      _fingerprintEnabled = biometricService.isFingerprintEnabled;
      
      // TODO: Load PIN and auto-logout settings from SharedPreferences
      _pinEnabled = false;
      _autoLogout = false;
      
      // Check face ID support
      final types = await biometricService.getAvailableBiometrics();
      // ✅ FIXED: BiometricType is now imported from local_auth
      _faceIdEnabled = types.contains(BiometricType.face);
      
    } catch (e) {
      print('Error loading security settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final biometricService = BiometricService();
      
      // Save fingerprint setting
      await biometricService.setFingerprintEnabled(_fingerprintEnabled);
      
      // TODO: Save PIN and auto-logout settings
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Security settings saved!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to save settings: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setupPin() async {
    // TODO: Navigate to PIN setup screen
    CustomSnackBar.show(
      context,
      'PIN setup coming soon',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Security Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                  Icon(
                    Icons.security,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Secure your account',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Enable additional security features',
                          style: TextStyle(
                            fontSize: 12,
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

            // Biometric section
            const Text(
              'Biometric Authentication',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (_isBiometricAvailable) ...[
              // Fingerprint
              _buildToggleTile(
                title: 'Fingerprint Login',
                subtitle: 'Use your fingerprint to login',
                value: _fingerprintEnabled,
                onChanged: (value) {
                  setState(() {
                    _fingerprintEnabled = value;
                  });
                },
                icon: Icons.fingerprint,
              ),
              const SizedBox(height: 4),

              // Face ID
              if (_faceIdEnabled)
                _buildToggleTile(
                  title: 'Face ID',
                  subtitle: 'Use Face ID to login',
                  value: _faceIdEnabled,
                  onChanged: (value) {
                    setState(() {
                      _faceIdEnabled = value;
                    });
                  },
                  icon: Icons.face,
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biometric authentication is not available on this device',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // PIN section
            const Text(
              'PIN Security',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _buildToggleTile(
              title: 'PIN Lock',
              subtitle: 'Set a PIN to secure your app',
              value: _pinEnabled,
              onChanged: (value) {
                if (value) {
                  _setupPin();
                } else {
                  setState(() {
                    _pinEnabled = false;
                  });
                }
              },
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 16),

            // Session section
            const Text(
              'Session Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _buildToggleTile(
              title: 'Auto Logout',
              subtitle: 'Automatically logout after 30 minutes of inactivity',
              value: _autoLogout,
              onChanged: (value) {
                setState(() {
                  _autoLogout = value;
                });
              },
              icon: Icons.timer,
            ),
            const SizedBox(height: 24),

            // Save Button
            CustomButton(
              onPressed: _isSaving ? null : _saveSettings,
              text: 'Save Settings',
              isLoading: _isSaving,
              type: ButtonType.primary,
              size: ButtonSize.large,
              icon: Icons.save,
            ),

            const SizedBox(height: 12),

            // Change password
            CustomButton(
              onPressed: () {
                Navigator.pushNamed(context, '/change_password');
              },
              text: 'Change Password',
              type: ButtonType.outline,
              size: ButtonSize.medium,
              icon: Icons.lock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
