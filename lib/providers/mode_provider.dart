// lib/providers/mode_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ADDED

// Add this enum at the top
enum AppMode { personal, family }

class ModeProvider extends ChangeNotifier {
  AppMode _currentMode = AppMode.personal;
  static const String _modeKey = 'selected_mode'; // ✅ ADDED

  ModeProvider() {
    _loadMode(); // ✅ ADDED: Load saved mode on startup
  }

  AppMode get currentMode => _currentMode;

  bool get isPersonalMode => _currentMode == AppMode.personal;
  bool get isFamilyMode => _currentMode == AppMode.family;

  // ✅ ADDED: Load mode from SharedPreferences
  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_modeKey);
      if (savedMode == 'family') {
        _currentMode = AppMode.family;
      } else {
        _currentMode = AppMode.personal;
      }
      print('✅ Mode loaded: ${_currentMode == AppMode.personal ? "Personal" : "Family"}');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading mode: $e');
    }
  }

  void toggleMode(AppMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      _saveMode(); // ✅ ADDED: Save when changed
      notifyListeners();
    }
  }

  void setMode(String mode) {
    if (mode == 'personal') {
      _currentMode = AppMode.personal;
    } else if (mode == 'family') {
      _currentMode = AppMode.family;
    }
    _saveMode(); // ✅ ADDED: Save when changed
    print('✅ Mode set: ${_currentMode == AppMode.personal ? "Personal" : "Family"}');
    notifyListeners();
  }

  // ✅ ADDED: Save mode to SharedPreferences
  Future<void> _saveMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeValue = _currentMode == AppMode.personal ? 'personal' : 'family';
      await prefs.setString(_modeKey, modeValue);
      print('✅ Mode saved: $modeValue');
    } catch (e) {
      print('❌ Error saving mode: $e');
    }
  }

  // ✅ ADDED: Get current mode as string
  String get modeString => _currentMode == AppMode.personal ? 'personal' : 'family';

  // ✅ ADDED: Reset to default
  void resetMode() {
    _currentMode = AppMode.personal;
    _saveMode();
    notifyListeners();
  }
}
