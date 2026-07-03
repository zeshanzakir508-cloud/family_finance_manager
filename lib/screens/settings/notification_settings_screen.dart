// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Settings
  bool _pushNotifications = true;
  bool _initialPushNotifications = true;
  bool _transactionAlerts = true;
  bool _initialTransactionAlerts = true;
  bool _budgetAlerts = true;
  bool _initialBudgetAlerts = true;
  bool _familyActivity = true;
  bool _initialFamilyActivity = true;
  bool _dailyReminders = false;
  bool _initialDailyReminders = false;
  bool _weeklySummary = true;
  bool _initialWeeklySummary = true;
  bool _monthlySummary = true;
  bool _initialMonthlySummary = true;
  
  // State
  bool _hasChanges = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
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

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('notifications_push') ?? true;
      _initialPushNotifications = _pushNotifications;
      _transactionAlerts = prefs.getBool('notifications_transactions') ?? true;
      _initialTransactionAlerts = _transactionAlerts;
      _budgetAlerts = prefs.getBool('notifications_budget') ?? true;
      _initialBudgetAlerts = _budgetAlerts;
      _familyActivity = prefs.getBool('notifications_family') ?? true;
      _initialFamilyActivity = _familyActivity;
      _dailyReminders = prefs.getBool('notifications_daily') ?? false;
      _initialDailyReminders = _dailyReminders;
      _weeklySummary = prefs.getBool('notifications_weekly') ?? true;
      _initialWeeklySummary = _weeklySummary;
      _monthlySummary = prefs.getBool('notifications_monthly') ?? true;
      _initialMonthlySummary = _monthlySummary;
      _hasChanges = false;
      _isLoading = false;
    });
  }

  void _markChanged() {
    setState(() {
      _hasChanges = _pushNotifications != _initialPushNotifications ||
          _transactionAlerts != _initialTransactionAlerts ||
          _budgetAlerts != _initialBudgetAlerts ||
          _familyActivity != _initialFamilyActivity ||
          _dailyReminders != _initialDailyReminders ||
          _weeklySummary != _initialWeeklySummary ||
          _monthlySummary != _initialMonthlySummary;
    });
  }

  void _updateSetting(bool value, Function(bool) setter) {
    _debounceAction(() {
      setter(value);
      _markChanged();
    });
  }

  Future<void> _saveSettings() async {
    _debounceAction(() async {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_push', _pushNotifications);
      await prefs.setBool('notifications_transactions', _transactionAlerts);
      await prefs.setBool('notifications_budget', _budgetAlerts);
      await prefs.setBool('notifications_family', _familyActivity);
      await prefs.setBool('notifications_daily', _dailyReminders);
      await prefs.setBool('notifications_weekly', _weeklySummary);
      await prefs.setBool('notifications_monthly', _monthlySummary);
      
      setState(() {
        _initialPushNotifications = _pushNotifications;
        _initialTransactionAlerts = _transactionAlerts;
        _initialBudgetAlerts = _budgetAlerts;
        _initialFamilyActivity = _familyActivity;
        _initialDailyReminders = _dailyReminders;
        _initialWeeklySummary = _weeklySummary;
        _initialMonthlySummary = _monthlySummary;
        _hasChanges = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context, true);
    });
  }

  void _cancelChanges() {
    _debounceAction(() {
      if (_hasChanges) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved notification changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _pushNotifications = _initialPushNotifications;
                    _transactionAlerts = _initialTransactionAlerts;
                    _budgetAlerts = _initialBudgetAlerts;
                    _familyActivity = _initialFamilyActivity;
                    _dailyReminders = _initialDailyReminders;
                    _weeklySummary = _initialWeeklySummary;
                    _monthlySummary = _initialMonthlySummary;
                    _hasChanges = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification changes discarded'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Master Switch
                      _buildMasterSwitchTile(),
                      const Divider(height: 16),
                      
                      // Transaction Alerts
                      _buildSwitchTile(
                        icon: Icons.attach_money,
                        title: 'Transaction Alerts',
                        subtitle: 'Notify when transaction is added',
                        value: _transactionAlerts && _pushNotifications,
                        enabled: _pushNotifications,
                        onChanged: (value) {
                          if (_pushNotifications) {
                            _updateSetting(value, (v) => _transactionAlerts = v);
                          }
                        },
                      ),
                      
                      // Budget Alerts
                      _buildSwitchTile(
                        icon: Icons.warning_amber,
                        title: 'Budget Alerts',
                        subtitle: 'Notify when near budget limit',
                        value: _budgetAlerts && _pushNotifications,
                        enabled: _pushNotifications,
                        onChanged: (value) {
                          if (_pushNotifications) {
                            _updateSetting(value, (v) => _budgetAlerts = v);
                          }
                        },
                      ),
                      
                      // Family Activity
                      _buildSwitchTile(
                        icon: Icons.family_restroom,
                        title: 'Family Activity',
                        subtitle: 'Notify about family member activities',
                        value: _familyActivity && _pushNotifications,
                        enabled: _pushNotifications,
                        onChanged: (value) {
                          if (_pushNotifications) {
                            _updateSetting(value, (v) => _familyActivity = v);
                          }
                        },
                      ),
                      
                      const Divider(height: 16),
                      
                      // Daily Reminders
                      _buildSwitchTile(
                        icon: Icons.alarm,
                        title: 'Daily Reminders',
                        subtitle: 'Get daily reminder to log expenses',
                        value: _dailyReminders && _pushNotifications,
                        enabled: _pushNotifications,
                        onChanged: (value) {
                          if (_pushNotifications) {
                            _updateSetting(value, (v) => _dailyReminders = v);
                          }
                        },
                      ),
                      
                      // Weekly Summary
                      _buildSwitchTile(
                        icon: Icons.calendar_view_week,
                        title: 'Weekly Summary',
                        subtitle: 'Get weekly finance summary',
                        value: _weeklySummary && _pushNotifications,
                        enabled: _pushNotifications,
                        onChanged: (value) {
                          if (_pushNotifications) {
                            _updateSetting(value, (v) => _weeklySummary = v);
                          }
                        },
                      ),
                      
                      // Monthly Summary
                      _buildSwitchTile(
                        icon: Icons.calendar_month,
                        title: 'Monthly Summary',
                        subtitle: 'Get monthly finance summary',
                        value: _monthlySummary && _pushNotifications,
                        enabled: _pushNotifications,
                        onChanged: (value) {
                          if (_pushNotifications) {
                            _updateSetting(value, (v) => _monthlySummary = v);
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info Card
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                // Bottom Buttons
                _buildBottomButtons(),
              ],
            ),
    );
  }

  Widget _buildMasterSwitchTile() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _pushNotifications ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _pushNotifications ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active,
            color: _pushNotifications ? AppTheme.primaryColor : Colors.grey,
            size: 28,
          ),
        ),
        title: Text(
          'Push Notifications',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _pushNotifications ? 'All notifications are enabled' : 'All notifications are disabled',
          style: TextStyle(
            fontSize: 12,
            color: _pushNotifications ? Colors.green : Colors.grey.shade600,
          ),
        ),
        value: _pushNotifications,
        onChanged: (value) {
          _updateSetting(value, (v) => _pushNotifications = v);
        },
        activeColor: AppTheme.primaryColor,
        activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    final isActive = value && enabled;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive ? AppTheme.primaryColor.withOpacity(0.2) : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? AppTheme.primaryColor : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? null : Colors.grey.shade500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        value: value && enabled,
        onChanged: enabled ? onChanged : null,
        activeColor: AppTheme.primaryColor,
        activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildInfoCard() {
    final activeCount = [
      _pushNotifications,
      _transactionAlerts && _pushNotifications,
      _budgetAlerts && _pushNotifications,
      _familyActivity && _pushNotifications,
      _dailyReminders && _pushNotifications,
      _weeklySummary && _pushNotifications,
      _monthlySummary && _pushNotifications,
    ].where((v) => v == true).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_activeCount of 7 notifications active',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Manage your notification preferences here',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
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
              onPressed: _hasChanges ? _saveSettings : null,
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
}
