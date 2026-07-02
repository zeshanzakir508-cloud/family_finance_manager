import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _transactionAlerts = true;
  bool _budgetAlerts = true;
  bool _familyActivity = true;
  bool _dailyReminders = false;
  bool _weeklySummary = true;
  bool _monthlySummary = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('notifications_push') ?? true;
      _transactionAlerts = prefs.getBool('notifications_transactions') ?? true;
      _budgetAlerts = prefs.getBool('notifications_budget') ?? true;
      _familyActivity = prefs.getBool('notifications_family') ?? true;
      _dailyReminders = prefs.getBool('notifications_daily') ?? false;
      _weeklySummary = prefs.getBool('notifications_weekly') ?? true;
      _monthlySummary = prefs.getBool('notifications_monthly') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_push', _pushNotifications);
    await prefs.setBool('notifications_transactions', _transactionAlerts);
    await prefs.setBool('notifications_budget', _budgetAlerts);
    await prefs.setBool('notifications_family', _familyActivity);
    await prefs.setBool('notifications_daily', _dailyReminders);
    await prefs.setBool('notifications_weekly', _weeklySummary);
    await prefs.setBool('notifications_monthly', _monthlySummary);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Enable all notifications',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
            },
          ),
          const Divider(),
          _buildSwitchTile(
            icon: Icons.attach_money,
            title: 'Transaction Alerts',
            subtitle: 'Notify when transaction is added',
            value: _transactionAlerts && _pushNotifications,
            onChanged: (value) {
              if (_pushNotifications) {
                setState(() => _transactionAlerts = value);
              }
            },
          ),
          _buildSwitchTile(
            icon: Icons.warning_amber,
            title: 'Budget Alerts',
            subtitle: 'Notify when near budget limit',
            value: _budgetAlerts && _pushNotifications,
            onChanged: (value) {
              if (_pushNotifications) {
                setState(() => _budgetAlerts = value);
              }
            },
          ),
          _buildSwitchTile(
            icon: Icons.family_restroom,
            title: 'Family Activity',
            subtitle: 'Notify about family member activities',
            value: _familyActivity && _pushNotifications,
            onChanged: (value) {
              if (_pushNotifications) {
                setState(() => _familyActivity = value);
              }
            },
          ),
          const Divider(),
          _buildSwitchTile(
            icon: Icons.alarm,
            title: 'Daily Reminders',
            subtitle: 'Get daily reminder to log expenses',
            value: _dailyReminders && _pushNotifications,
            onChanged: (value) {
              if (_pushNotifications) {
                setState(() => _dailyReminders = value);
              }
            },
          ),
          _buildSwitchTile(
            icon: Icons.calendar_view_week,
            title: 'Weekly Summary',
            subtitle: 'Get weekly finance summary',
            value: _weeklySummary && _pushNotifications,
            onChanged: (value) {
              if (_pushNotifications) {
                setState(() => _weeklySummary = value);
              }
            },
          ),
          _buildSwitchTile(
            icon: Icons.calendar_month,
            title: 'Monthly Summary',
            subtitle: 'Get monthly finance summary',
            value: _monthlySummary && _pushNotifications,
            onChanged: (value) {
              if (_pushNotifications) {
                setState(() => _monthlySummary = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(icon, color: value ? AppTheme.primaryColor : Colors.grey),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}
