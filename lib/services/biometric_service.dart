// lib/services/biometric_service.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate({
    required String reason,  // <-- ADDED THIS REQUIRED PARAMETER
    String? title,
    String? message,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics({
    required String reason,
    String? title,
    String? message,
  }) async {
    return authenticate(
      reason: reason,
      title: title,
      message: message,
    );
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      return true;
    } catch (e) {
      return false;
    }
  }
}
