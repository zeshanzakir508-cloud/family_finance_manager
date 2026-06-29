import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static bool _isLoaded = false;

  static Future<void> init() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults({
        'owner_email': 'zeshanzakir508@gmail.com',
        'moderator_emails': 'mrszeshanzakir508@gmail.com',
        'max_families_created': '3',
        'max_families_joined': '3',
        'max_members_per_family': '10',
        'enable_fingerprint': 'true',
        'enable_transfer': 'true',
        'enable_recurring': 'true',
        'app_name': 'FinFam',
        'app_subtitle': 'Family Finance Manager',
        'primary_color': '#1A73E8',
        'secondary_color': '#00897B',
        'default_currency': 'USD',
        'default_language': 'en',
        // Custom Messages
        'show_message': 'false',
        'message_title': '',
        'message_body': '',
        'message_icon': '🎉',
        'message_type': 'success',
        'message_expiry': '',
        'message_button_text': 'OK',
      });

      await _remoteConfig.fetchAndActivate();
      _isLoaded = true;
      print('✅ Remote Config loaded');
    } catch (e) {
      print('⚠️ Remote Config error: $e');
      _isLoaded = true;
    }
  }

  static String getString(String key) => _remoteConfig.getString(key);
  static int getInt(String key) => _remoteConfig.getInt(key);
  static bool getBool(String key) => _remoteConfig.getBool(key);

  // Owner
  static String get ownerEmail => getString('owner_email');
  static bool isOwner(String? email) => email == ownerEmail;

  // Moderator
  static List<String> get moderatorEmails => 
      getString('moderator_emails').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  
  static bool isModerator(String? email) {
    if (email == null) return false;
    return moderatorEmails.contains(email);
  }

  static bool hasAdminAccess(String? email) => isOwner(email) || isModerator(email);

  // Limits
  static int get maxFamiliesCreated => getInt('max_families_created');
  static int get maxFamiliesJoined => getInt('max_families_joined');
  static int get maxMembersPerFamily => getInt('max_members_per_family');
  
  static bool canCreateFamily(int count) => count < maxFamiliesCreated;
  static bool canJoinFamily(int count) => count < maxFamiliesJoined;
  static bool canAddMember(int count) => count < maxMembersPerFamily;

  // Features
  static bool get enableFingerprint => getBool('enable_fingerprint');
  static bool get enableTransfer => getBool('enable_transfer');
  static bool get enableRecurring => getBool('enable_recurring');

  // UI
  static String get appName => getString('app_name');
  static String get appSubtitle => getString('app_subtitle');
  static String get primaryColor => getString('primary_color');
  static String get secondaryColor => getString('secondary_color');

  // Defaults
  static String get defaultCurrency => getString('default_currency');
  static String get defaultLanguage => getString('default_language');

  // Custom Messages
  static bool get showMessage => getBool('show_message');
  static String get messageTitle => getString('message_title');
  static String get messageBody => getString('message_body');
  static String get messageIcon => getString('message_icon');
  static String get messageType => getString('message_type');
  static String get messageExpiry => getString('message_expiry');
  static String get messageButtonText => getString('message_button_text');

  static bool get isMessageValid {
    if (!showMessage) return false;
    final expiry = messageExpiry;
    if (expiry.isEmpty) return true;
    try {
      final expiryDate = DateTime.parse(expiry);
      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
      return true;
    }
  }

  static Color getMessageColor(String type) {
    switch (type) {
      case 'success': return Colors.green;
      case 'info': return Colors.blue;
      case 'warning': return Colors.orange;
      case 'celebration': return Colors.amber;
      case 'event': return Colors.purple;
      default: return Colors.blue;
    }
  }

  static String getMessageIconByType(String type) {
    switch (type) {
      case 'success': return '🎉';
      case 'info': return '💡';
      case 'warning': return '⚠️';
      case 'celebration': return '🎊';
      case 'event': return '🎪';
      default: return '📢';
    }
  }

  static Future<void> refresh() async {
    await _remoteConfig.fetchAndActivate();
    print('✅ Remote Config refreshed');
  }
}
