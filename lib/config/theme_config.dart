// lib/config/theme_config.dart
import 'package:flutter/material.dart';

class ThemeConfig {
  // ============================================================
  // COLOR PALETTE
  // ============================================================
  
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color accentColor = Color(0xFF10B981);
  
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightDivider = Color(0xFFE2E8F0);
  
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF334155);
  
  // ============================================================
  // TEXT STYLES
  // ============================================================
  
  static const String fontFamily = 'Poppins';
  static const String fontFamilyAlt = 'Inter';
  
  // ============================================================
  // THEME DATA
  // ============================================================
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightCard,
      background: lightBackground,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightText,
      onBackground: lightText,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCard,
    dividerColor: lightDivider,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightCard,
      foregroundColor: lightText,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: lightText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: lightTextSecondary),
      hintStyle: TextStyle(color: lightTextSecondary.withOpacity(0.6)),
    ),
    cardTheme: CardTheme(
      color: lightCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightCard,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightTextSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(
      color: lightDivider,
      thickness: 1,
    ),
    iconTheme: IconThemeData(
      color: lightText,
      size: 24,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightText),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightText),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightText),
      headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lightText),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightText),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lightText),
      bodyLarge: TextStyle(fontSize: 16, color: lightText),
      bodyMedium: TextStyle(fontSize: 14, color: lightText),
      bodySmall: TextStyle(fontSize: 12, color: lightTextSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightText),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lightTextSecondary),
      labelSmall: TextStyle(fontSize: 10, color: lightTextSecondary),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryLight,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      secondary: secondaryColor,
      surface: darkCard,
      background: darkBackground,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkText,
      onBackground: darkText,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dividerColor: darkDivider,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCard,
      foregroundColor: darkText,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: darkText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: const BorderSide(color: primaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: darkTextSecondary),
      hintStyle: TextStyle(color: darkTextSecondary.withOpacity(0.6)),
    ),
    cardTheme: CardTheme(
      color: darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: primaryLight,
      unselectedItemColor: darkTextSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(
      color: darkDivider,
      thickness: 1,
    ),
    iconTheme: IconThemeData(
      color: darkText,
      size: 24,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkText),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkText),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
      headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
      bodyLarge: TextStyle(fontSize: 16, color: darkText),
      bodyMedium: TextStyle(fontSize: 14, color: darkText),
      bodySmall: TextStyle(fontSize: 12, color: darkTextSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecondary),
      labelSmall: TextStyle(fontSize: 10, color: darkTextSecondary),
    ),
  );
}
