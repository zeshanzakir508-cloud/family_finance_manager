// lib/config/app_config.dart
class AppConfig {
  static const String appName = 'FinFam';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Family Finance Manager';
  
  static const String defaultCurrency = 'USD';
  static const String defaultLanguage = 'en';
  
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 20;
  static const int minUsernameLength = 3;
  
  static const int transactionPageSize = 20;
  static const int maxTransactionAttachments = 5;
  
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration otpExpiry = Duration(minutes: 5);
  static const Duration backupInterval = Duration(days: 7);
  
  static const List<String> supportedLanguages = ['en', 'ur', 'ar'];
  
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ur': 'اردو',
    'ar': 'العربية',
  };
  
  static const String emailRegex = r'^[^@]+@[^@]+\.[^@]+$';
  static const String phoneRegex = r'^[0-9+\- ]{10,15}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
  
  static const bool enableDebugLogs = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  static const String supportEmail = 'support@finfam.com';
  static const String privacyPolicyUrl = 'https://finfam.com/privacy';
  static const String termsOfServiceUrl = 'https://finfam.com/terms';
  
  static const String defaultAvatar = 'assets/images/default_avatar.png';
  static const String appLogo = 'assets/images/app_logo.png';
  static const String appIcon = 'assets/images/app_icon.png';
  
  static const int maxRecentTransactions = 50;
  static const int maxCategories = 100;
  static const int maxGoals = 50;
  static const int maxFamilyMembers = 50;
  
  static const String defaultFamilyName = 'My Family';
  static const String defaultBudgetName = 'Monthly Budget';
}
