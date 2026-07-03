// lib/screens/settings/security_settings_screen.dart
import 'dart:async';
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
  bool _initialPinEnabled = false;
  bool _fingerprintEnabled = false;
  bool _initialFingerprintEnabled = false;
  bool _autoLogout = false;
  bool _initialAutoLogout = false;
  int _autoLogoutTime = 5;
  int _initialAutoLogoutTime = 5;
  String _pinCode = '';
  bool _hasChanges = false;
  bool _isLoading = false;
  bool _isProcessing = false;

  Timer? _debounceTimer;
  final List<int> _logoutTimes = [1, 5, 10, 15, 30, 60];

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
      _pinEnabled = prefs.getBool('pin_enabled') ?? false;
      _initialPinEnabled = _pinEnabled;
      _fingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
      _initialFingerprintEnabled = _fingerprintEnabled;
      _autoLogout = prefs.getBool('auto_logout') ?? false;
      _initialAutoLogout = _autoLogout;
      _autoLogoutTime = prefs.getInt('auto_logout_time') ?? 5;
      _initialAutoLogoutTime = _autoLogoutTime;
      _pinCode = prefs.getString('pin_code') ?? '';
      _hasChanges = false;
      _isLoading = false;
    });
  }

  void _markChanged() {
    setState(() {
      _hasChanges = _pinEnabled != _initialPinEnabled ||
          _fingerprintEnabled != _initialFingerprintEnabled ||
          _autoLogout != _initialAutoLogout ||
          _autoLogoutTime != _initialAutoLogoutTime;
    });
  }

  Future<void> _saveSettings() async {
    _debounceAction(() async {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pin_enabled', _pinEnabled);
      await prefs.setBool('fingerprint_enabled', _fingerprintEnabled);
      await prefs.setBool('auto_logout', _autoLogout);
      await prefs.setInt('auto_logout_time', _autoLogoutTime);
      
      setState(() {
        _initialPinEnabled = _pinEnabled;
        _initialFingerprintEnabled = _fingerprintEnabled;
        _initialAutoLogout = _autoLogout;
        _initialAutoLogoutTime = _autoLogoutTime;
        _hasChanges = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security settings saved successfully'),
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
            content: const Text('You have unsaved security changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _pinEnabled = _initialPinEnabled;
                    _fingerprintEnabled = _initialFingerprintEnabled;
                    _autoLogout = _initialAutoLogout;
                    _autoLogoutTime = _initialAutoLogoutTime;
                    _hasChanges = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Security changes discarded'),
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

  Future<void> _setupPin() async {
    _debounceAction(() {
      if (_pinEnabled) {
        _showChangePinDialog();
      } else {
        _showSetPinDialog();
      }
    });
  }

  void _showSetPinDialog() {
    String newPin = '';
    String confirmPin = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a 4-6 digit PIN to lock the app'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (value) => newPin = value,
            ),
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Confirm PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (value) => confirmPin = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _pinEnabled = false;
                _markChanged();
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPin.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be at least 4 digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (newPin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PINs do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              _savePin(newPin);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    String currentPin = '';
    String newPin = '';
    String confirmPin = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Current PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (value) => currentPin = value,
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (value) => newPin = value,
            ),
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Confirm PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (value) => confirmPin = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (currentPin != _pinCode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Current PIN is incorrect'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (newPin.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be at least 4 digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (newPin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PINs do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              _savePin(newPin);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin_code', pin);
    setState(() {
      _pinCode = pin;
      _pinEnabled = true;
      _markChanged();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN set successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testFingerprint() async {
    _debounceAction(() async {
      final available = await BiometricService.isAvailable();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to test fingerprint',  // <-- FIXED: Added reason parameter
      );
      
      if (authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint authentication successful! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint authentication failed ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
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
                      // PIN Lock
                      _buildSwitchTile(
                        icon: Icons.lock,
                        title: 'PIN Lock',
                        subtitle: _pinEnabled 
                            ? 'PIN is enabled' 
                            : 'Lock app with PIN code',
                        value: _pinEnabled,
                        onChanged: (value) {
                          _debounceAction(() {
                            setState(() {
                              _pinEnabled = value;
                              if (value) {
                                _setupPin();
                              } else {
                                // Disable PIN
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Disable PIN?'),
                                    content: const Text('Are you sure you want to disable PIN lock?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _pinEnabled = true;
                                            _markChanged();
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.remove('pin_code');
                                          setState(() {
                                            _pinCode = '';
                                            _markChanged();
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('PIN disabled'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Disable'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              _markChanged();
                            });
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
                              _debounceAction(() {
                                if (value) {
                                  _testFingerprint();
                                }
                                setState(() {
                                  _fingerprintEnabled = value;
                                  _markChanged();
                                });
                              });
                            } : null,
                          );
                        },
                      ),
                      
                      const Divider(height: 24),
                      
                      // Auto Logout
                      _buildSwitchTile(
                        icon: Icons.timer,
                        title: 'Auto Logout',
                        subtitle: _autoLogout
                            ? 'Logout after $_autoLogoutTime minutes of inactivity'
                            : 'Auto logout after inactivity',
                        value: _autoLogout,
                        onChanged: (value) {
                          _debounceAction(() {
                            setState(() {
                              _autoLogout = value;
                              _markChanged();
                            });
                          });
                        },
                      ),
                      
                      if (_autoLogout)
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.timer_outlined, color: Colors.blue),
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
                                _debounceAction(() {
                                  if (value != null) {
                                    setState(() {
                                      _autoLogoutTime = value;
                                      _markChanged();
                                    });
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      
                      // Security Info
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.security, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Security settings help protect your financial data. '
                                'Enable PIN or fingerprint for extra security.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade200,
          width: value ? 2 : 1,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: value ? AppTheme.primaryColor : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
