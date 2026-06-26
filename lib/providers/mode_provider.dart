import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModeProvider extends ChangeNotifier {
  String _currentMode = 'personal'; // 'personal' or 'family'
  bool _rememberChoice = false;

  ModeProvider() {
    _loadSavedMode();
  }

  String get currentMode => _currentMode;
  bool get rememberChoice => _rememberChoice;

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberChoice = prefs.getBool('remember_mode') ?? false;
    if (_rememberChoice) {
      _currentMode = prefs.getString('selected_mode') ?? 'personal';
    }
    notifyListeners();
  }

  Future<void> setMode(String mode, {bool remember = false}) async {
    _currentMode = mode;
    _rememberChoice = remember;
    
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString('selected_mode', mode);
      await prefs.setBool('remember_mode', true);
    } else {
      await prefs.remove('selected_mode');
      await prefs.setBool('remember_mode', false);
    }
    
    notifyListeners();
  }

  Future<void> toggleMode() async {
    final newMode = _currentMode == 'personal' ? 'family' : 'personal';
    await setMode(newMode, remember: _rememberChoice);
  }

  bool get isPersonalMode => _currentMode == 'personal';
  bool get isFamilyMode => _currentMode == 'family';
}
