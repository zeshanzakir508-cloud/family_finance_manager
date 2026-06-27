import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ModeProvider extends ChangeNotifier {
  String _currentMode = 'personal';
  bool _rememberChoice = false;

  ModeProvider() {
    _loadSavedMode();
  }

  String get currentMode => _currentMode;
  bool get rememberChoice => _rememberChoice;

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberChoice = prefs.getBool(Constants.rememberModeKey) ?? false;
    if (_rememberChoice) {
      _currentMode = prefs.getString(Constants.selectedModeKey) ?? 'personal';
    }
    notifyListeners();
  }

  Future<void> setMode(String mode, {bool remember = false}) async {
    _currentMode = mode;
    _rememberChoice = remember;
    
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(Constants.selectedModeKey, mode);
      await prefs.setBool(Constants.rememberModeKey, true);
    } else {
      await prefs.remove(Constants.selectedModeKey);
      await prefs.setBool(Constants.rememberModeKey, false);
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
