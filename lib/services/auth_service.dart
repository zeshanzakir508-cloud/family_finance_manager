// lib/services/auth_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  User? _user;
  bool _isFingerprintEnabled = false;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
    _loadFingerprintSetting();
  }

  Future<void> _loadFingerprintSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
  }

  User? get currentUser => _user;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // ✅ ADDED: Change Password with re-authentication
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      print('✅ Password changed successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase error changing password: ${e.code}');
      
      // Handle specific errors
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Please login again before changing password');
      } else if (e.code == 'weak-password') {
        throw Exception('Password should be at least 6 characters');
      } else {
        throw Exception(_getErrorMessage(e));
      }
    } catch (e) {
      print('❌ Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }

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
      return false;
    }
  }

  Future<bool> isFingerprintAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fingerprint_enabled', enabled);
    _isFingerprintEnabled = enabled;
    notifyListeners();
  }

  bool get isFingerprintEnabled => _isFingerprintEnabled;

  // ✅ ADDED: Get current user email
  String? getCurrentUserEmail() {
    return _user?.email;
  }

  // ✅ ADDED: Check if user is logged in
  bool isLoggedIn() {
    return _user != null;
  }

  // ✅ ADDED: Re-authenticate user
  Future<bool> reauthenticateUser(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('❌ Re-authentication failed: $e');
      return false;
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please login again before changing password.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
