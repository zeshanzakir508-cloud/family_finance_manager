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
        // ✅ Auto-fetch profile when user logs in
        await fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
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

  // ============================================================
  // ✅ PROFILE MANAGEMENT (FIXED)
  // ============================================================

  /// Fetch user profile from Firestore
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        _userProfile = doc.data();
        print('✅ Profile loaded for user: $uid');
        print('   Role: ${_userProfile?['role'] ?? 'No role'}');
        print('   Name: ${_userProfile?['name'] ?? 'No name'}');
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
        'name': name,
        'role': 'member', // Default role
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

  /// ✅ Check if profile exists
  Future<bool> profileExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// ✅ Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ✅ Check if user is Owner
  Future<bool> isOwner(String uid) async {
    final role = await getUserRole(uid);
    return role == 'owner';
  }

  /// ✅ Check if user is Moderator
  Future<bool> isModerator(String uid) async {
    final role = await getUserRole(uid);
    return role == 'moderator';
  }

  /// ✅ Check if user is Member
  Future<bool> isMember(String uid) async {
    final role = await getUserRole(uid);
    return role == 'member';
  }

  /// ✅ Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final uid = _user?.uid;
      if (uid == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh profile
      await fetchUserProfile(uid);
      print('✅ Profile updated successfully');
    } catch (e) {
      print('❌ Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }

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
      
      // ✅ Profile will be auto-fetched via authStateChanges listener
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

  Future<void> signUpWithEmail(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await result.user?.updateDisplayName(name);
      
      // ✅ Auto-create profile after signup
      if (result.user != null) {
        await _createDefaultProfile(result.user!.uid);
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

  // ✅ Change Password with re-authentication
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
  // HELPER METHODS
  // ============================================================

  String? getCurrentUserEmail() {
    return _user?.email;
  }

  bool isLoggedIn() {
    return _user != null;
  }

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

  // ✅ Get user role synchronously from cached profile
  String? getCachedUserRole() {
    return _userProfile?['role'] as String?;
  }

  // ✅ Check if cached user is Owner
  bool get isCachedOwner => _userProfile?['role'] == 'owner';
  
  // ✅ Check if cached user is Moderator
  bool get isCachedModerator => _userProfile?['role'] == 'moderator';
  
  // ✅ Check if cached user is Member
  bool get isCachedMember => _userProfile?['role'] == 'member';

  // ============================================================
  // ERROR HANDLING
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
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
