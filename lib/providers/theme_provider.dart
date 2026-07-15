// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ FIXED: Use ThemeConfig instead of AppTheme
import '../config/theme_config.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;
  final SharedPreferences _prefs;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  ThemeMode get themeMode => _themeMode;
  bool get useSystemTheme => _useSystemTheme;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // ============================================================
  // LOAD & SAVE
  // ============================================================

  void _loadTheme() {
    final savedMode = _prefs.getString(_themeKey);
    if (savedMode == null) {
      _themeMode = ThemeMode.system;
      _useSystemTheme = true;
    } else {
      switch (savedMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          _useSystemTheme = false;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          _useSystemTheme = false;
          break;
        default:
          _themeMode = ThemeMode.system;
          _useSystemTheme = true;
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    String? value;
    if (_useSystemTheme) {
      value = 'system';
    } else {
      value = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    }
    await _prefs.setString(_themeKey, value);
  }

  // ============================================================
  // SET THEME
  // ============================================================

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode && !_useSystemTheme) return;
    
    _themeMode = mode;
    _useSystemTheme = false;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> setSystemTheme() async {
    _useSystemTheme = true;
    _themeMode = ThemeMode.system;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_useSystemTheme) {
      final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      _useSystemTheme = false;
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    } else {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    await _saveTheme();
    notifyListeners();
  }

  // ============================================================
  // GET THEME DATA
  // ============================================================

  ThemeData get currentTheme {
    if (_themeMode == ThemeMode.system) {
      final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      // ✅ FIXED: Use ThemeConfig
      return isDark ? ThemeConfig.darkTheme : ThemeConfig.lightTheme;
    }
    // ✅ FIXED: Use ThemeConfig
    return _themeMode == ThemeMode.dark ? ThemeConfig.darkTheme : ThemeConfig.lightTheme;
  }

  bool isDarkModeWithContext(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String getThemeLabel() {
    if (_useSystemTheme) return 'System';
    return _themeMode == ThemeMode.dark ? 'Dark' : 'Light';
  }

  IconData getThemeIcon() {
    if (_useSystemTheme) return Icons.settings_overscan;
    return _themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode;
  }

  bool get isUsingSystemTheme => _useSystemTheme;
}
