// lib/services/biometric_service.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      print('🔐 Biometric - Available: $isAvailable, Device Supported: $isDeviceSupported');
      
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('❌ Biometric - Error checking availability: $e');
      return false;
    }
  }

  static Future<bool> authenticate({
    required String reason,
    String? title,
    String? message,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) {
        print('❌ Biometric - Not available on this device');
        return false;
      }

      print('🔐 Biometric - Authenticating with reason: $reason');
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );
      
      print('🔐 Biometric - Authentication result: $authenticated');
      return authenticated;
    } on Exception catch (e) {
      print('❌ Biometric - Authentication error: $e');
      return false;
    } catch (e) {
      print('❌ Biometric - Unexpected error: $e');
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
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('🔐 Biometric - Available types: $biometrics');
      return biometrics;
    } catch (e) {
      print('❌ Biometric - Error getting types: $e');
      return [];
    }
  }

  static Future<bool> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      return true;
    } catch (e) {
      print('❌ Biometric - Error stopping: $e');
      return false;
    }
  }
}
