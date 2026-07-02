import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId != null) {
      _user = await DatabaseService.getUser(userId);
    }
    setState(() => _isLoading = false);
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
      ),
      body: ListView(
        children: [
          // User Info Section
          _buildUserInfoSection(context),
          
          const Divider(),
          
          // Mode Section
          _buildModeSection(context, modeProvider),
          
          const Divider(),
          
          // General Settings
          _buildGeneralSettings(context),
          
          const Divider(),
          
          // Security
          _buildSecuritySettings(context),
          
          const Divider(),
          
          // App Settings
          _buildAppSettings(context),
          
          const Divider(),
          
          // Logout
          _buildLogoutButton(context, authService),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Text(
          _user?.initials ?? 'U',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(_user?.displayName ?? 'User'),
      subtitle: Text(_user?.email ?? 'No email'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pushNamed(context, '/profile');
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
                  isPersonal ? 'Active' : 'Active',
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
            _showModeSwitchDialog(context);
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
          subtitle: Text(_user?.currency ?? 'USD'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/currency-settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          subtitle: Text(_isDarkMode ? 'Dark' : 'Light'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/theme-settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: const Text('English'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Language settings
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
            onChanged: (value) {},
            activeColor: AppTheme.primaryColor,
          ),
          onTap: () {
            Navigator.pushNamed(context, '/security-settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('PIN Lock'),
          trailing: Switch(
            value: false,
            onChanged: (value) {},
            activeColor: AppTheme.primaryColor,
          ),
          onTap: () {
            Navigator.pushNamed(context, '/security-settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_reset),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Change password
          },
        ),
      ],
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
            Navigator.pushNamed(context, '/notification-settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup & Restore'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/backup');
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/privacy-policy');
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/about');
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          _showLogoutDialog(context, authService);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
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
              Navigator.pushReplacementNamed(context, '/login');
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
