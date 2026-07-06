// lib/services/auth_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isFingerprintEnabled = false;
  bool _isLoading = false;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        print('✅ User logged in: ${user.uid}');
        // ✅ CRITICAL: Auto-fetch profile on login
        await fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
        print('⚠️ User logged out');
      }
      notifyListeners();
    });
    _loadFingerprintSetting();
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  User? get currentUser => _user;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isFingerprintEnabled => _isFingerprintEnabled;
  bool get isLoggedIn => _user != null;
  bool get hasProfile => _userProfile != null;

  // ============================================================
  // ✅ PROFILE MANAGEMENT (FIXED)
  // ============================================================

  /// ✅ Fetch user profile from Firestore
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Fetching profile for user: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        _userProfile = doc.data();
        print('✅ Profile loaded successfully!');
        print('   👤 Name: ${_userProfile?['displayName'] ?? 'No name'}');
        print('   📧 Email: ${_userProfile?['email'] ?? 'No email'}');
        print('   👑 Role: ${_userProfile?['role'] ?? 'No role'}');
        print('   🔑 Username: ${_userProfile?['username'] ?? 'No username'}');
      } else {
        print('⚠️ No profile found for user: $uid');
        // ✅ Auto-create profile if missing
        await _createDefaultProfile(uid);
      }

      _isLoading = false;
      notifyListeners();
      return _userProfile;
    } catch (e) {
      _isLoading = false;
      print('❌ Error fetching profile: $e');
      notifyListeners();
      return null;
    }
  }

  /// ✅ Auto-create default profile if missing
  Future<void> _createDefaultProfile(String uid) async {
    try {
      print('🔄 Creating default profile for: $uid');
      
      final email = _user?.email ?? '';
      final name = _user?.displayName ?? email.split('@').first;

      final profileData = {
        'uid': uid,
        'email': email,
        'displayName': name,
        'username': email.split('@').first,
        'role': 'member',
        'familyId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'photoUrl': _user?.photoURL ?? '',
        'settings': {
          'currency': 'USD',
          'theme': 'system',
          'notifications': true,
        },
      };

      await _firestore.collection('users').doc(uid).set(profileData);
      _userProfile = profileData;
      print('✅ Default profile created for: $uid');
    } catch (e) {
      print('❌ Error creating default profile: $e');
    }
  }

  /// ✅ Refresh profile (call after updates)
  Future<void> refreshProfile() async {
    if (_user != null) {
      await fetchUserProfile(_user!.uid);
    }
  }

  /// ✅ Get user role from cache
  String? getCachedUserRole() {
    return _userProfile?['role'] as String?;
  }

  /// ✅ Get username from cache
  String? getCachedUsername() {
    return _userProfile?['username'] as String?;
  }

  /// ✅ Check if cached user is Owner
  bool get isCachedOwner => _userProfile?['role'] == 'owner';
  
  /// ✅ Check if cached user is Moderator
  bool get isCachedModerator => _userProfile?['role'] == 'moderator';

  // ============================================================
  // AUTHENTICATION METHODS
  // ============================================================

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // ✅ Profile auto-fetched via authStateChanges listener
      print('✅ User signed in: ${result.user?.uid}');
      
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _getErrorMessage(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('An error occurred. Please try again.');
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      // ✅ Check if username already exists
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username already taken. Please choose another.');
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await result.user?.updateDisplayName(name);
      
      if (result.user != null) {
        await _createProfileWithUsername(result.user!.uid, email, name, username);
      }
      
      print('✅ User signed up: ${result.user?.uid}');
      
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _getErrorMessage(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('An error occurred. Please try again.');
    }
  }

  Future<void> _createProfileWithUsername(String uid, String email, String name, String username) async {
    try {
      final profileData = {
        'uid': uid,
        'email': email,
        'displayName': name,
        'username': username,
        'role': 'member',
        'familyId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'photoUrl': '',
        'settings': {
          'currency': 'USD',
          'theme': 'system',
          'notifications': true,
        },
      };

      await _firestore.collection('users').doc(uid).set(profileData);
      _userProfile = profileData;
      print('✅ Profile created with username: $username');
    } catch (e) {
      print('❌ Error creating profile: $e');
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.signOut();
      _userProfile = null;
      
      _isLoading = false;
      notifyListeners();
      print('✅ User signed out');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Error signing out: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      await user.updatePassword(newPassword);
      
      print('✅ Password changed successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase error changing password: ${e.code}');
      
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

  // ============================================================
  // BIOMETRIC / FINGERPRINT
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

  // ============================================================
  // HELPERS
  // ============================================================

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
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _loadFingerprintSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
  }
}
