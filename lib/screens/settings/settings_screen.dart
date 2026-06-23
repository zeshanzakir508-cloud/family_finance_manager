import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../models/transaction_model.dart';
import '../../models/family_member_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _darkMode = false;
  bool _fingerprintEnabled = false;
  String _currency = 'PKR';

  final List<String> _currencies = ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _fingerprintEnabled = prefs.getBool('fingerprintEnabled') ?? false;
      _currency = prefs.getString('currency') ?? 'PKR';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 16),
            _buildPreferencesSection(),
            const SizedBox(height: 16),
            _buildAppInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserProfile>('userProfile').listenable(),
      builder: (context, Box<UserProfile> box, _) {
        final profile = box.get('profile');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showEditProfileDialog(profile),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const Divider(),
              if (profile != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline, color: AppTheme.textLight),
                  title: Text(profile.name, style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  )),
                  subtitle: Text('Name', style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  )),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined, color: AppTheme.textLight),
                  title: Text(profile.email, style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  )),
                  subtitle: Text('Email', style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  )),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined, color: AppTheme.textLight),
                  title: Text(profile.phoneNumber, style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  )),
                  subtitle: Text('Phone', style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  )),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No profile found. Please complete your profile.'),
                ),
                ElevatedButton(
                  onPressed: () => _showEditProfileDialog(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Profile'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(UserProfile? profile) {
    final nameController = TextEditingController(text: profile?.name ?? '');
    final fatherNameController = TextEditingController(text: profile?.fatherName ?? '');
    final phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    final emailController = TextEditingController(text: profile?.email ?? '');
    final addressController = TextEditingController(text: profile?.address ?? '');
    final cityController = TextEditingController(text: profile?.city ?? '');
    final occupationController = TextEditingController(text: profile?.occupation ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: fatherNameController,
                        decoration: const InputDecoration(
                          labelText: 'Father/Husband Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: occupationController,
                        decoration: const InputDecoration(
                          labelText: 'Occupation (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final box = Hive.box<UserProfile>('userProfile');
                        final newProfile = UserProfile(
                          uid: profile?.uid ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          fatherName: fatherNameController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                          email: emailController.text.trim(),
                          address: addressController.text.trim().isNotEmpty
                              ? addressController.text.trim()
                              : null,
                          city: cityController.text.trim().isNotEmpty
                              ? cityController.text.trim()
                              : null,
                          occupation: occupationController.text.trim().isNotEmpty
                              ? occupationController.text.trim()
                              : null,
                          createdAt: profile?.createdAt ?? DateTime.now(),
                          isActive: true,
                        );
                        await box.put('profile', newProfile);
                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile saved successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: AppTheme.primary),
              const SizedBox(width: 10),
              const Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Mode'),
            subtitle: Text(
              'Enable dark theme',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            value: _darkMode,
            onChanged: (value) async {
              setState(() => _darkMode = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('darkMode', value);
            },
            activeColor: AppTheme.primary,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fingerprint Login'),
            subtitle: Text(
              'Login with fingerprint',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            value: _fingerprintEnabled,
            onChanged: (value) async {
              setState(() => _fingerprintEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('fingerprintEnabled', value);
            },
            activeColor: AppTheme.primary,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.currency_exchange, color: AppTheme.primary, size: 20),
            ),
            title: const Text('Currency'),
            subtitle: Text(
              _currency,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            trailing: DropdownButton<String>(
              value: _currency,
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              items: _currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _currency = value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('currency', value);
                }
              },
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storage, color: AppTheme.info, size: 20),
                  ),
                  title: const Text('Transactions'),
                  subtitle: Text(
                    '${Hive.box<TransactionModel>('transactions').values.length} entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1ABC9C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.family_restroom, color: Color(0xFF1ABC9C), size: 20),
                  ),
                  title: const Text('Family'),
                  subtitle: Text(
                    '${Hive.box<FamilyMemberModel>('familyMembers').values.length} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: AppTheme.info),
              const SizedBox(width: 10),
              const Text(
                'App Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apps, color: AppTheme.primary, size: 20),
            ),
            title: const Text('App Version'),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: AppTheme.error, size: 20),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: _showLogoutDialog,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever, color: AppTheme.error, size: 20),
            ),
            title: const Text(
              'Delete All Data',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: _showDeleteDataDialog,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = AuthService();
              await authService.signOut();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete All Data',
          style: TextStyle(color: AppTheme.error),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will permanently delete ALL your data:'),
            SizedBox(height: 8),
            Text('• All transactions'),
            Text('• Family members'),
            Text('• Profile information'),
            Text('• Settings'),
            SizedBox(height: 8),
            Text('This action cannot be undone!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final transactionsBox = Hive.box<TransactionModel>('transactions');
              final familyBox = Hive.box<FamilyMemberModel>('familyMembers');
              final profileBox = Hive.box<UserProfile>('userProfile');
              final settingsBox = Hive.box<Map>('settings');

              await transactionsBox.clear();
              await familyBox.clear();
              await profileBox.clear();
              await settingsBox.clear();

              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data deleted'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}