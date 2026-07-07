// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _budgetAlerts = true;
  bool _transactionAlerts = true;
  bool _familyUpdates = true;
  bool _dailyReminders = false;
  bool _weeklyReports = false;
  bool _marketingUpdates = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // TODO: Load from SharedPreferences
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      // TODO: Save to SharedPreferences
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Notification settings saved!',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage your notification preferences',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can customize which notifications you receive.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Push notifications
                  _buildToggleTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive push notifications on your device',
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                    icon: Icons.notifications_active,
                  ),
                  const SizedBox(height: 8),

                  // Email notifications
                  _buildToggleTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                    },
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Notification Types',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Budget alerts
                  _buildToggleTile(
                    title: 'Budget Alerts',
                    subtitle: 'Get notified when you exceed budget limits',
                    value: _budgetAlerts,
                    onChanged: (value) {
                      setState(() {
                        _budgetAlerts = value;
                      });
                    },
                    icon: Icons.speed,
                  ),
                  const SizedBox(height: 4),

                  // Transaction alerts
                  _buildToggleTile(
                    title: 'Transaction Alerts',
                    subtitle: 'Get notified for new transactions',
                    value: _transactionAlerts,
                    onChanged: (value) {
                      setState(() {
                        _transactionAlerts = value;
                      });
                    },
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 4),

                  // Family updates
                  _buildToggleTile(
                    title: 'Family Updates',
                    subtitle: 'Get notified about family activities',
                    value: _familyUpdates,
                    onChanged: (value) {
                      setState(() {
                        _familyUpdates = value;
                      });
                    },
                    icon: Icons.family_restroom,
                  ),
                  const SizedBox(height: 4),

                  // Daily reminders
                  _buildToggleTile(
                    title: 'Daily Reminders',
                    subtitle: 'Get daily reminders to track expenses',
                    value: _dailyReminders,
                    onChanged: (value) {
                      setState(() {
                        _dailyReminders = value;
                      });
                    },
                    icon: Icons.alarm,
                  ),
                  const SizedBox(height: 4),

                  // Weekly reports
                  _buildToggleTile(
                    title: 'Weekly Reports',
                    subtitle: 'Get weekly summary reports',
                    value: _weeklyReports,
                    onChanged: (value) {
                      setState(() {
                        _weeklyReports = value;
                      });
                    },
                    icon: Icons.assessment,
                  ),
                  const SizedBox(height: 4),

                  // Marketing updates
                  _buildToggleTile(
                    title: 'Marketing Updates',
                    subtitle: 'Receive updates about new features and offers',
                    value: _marketingUpdates,
                    onChanged: (value) {
                      setState(() {
                        _marketingUpdates = value;
                      });
                    },
                    icon: Icons.campaign,
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
