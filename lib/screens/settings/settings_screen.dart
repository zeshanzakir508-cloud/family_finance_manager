// lib/screens/settings/settings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/mode_provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isDarkMode = false;
  String _selectedCurrency = 'USD';
  bool _hasChanges = false;

  // Debounce
  Timer? _debounceTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId != null) {
      _user = await DatabaseService.getUser(userId);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _selectedCurrency = prefs.getString('currency') ?? 'USD';
      _hasChanges = false;
    });
  }

  void _debounceAction(VoidCallback action) {
    if (_isProcessing) return;
    _debounceTimer?.cancel();
    _isProcessing = true;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      action();
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveAllSettings,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Save All'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildUserInfoSection(context),
                const Divider(),
                _buildModeSection(context, modeProvider),
                const Divider(),
                _buildGeneralSettings(context),
                const Divider(),
                _buildSecuritySettings(context),
                const Divider(),
                _buildAppSettings(context),
                const Divider(),
                _buildLogoutButton(context, authService),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelChanges,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _hasChanges ? _saveAllSettings : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasChanges 
                    ? AppTheme.primaryColor 
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_hasChanges ? 'Save Changes' : 'No Changes'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAllSettings() async {
    _debounceAction(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setString('currency', _selectedCurrency);
      
      setState(() => _hasChanges = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    });
  }

  void _cancelChanges() {
    _debounceAction(() {
      if (_hasChanges) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadSettings();
                  setState(() => _hasChanges = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Changes discarded'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _markChanged() {
    setState(() => _hasChanges = true);
  }

  Widget _buildUserInfoSection(BuildContext context) {
    final isOwner = _user?.role == 'owner';
    final displayName = isOwner ? 'Owner' : (_user?.displayName ?? 'User');
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOwner ? Colors.amber : AppTheme.primaryColor,
        child: Text(
          isOwner ? '👑' : (_user?.initials ?? 'U'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(displayName),
      subtitle: Text(_user?.email ?? 'No email'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _debounceAction(() {
          Navigator.pushNamed(context, '/profile');
        });
      },
    );
  }

  Widget _buildModeSection(BuildContext context, ModeProvider modeProvider) {
    final isPersonal = modeProvider.isPersonalMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            isPersonal ? Icons.person : Icons.family_restroom,
            color: AppTheme.primaryColor,
          ),
          title: Text(
            isPersonal ? 'Personal Mode' : 'Family Mode',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            isPersonal 
                ? 'Managing personal finances' 
                : 'Managing family finances',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            _debounceAction(() {
              _showModeSwitchDialog(context);
            });
          },
        ),
      ],
    );
  }

  void _showModeSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Mode'),
        content: const Text(
          'Changing mode will navigate you to the mode selection screen. '
          'Your data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/mode-selection');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Switch Mode'),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'General',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.currency_exchange),
          title: const Text('Currency'),
          subtitle: Text(_selectedCurrency),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              // ✅ FIXED: Added .then() to handle return value
              Navigator.pushNamed(
                context, 
                '/currency-settings',
                arguments: {'currentCurrency': _selectedCurrency},
              ).then((result) {
                if (result != null && result is String && result != _selectedCurrency) {
                  setState(() {
                    _selectedCurrency = result;
                    _markChanged();
                  });
                }
              });
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          subtitle: Text(_isDarkMode ? 'Dark' : 'Light'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              // ✅ FIXED: Added .then() to handle return value
              Navigator.pushNamed(
                context,
                '/theme-settings',
                arguments: {'isDarkMode': _isDarkMode},
              ).then((result) {
                if (result != null && result is bool && result != _isDarkMode) {
                  setState(() {
                    _isDarkMode = result;
                    _markChanged();
                  });
                }
              });
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: const Text('English'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language settings coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Security',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.fingerprint),
          title: const Text('Fingerprint Login'),
          trailing: Switch(
            value: false,
            onChanged: (value) {
              _debounceAction(() {
                _showFingerprintSetup(value);
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
          onTap: () {
            _debounceAction(() {
              // ✅ FIXED: Added .then() to handle return value
              Navigator.pushNamed(context, '/security-settings').then((result) {
                if (result == true) {
                  _loadSettings();
                }
              });
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('PIN Lock'),
          trailing: Switch(
            value: false,
            onChanged: (value) {
              _debounceAction(() {
                // Handle PIN lock
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
          onTap: () {
            _debounceAction(() {
              // ✅ FIXED: Added .then() to handle return value
              Navigator.pushNamed(context, '/security-settings').then((result) {
                if (result == true) {
                  _loadSettings();
                }
              });
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_reset),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change password coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            });
          },
        ),
      ],
    );
  }

  void _showFingerprintSetup(bool value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fingerprint Login'),
        content: Text(
          value 
              ? 'Enable fingerprint login for faster access?' 
              : 'Disable fingerprint login?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                          ? 'Fingerprint login enabled!' 
                          : 'Fingerprint login disabled!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                _markChanged();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: Text(value ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'App',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              Navigator.pushNamed(context, '/notification-settings');
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup & Restore'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              Navigator.pushNamed(context, '/backup');
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              Navigator.pushNamed(context, '/privacy-policy');
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _debounceAction(() {
              Navigator.pushNamed(context, '/about');
            });
          },
        ),
        // Premium Section (Owner/Moderator Free)
        if (_user?.role == 'owner' || _user?.role == 'moderator')
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 12),
                Text(
                  _user?.role == 'owner' ? 'Owner - Free Forever' : 'Moderator - Free Forever',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          _debounceAction(() {
            _showLogoutDialog(context, authService);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Logout'),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
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
              await authService.signOut();
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
