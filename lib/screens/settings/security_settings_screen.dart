import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/biometric_service.dart';
import '../../utils/app_theme.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _pinEnabled = false;
  bool _fingerprintEnabled = false;
  bool _autoLogout = false;
  int _autoLogoutTime = 5; // minutes
  String _pinCode = '';

  final List<int> _logoutTimes = [1, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinEnabled = prefs.getBool('pin_enabled') ?? false;
      _fingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
      _autoLogout = prefs.getBool('auto_logout') ?? false;
      _autoLogoutTime = prefs.getInt('auto_logout_time') ?? 5;
      _pinCode = prefs.getString('pin_code') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_enabled', _pinEnabled);
    await prefs.setBool('fingerprint_enabled', _fingerprintEnabled);
    await prefs.setBool('auto_logout', _autoLogout);
    await prefs.setInt('auto_logout_time', _autoLogoutTime);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _setupPin() async {
    if (_pinEnabled) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter new PIN (4-6 digits)'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'New PIN',
                ),
                onChanged: (value) {
                  setState(() => _pinCode = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_pinCode.length >= 4) {
                  final prefs = SharedPreferences.getInstance();
                  prefs.then((p) => p.setString('pin_code', _pinCode));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pin_code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Security Settings'),
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
          
          // PIN Lock
          _buildSwitchTile(
            icon: Icons.lock,
            title: 'PIN Lock',
            subtitle: 'Lock app with PIN code',
            value: _pinEnabled,
            onChanged: (value) {
              setState(() {
                _pinEnabled = value;
                if (value) _setupPin();
              });
            },
          ),
          
          // Fingerprint
          FutureBuilder<bool>(
            future: BiometricService.isAvailable(),
            builder: (context, snapshot) {
              final available = snapshot.data ?? false;
              return _buildSwitchTile(
                icon: Icons.fingerprint,
                title: 'Fingerprint Login',
                subtitle: available
                    ? 'Use fingerprint to unlock'
                    : 'Fingerprint not available on this device',
                value: _fingerprintEnabled && available,
                onChanged: available ? (value) {
                  setState(() => _fingerprintEnabled = value);
                } : null,
              );
            },
          ),
          
          const Divider(),
          
          // Auto Logout
          _buildSwitchTile(
            icon: Icons.timer,
            title: 'Auto Logout',
            subtitle: 'Auto logout after inactivity',
            value: _autoLogout,
            onChanged: (value) {
              setState(() => _autoLogout = value);
            },
          ),
          
          if (_autoLogout)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Logout Time'),
                subtitle: Text('$_autoLogoutTime minutes'),
                trailing: DropdownButton<int>(
                  value: _autoLogoutTime,
                  items: _logoutTimes.map((time) {
                    return DropdownMenuItem(
                      value: time,
                      child: Text('$time min'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _autoLogoutTime = value);
                    }
                  },
                ),
              ),
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
    required Function(bool)? onChanged,
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
