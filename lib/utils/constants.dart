// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'FinFam';
  static const String appVersion = '2.0.0';
  static const String appSubtitle = 'Family Finance Manager';
  static const String appYear = '2026';

  // SharedPreferences Keys
  static const String prefThemeKey = 'theme_mode';
  static const String prefCurrencyKey = 'selected_currency';
  static const String prefLanguageKey = 'selected_language';
  static const String prefFingerprintKey = 'fingerprint_enabled';
  static const String prefOnboardingKey = 'onboarding_complete';
  static const String prefModeKey = 'mode_selected';
  static const String prefUserIdKey = 'user_id';
  static const String prefFamilyIdKey = 'family_id';

  // Collections
  static const String collectionUsers = 'users';
  static const String collectionFamilies = 'families';
  static const String collectionTransactions = 'transactions';
  static const String collectionBudgets = 'budgets';
  static const String collectionGoals = 'goals';
  static const String collectionCategories = 'categories';
  static const String collectionNotifications = 'notifications';
  static const String collectionBackups = 'backups';
  static const String collectionTransfers = 'transfers';
  static const String collectionReports = 'reports';
  static const String collectionMessages = 'messages';

  // Limits
  static const int maxFamilyMembers = 10;
  static const int maxFamiliesPerUser = 3;
  static const int minPasswordLength = 6;
  static const int maxTransactionDescriptionLength = 100;
  static const int maxCategoryNameLength = 30;
  static const int maxGoalNameLength = 50;

  // Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration snackBarLongDuration = Duration(seconds: 5);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Animation
  static const double defaultRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;
  static const double defaultIconSize = 24.0;
  static const double defaultAvatarSize = 48.0;

  // Messages
  static const String errorDefault = 'An error occurred. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String successSaved = 'Saved successfully!';
  static const String successDeleted = 'Deleted successfully!';
  static const String successUpdated = 'Updated successfully!';
  static const String emptyMessage = 'No data available.';
}
