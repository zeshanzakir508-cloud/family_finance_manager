// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/mode_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/remote_config_service.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBiometricEnabled = false;
  String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
    _loadLanguage();
  }

  Future<void> _loadBiometricStatus() async {
    try {
      final biometricService = BiometricService();
      _isBiometricEnabled = biometricService.isFingerprintEnabled;
      setState(() {});
    } catch (e) {
      print('❌ Error loading biometric status: $e');
    }
  }

  Future<void> _loadLanguage() async {
    try {
      // TODO: Load language from SharedPreferences
    } catch (e) {
      print('❌ Error loading language: $e');
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      final biometricService = BiometricService();
      
      if (value) {
        final isAvailable = await biometricService.checkAvailability();
        if (!isAvailable) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              'Biometric authentication is not available on this device',
              isError: true,
            );
          }
          return;
        }
        
        final authenticated = await biometricService.authenticateWithFingerprint();
        if (authenticated) {
          await biometricService.setFingerprintEnabled(true);
          setState(() {
            _isBiometricEnabled = true;
          });
          if (mounted) {
            CustomSnackBar.show(
              context,
              'Biometric login enabled successfully 🔓',
            );
          }
        } else {
          if (mounted) {
            CustomSnackBar.show(
              context,
              'Biometric authentication failed',
              isError: true,
            );
          }
        }
      } else {
        await biometricService.setFingerprintEnabled(false);
        setState(() {
          _isBiometricEnabled = false;
        });
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Biometric login disabled',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to toggle biometric: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Changed AuthProvider to AppAuthProvider
    final authProvider = context.watch<AppAuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final modeProvider = context.watch<ModeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBiometricStatus();
              CustomSnackBar.show(
                context,
                'Settings refreshed',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSection(
            title: 'Profile',
            children: [
              SettingsTile(
                icon: Icons.person,
                title: 'Profile',
                subtitle: authProvider.user?.displayName ?? 'No name',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              SettingsTile(
                icon: Icons.email,
                title: 'Email',
                subtitle: authProvider.user?.email ?? 'No email',
                trailing: const SizedBox(),
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 8),

          SettingsSection(
            title: 'Mode',
            children: [
              SettingsTile(
                icon: Icons.swap_horiz,
                title: 'Switch Mode',
                subtitle: modeProvider.isPersonalMode ? 'Personal Mode' : 'Family Mode',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/mode_selection');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          SettingsSection(
            title: 'General',
            children: [
              SettingsTile(
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: currencyProvider.currentCurrency,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/currency_settings');
                },
              ),
              SettingsTile(
                icon: Icons.brightness_6,
                title: 'Theme',
                subtitle: themeProvider.getThemeLabel(),
                trailing: Switch(
                  value: !themeProvider.isUsingSystemTheme && themeProvider.isDarkMode,
                  onChanged: (_) {
                    themeProvider.toggleTheme();
                  },
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/theme_settings');
                },
              ),
              SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: _currentLanguage,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/language_settings');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          SettingsSection(
            title: 'Security',
            children: [
              SettingsTile(
                icon: Icons.fingerprint,
                title: 'Fingerprint Login',
                subtitle: 'Enable biometric authentication',
                trailing: Switch(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometric,
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/security_settings');
                },
              ),
              SettingsTile(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your account password',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/change_password');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          SettingsSection(
            title: 'App',
            children: [
              SettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage notification settings',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/notification_settings');
                },
              ),
              SettingsTile(
                icon: Icons.backup,
                title: 'Backup & Restore',
                subtitle: 'Backup your data to cloud',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/backup_restore');
                },
              ),
              SettingsTile(
                icon: Icons.file_download,
                title: 'Export Data',
                subtitle: 'Export your data as CSV or PDF',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/export_data');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                icon: Icons.info,
                title: 'About FinFam',
                subtitle: 'Version 2.0.0',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/about');
                },
              ),
              SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/privacy_policy');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            color: isDark ? Colors.grey[800] : Colors.white,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLogoutDialog();
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // ✅ FIXED: Changed AuthProvider to AppAuthProvider
              await context.read<AppAuthProvider>().logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
