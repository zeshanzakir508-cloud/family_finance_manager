// lib/services/auth_service.dart
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
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
