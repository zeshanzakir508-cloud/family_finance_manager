// lib/services/biometric_service.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isFingerprintEnabled = false;
  bool _isAvailable = false;

  BiometricService() {
    _loadFingerprintSetting();
    _checkAvailability();
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  bool get isFingerprintEnabled => _isFingerprintEnabled;
  bool get isAvailable => _isAvailable;

  // ============================================================
  // BIOMETRIC METHODS
  // ============================================================

  Future<bool> authenticateWithFingerprint() async {
    if (!_isFingerprintEnabled) return false;

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access FinFam',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } catch (e) {
      print('❌ Biometric authentication error: $e');
      return false;
    }
  }

  Future<bool> checkAvailability() async {
    try {
      _isAvailable = await _localAuth.canCheckBiometrics;
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    if (enabled && !_isAvailable) {
      throw Exception('Biometric authentication is not available on this device');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fingerprint_enabled', enabled);
    _isFingerprintEnabled = enabled;
    notifyListeners();
  }

  Future<bool> isFingerprintAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<void> _loadFingerprintSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
    notifyListeners();
  }

  Future<void> _checkAvailability() async {
    _isAvailable = await _localAuth.canCheckBiometrics;
    notifyListeners();
  }

  // Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Check if device supports fingerprint specifically
  Future<bool> isFingerprintSupported() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      return types.contains(BiometricType.fingerprint);
    } catch (e) {
      return false;
    }
  }
}
