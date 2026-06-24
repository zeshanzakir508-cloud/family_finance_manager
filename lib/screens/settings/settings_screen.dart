import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../models/transaction_model.dart';
import '../../models/notification_model.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedCurrency = 'USD';
  String _selectedLanguage = 'en';
  String? _userName;
  String? _userEmail;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'PKR', 'INR', 'AED', 'SAR'];
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ur', 'name': 'Urdu'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'hi', 'name': 'Hindi'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    // Load user profile
    if (userId != null) {
      final box = Hive.box<UserProfile>('userProfile');
      final user = box.get(userId);
      if (user != null) {
        setState(() {
          _userName = user.displayName;
          _userEmail = user.email;
          _isDarkMode = user.isDarkMode ?? false;
          _selectedCurrency = user.currency ?? 'USD';
          _selectedLanguage = user.preferredLanguage ?? 'en';
        });
      }
    }

    // Load settings from shared preferences
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _biometricEnabled = prefs.getBool('biometric') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('biometric', _biometricEnabled);

    // Update user profile
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId != null) {
      final box = Hive.box<UserProfile>('userProfile');
      final user = box.get(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          isDarkMode: _isDarkMode,
          currency: _selectedCurrency,
          preferredLanguage: _selectedLanguage,
        );
        await box.put(userId, updatedUser);
      }
    }

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
            // Profile Section
            _buildSectionHeader('Profile'),
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
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Dark Mode',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Switch between light and dark theme',
                      style: AppTheme.captionStyle,
                    ),
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
                    title: Text(
                      'Currency',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Select your preferred currency',
                      style: AppTheme.captionStyle,
                    ),
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
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Language',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Select your preferred language',
                      style: AppTheme.captionStyle,
                    ),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      items: _languages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text(lang['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
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
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Push Notifications',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Receive notifications for important updates',
                      style: AppTheme.captionStyle,
                    ),
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
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Biometric Login',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Enable fingerprint or face recognition',
                      style: AppTheme.captionStyle,
                    ),
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                    },
                    secondary: Icon(
                      _biometricEnabled
                          ? Icons.fingerprint
                          : Icons.fingerprint_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader('Account Security'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Change Password',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Update your password',
                      style: AppTheme.captionStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onTap: () {
                      _showChangePasswordDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.email_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Change Email',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Update your email address',
                      style: AppTheme.captionStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onTap: () {
                      _showChangeEmailDialog();
                    },
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
                    subtitle: Text(
                      'Permanently delete your account',
                      style: AppTheme.captionStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.errorColor,
                    ),
                    onTap: () {
                      _showDeleteAccountDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data Section
            _buildSectionHeader('Data Management'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.backup_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Backup Data',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Backup your data to cloud',
                      style: AppTheme.captionStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup feature coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.restore_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Restore Data',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: Text(
                      'Restore data from backup',
                      style: AppTheme.captionStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Restore feature coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.clear_all_outlined,
                      color: AppTheme.errorColor,
                    ),
                    title: Text(
                      'Clear Local Data',
                      style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                    subtitle: Text(
                      'Clear all local data',
                      style: AppTheme.captionStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.errorColor,
                    ),
                    onTap: () {
                      _showClearDataDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('About'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'App Version',
                      style: AppTheme.bodyStyle,
                    ),
                    subtitle: const Text('1.0.0'),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Family Finance Manager v1.0.0'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: AppTheme.bodyStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy Policy coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Terms & Conditions',
                      style: AppTheme.bodyStyle,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terms & Conditions coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTheme.bodyStyle.copyWith(
          color: AppTheme.textSecondaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog(
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
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              // Implement password change
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
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

  Future<void> _showChangeEmailDialog() async {
    final newEmailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: newEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New Email',
            hintText: 'Enter your new email address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement email change
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email change coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
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

  Future<void> _showDeleteAccountDialog() async {
    final confirm = await showDialog<bool>(
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
            const Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Type DELETE',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Enable confirm button if DELETE is typed
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.deleteAccount();

      if (success && mounted) {
        // Clear Hive data
        await Hive.box<UserProfile>('userProfile').clear();
        await Hive.box<TransactionModel>('transactions').clear();
        await Hive.box<dynamic>('appSettings').clear();

        // Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showClearDataDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'Are you sure you want to clear all local data? This will not delete your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear Hive data
      await Hive.box<UserProfile>('userProfile').clear();
      await Hive.box<TransactionModel>('transactions').clear();
      await Hive.box<dynamic>('appSettings').clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
