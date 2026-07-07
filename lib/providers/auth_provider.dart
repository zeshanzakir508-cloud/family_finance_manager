// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider() {
    _authService.addListener(_onAuthChanged);
    _loadUser();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOwner => _user?.role == 'owner';
  bool get isModerator => _user?.role == 'moderator';
  bool get isAdmin => isOwner || isModerator;
  String get userId => _user?.id ?? '';
  String get userEmail => _user?.email ?? '';
  String get userName => _user?.displayName ?? 'User';
  String get userCurrency => _user?.currency ?? 'USD';

  // ============================================================
  // AUTH METHODS
  // ============================================================

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmail(email, password);
      await _loadUser();
      _isAuthenticated = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signup(String email, String password, String name, String username) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmail(email, password, name, username);
      await _loadUser();
      _isAuthenticated = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    await _loadUser();
  }

  // ============================================================
  // BIOMETRIC METHODS
  // ============================================================

  Future<bool> authenticateWithBiometric() async {
    return await _biometricService.authenticateWithFingerprint();
  }

  Future<bool> isBiometricAvailable() async {
    return await _biometricService.checkAvailability();
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    await _biometricService.setFingerprintEnabled(enabled);
    notifyListeners();
  }

  bool get isFingerprintEnabled => _biometricService.isFingerprintEnabled;

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    try {
      final profile = _authService.userProfile;
      if (profile != null) {
        _user = UserModel.fromJson(profile);
        _isAuthenticated = true;
      } else {
        _user = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  void _onAuthChanged() {
    if (_authService.currentUser == null) {
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } else {
      _loadUser();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
