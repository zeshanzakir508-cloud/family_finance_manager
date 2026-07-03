// lib/providers/mode_provider.dart
import 'package:flutter/material.dart';

// Add this enum at the top
enum AppMode { personal, family }

class ModeProvider extends ChangeNotifier {
  AppMode _currentMode = AppMode.personal;

  AppMode get currentMode => _currentMode;

  bool get isPersonalMode => _currentMode == AppMode.personal;
  bool get isFamilyMode => _currentMode == AppMode.family;

  void toggleMode(AppMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  void setMode(String mode) {
    if (mode == 'personal') {
      _currentMode = AppMode.personal;
    } else if (mode == 'family') {
      _currentMode = AppMode.family;
    }
    notifyListeners();
  }
}
