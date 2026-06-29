import '../services/remote_config_service.dart';

class AppConfig {
  // ============================================================
  // 🧪 TEST MODE - Set to false before release
  // ============================================================
  
  static const bool isTestMode = false;

  // ============================================================
  // 👑 OWNER & MODERATOR SETTINGS
  // ============================================================
  
  static const String ownerEmail = 'zeshanzakir508@gmail.com';
  static const List<String> moderatorEmails = [
    'mrszeshanzakir508@gmail.com',
    // Add more moderators here as needed
    // 'sister@gmail.com',
    // 'brother@gmail.com',
  ];

  static bool isOwner(String? email) {
    if (email == null) return false;
    return email == ownerEmail;
  }

  static bool isModerator(String? email) {
    if (email == null) return false;
    return moderatorEmails.contains(email);
  }

  static bool hasAdminAccess(String? email) {
    return isOwner(email) || isModerator(email);
  }

  // ============================================================
  // 👨‍👩‍👦 FAMILY LIMITS
  // ============================================================
  
  static const int maxFamiliesCreated = 3;
  static const int maxFamiliesJoined = 3;
  static const int maxMembersPerFamily = 10;

  static bool canCreateFamily(int currentCount) {
    return currentCount < maxFamiliesCreated;
  }

  static bool canJoinFamily(int currentCount) {
    return currentCount < maxFamiliesJoined;
  }

  static bool canAddMember(int currentCount) {
    return currentCount < maxMembersPerFamily;
  }

  // ============================================================
  // 🎨 APP CUSTOMIZATION
  // ============================================================
  
  static const String appName = 'FinFam';
  static const String appSubtitle = 'Family Finance Manager';
  static const int primaryColor = 0xFF1A73E8;
  static const int secondaryColor = 0xFF00897B;

  // ============================================================
  // 🔧 FEATURE TOGGLES (Remote Config Overrides)
  // ============================================================
  
  static bool get enableFingerprint => RemoteConfigService.enableFingerprint;
  static bool get enableTransfer => RemoteConfigService.enableTransfer;
  static bool get enableRecurring => RemoteConfigService.enableRecurring;

  // ============================================================
  // 📊 DEFAULT VALUES
  // ============================================================
  
  static const String defaultCurrency = 'USD';
  static const String defaultLanguage = 'en';

  // ============================================================
  // 💎 PREMIUM PLANS - Free vs Premium Features
  // ============================================================
  
  static const List<String> freeFeatures = [
    '1 Family',
    '3 Members per Family',
    '50 Transactions/month',
    'Basic Reports',
    '50 MB Storage',
  ];

  static const List<String> premium1Features = [
    '3 Families',
    '5 Members per Family',
    'Unlimited Transactions',
    'Advanced Reports',
    '200 MB Storage',
    'Export CSV',
    'Fingerprint Login',
  ];

  static const List<String> premium2Features = [
    '10 Families',
    '10 Members per Family',
    'Unlimited Transactions',
    'Advanced Reports + Charts',
    '500 MB Storage',
    'Export CSV/PDF',
    'Fingerprint Login',
    'PIN Lock',
    'Auto Backup',
  ];

  static const List<String> premium3Features = [
    '20 Families',
    '20 Members per Family',
    'Unlimited Transactions',
    'All Features',
    '1 GB Storage',
    'Export CSV/PDF',
    'Fingerprint Login',
    'PIN Lock',
    'Auto Backup',
    'Tax Reports',
    'Bulk Import',
    '24/7 Support',
  ];

  // ============================================================
  // 👤 USER ROLES
  // ============================================================
  
  static bool isOwnerUser(String? email) => isOwner(email);
  static bool isModeratorUser(String? email) => isModerator(email);
  static bool isAdminUser(String? email) => hasAdminAccess(email);

  // ============================================================
  // 🚀 HELPER METHODS
  // ============================================================
  
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'PKR': return 'Rs';
      case 'INR': return '₹';
      case 'AED': return 'د.إ';
      case 'SAR': return '﷼';
      case 'CAD': return 'C\$';
      case 'AUD': return 'A\$';
      case 'JPY': return '¥';
      default: return '\$';
    }
  }

  // ============================================================
  // 📱 TEST MODE HELPERS
  // ============================================================
  
  static bool get isTestEnvironment => isTestMode;
  
  static void log(String message) {
    if (isTestMode) {
      print('🔍 [TEST] $message');
    }
  }
}
