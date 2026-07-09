// lib/services/auth_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isInitialized = false; // ✅ ADDED

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        print('✅ User logged in: ${user.uid}');
        await fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
        print('⚠️ User logged out');
      }
      _isInitialized = true; // ✅ ADDED
      notifyListeners();
    });
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  User? get currentUser => _user;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get hasProfile => _userProfile != null;
  bool get isInitialized => _isInitialized; // ✅ ADDED

  // ============================================================
  // PROFILE MANAGEMENT
  // ============================================================

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Fetching profile for user: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        _userProfile = doc.data();
        print('✅ Profile loaded successfully!');
        print('📋 Role: ${_userProfile?['role']}');
        print('📋 Username: ${_userProfile?['username']}');
      } else {
        print('⚠️ No profile found for user: $uid');
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

  Future<void> refreshProfile() async {
    if (_user != null) {
      await fetchUserProfile(_user!.uid);
    }
  }

  String? getCachedUserRole() {
    return _userProfile?['role'] as String?;
  }

  String? getCachedUsername() {
    return _userProfile?['username'] as String?;
  }

  bool get isCachedOwner => _userProfile?['role'] == 'owner';
  bool get isCachedModerator => _userProfile?['role'] == 'moderator';

  // ✅ ADDED: Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print('❌ Error checking email verification: $e');
      return false;
    }
  }

  // ✅ ADDED: Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      await user.sendEmailVerification();
      print('✅ Verification email resent to: ${user.email}');
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // ============================================================
  // AUTHENTICATION METHODS
  // ============================================================

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔐 Signing in: $email');
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ User signed in: ${result.user?.uid}');
      
      // ✅ ADDED: Check email verification
      if (result.user != null) {
        await result.user!.reload();
        if (!result.user!.emailVerified) {
          print('⚠️ Email not verified for: $email');
          // Still logged in, but flag for UI
        } else {
          print('✅ Email verified: $email');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _getErrorMessage(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Login error: $e');
      throw Exception('An error occurred. Please try again.');
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      // ✅ FIXED: Check username availability
      try {
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
        
        if (usernameQuery.docs.isNotEmpty) {
          throw Exception('Username already taken. Please choose another.');
        }
      } catch (e) {
        print('⚠️ Error checking username: $e');
        // Continue with signup
      }

      print('🔐 Signing up: $email');
      
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await result.user?.updateDisplayName(name);
      
      // ✅ FIXED: Create profile with all data
      if (result.user != null) {
        await _createProfileWithUsername(result.user!.uid, email, name, username);
      }
      
      // ✅ ADDED: Send verification email
      if (result.user != null) {
        await result.user!.sendEmailVerification();
        print('✅ Verification email sent to: $email');
      }
      
      print('✅ User signed up: ${result.user?.uid}');
      
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _getErrorMessage(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Signup error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
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
      print('🔐 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
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
      case 'email-not-verified':
        return 'Please verify your email before logging in. Check your inbox.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
