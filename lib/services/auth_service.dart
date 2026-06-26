import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _user;

  String? get userId => _user?.uid;

  String? get userEmail => _user?.email;

  bool get isAuthenticated => _user != null;

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

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = result.user;
      notifyListeners();
      
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

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

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
}
