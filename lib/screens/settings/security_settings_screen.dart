// lib/screens/settings/security_settings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _fingerprintEnabled = false;
  bool _initialFingerprintEnabled = false;
  bool _autoLogout = false;
  bool _initialAutoLogout = false;
  int _autoLogoutTime = 5;
  int _initialAutoLogoutTime = 5;
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
    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _fingerprintEnabled = authService.isFingerprintEnabled;
      _initialFingerprintEnabled = _fingerprintEnabled;
      _autoLogout = prefs.getBool('auto_logout') ?? false;
      _initialAutoLogout = _autoLogout;
      _autoLogoutTime = prefs.getInt('auto_logout_time') ?? 5;
      _initialAutoLogoutTime = _autoLogoutTime;
      _hasChanges = false;
      _isLoading = false;
    });
  }

  void _markChanged() {
    setState(() {
      _hasChanges = _fingerprintEnabled != _initialFingerprintEnabled ||
          _autoLogout != _initialAutoLogout ||
          _autoLogoutTime != _initialAutoLogoutTime;
    });
  }

  Future<void> _saveSettings() async {
    _debounceAction(() async {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_logout', _autoLogout);
      await prefs.setInt('auto_logout_time', _autoLogoutTime);
      
      setState(() {
        _initialFingerprintEnabled = _fingerprintEnabled;
        _initialAutoLogout = _autoLogout;
        _initialAutoLogoutTime = _autoLogoutTime;
        _hasChanges = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings saved successfully'),
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

  Future<void> _testFingerprint() async {
    _debounceAction(() async {
      final available = await BiometricService.isAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint not available on this device'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to test fingerprint',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authenticated 
                  ? 'Fingerprint authentication successful! ✅' 
                  : 'Fingerprint authentication failed ❌',
            ),
            backgroundColor: authenticated ? Colors.green : Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _enableFingerprintForLogin() async {
    final available = await BiometricService.isAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final authenticated = await BiometricService.authenticate(
      reason: 'Enable fingerprint login',
    );
    
    if (authenticated) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.setFingerprintEnabled(true);
      
      setState(() {
        _fingerprintEnabled = true;
        _markChanged();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint login enabled! 🔐'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint authentication failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disableFingerprintForLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.setFingerprintEnabled(false);
    
    setState(() {
      _fingerprintEnabled = false;
      _markChanged();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fingerprint login disabled'),
          backgroundColor: Colors.orange,
        ),
      );
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
                      FutureBuilder<bool>(
                        future: BiometricService.isAvailable(),
                        builder: (context, snapshot) {
                          final available = snapshot.data ?? false;
                          return _buildSwitchTile(
                            icon: Icons.fingerprint,
                            title: 'Fingerprint Login',
                            subtitle: available
                                ? _fingerprintEnabled
                                    ? 'Fingerprint login enabled ✓'
                                    : 'Enable fingerprint to unlock'
                                : 'Fingerprint not available on this device',
                            value: _fingerprintEnabled && available,
                            onChanged: available ? (value) {
                              _debounceAction(() {
                                if (value) {
                                  _enableFingerprintForLogin();
                                } else {
                                  _disableFingerprintForLogin();
                                }
                              });
                            } : null,
                          );
                        },
                      ),
                      
                      const Divider(height: 24),
                      
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
                                'Enable fingerprint for quick and secure login.',
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
