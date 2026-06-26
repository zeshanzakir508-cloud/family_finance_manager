import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isInitialized = false;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialized = true;
      notifyListeners();
    });
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _user;

  // Get user ID
  String? get userId => _user?.uid;

  // Get user email
  String? get userEmail => _user?.email;

  // Check if user is authenticated
  bool get isAuthenticated => _user != null;

  // Check if auth is initialized
  bool get isInitialized => _isInitialized;

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = result.user;
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = result.user;
      notifyListeners();
      
      // Send email verification
      await result.user?.sendEmailVerification();
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Sign up error: $e');
      return null;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      await _user?.delete();
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _user?.updatePassword(newPassword);
      return true;
    } catch (e) {
      debugPrint('Update password error: $e');
      return false;
    }
  }

  // Update email
  Future<bool> updateEmail(String newEmail) async {
    try {
      await _user?.updateEmail(newEmail.trim());
      return true;
    } catch (e) {
      debugPrint('Update email error: $e');
      return false;
    }
  }

  // Re-authenticate user
  Future<bool> reauthenticate(String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user?.email ?? '',
        password: password,
      );
      await _user?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('Re-authentication error: $e');
      return false;
    }
  }
}
