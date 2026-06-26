import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/mode_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _fingerprintEnabled = false;
  String _selectedCurrency = 'USD';
  String? _userName;
  String? _userEmail;

  final List<String> _currencies = Constants.currencies;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId != null) {
      final user = DatabaseService.getUser(userId);
      if (user != null) {
        setState(() {
          _userName = user.displayName;
          _userEmail = user.email;
          _isDarkMode = user.isDarkMode ?? false;
          _selectedCurrency = user.currency ?? 'USD';
        });
      }
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(Constants.notificationsKey) ?? true;
      _fingerprintEnabled = prefs.getBool(Constants.fingerprintKey) ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId != null) {
      final user = DatabaseService.getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          isDarkMode: _isDarkMode,
          currency: _selectedCurrency,
        );
        await DatabaseService.saveUser(updatedUser);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.notificationsKey, _notificationsEnabled);
    await prefs.setBool(Constants.fingerprintKey, _fingerprintEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            _buildPreferencesSection(),
            const SizedBox(height: 24),
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            _buildSecuritySection(),
            const SizedBox(height: 24),
            _buildModeSection(modeProvider),
            const SizedBox(height: 24),
            _buildAboutSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              radius: 28,
              child: Text(
                _userName?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(
              _userName ?? 'User',
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              _userEmail ?? 'No email',
              style: AppTheme.captionStyle,
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              // Navigate to profile edit
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
                secondary: Icon(
                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Currency'),
                subtitle: const Text('Select your preferred currency'),
                trailing: DropdownButton<String>(
                  value: _selectedCurrency,
                  items: _currencies.map((currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications for important updates'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Fingerprint Login'),
                subtitle: const Text('Enable fingerprint or face recognition'),
                value: _fingerprintEnabled,
                onChanged: (value) {
                  setState(() {
                    _fingerprintEnabled = value;
                  });
                },
                secondary: Icon(
                  _fingerprintEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Change Password'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: _showChangePasswordDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorColor,
                ),
                title: Text(
                  'Delete Account',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSection(ModeProvider modeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              modeProvider.isPersonalMode ? Icons.person : Icons.family_restroom,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Current Mode'),
            subtitle: Text(
              modeProvider.isPersonalMode ? 'Personal Mode' : 'Family Mode',
            ),
            trailing: DropdownButton<String>(
              value: modeProvider.isPersonalMode ? 'personal' : 'family',
              items: const [
                DropdownMenuItem(value: 'personal', child: Text('Personal')),
                DropdownMenuItem(value: 'family', child: Text('Family')),
              ],
              onChanged: (value) {
                if (value != null) {
                  modeProvider.setMode(value);
                  setState(() {});
                  if (value == 'personal') {
                    Navigator.pushReplacementNamed(context, '/personal-dashboard');
                  } else {
                    Navigator.pushReplacementNamed(context, '/family-dashboard');
                  }
                }
              },
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
            ),
            title: const Text('App Version'),
            subtitle: const Text(Constants.appVersion),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${Constants.appName} v${Constants.appVersion}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);

              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final success = await authService.updatePassword(
                newPasswordController.text,
              );

              if (!mounted) return;
              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update password.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account?',
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter Password *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Type "DELETE" to confirm *',
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (confirmController.text != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type "DELETE" to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final authService = Provider.of<AuthService>(context, listen: false);
              final success = await authService.deleteAccount();

              if (success) {
                await DatabaseService.clearAllData();

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete account. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
