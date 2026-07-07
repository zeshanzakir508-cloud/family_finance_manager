// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'dart:math';

class Helpers {
  // ============================================================
  // ID GENERATION
  // ============================================================

  static String generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(20, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  static String generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatDateWithTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  static String getShortMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  static String getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  static String timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  // ============================================================
  // TEXT FORMATTING
  // ============================================================

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[0-9+\- ]{10,15}$').hasMatch(phone);
  }

  static bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidAmount(String amount) {
    return RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(amount);
  }

  // ============================================================
  // MISC
  // ============================================================

  static T? enumFromString<T>(Iterable<T> values, String? value) {
    if (value == null) return null;
    try {
      return values.firstWhere((v) => v.toString().split('.').last == value);
    } catch (_) {
      return null;
    }
  }

  static String enumToString<T>(T value) {
    return value.toString().split('.').last;
  }

  static List<T> distinctList<T>(List<T> list) {
    return list.toSet().toList();
  }

  static bool isNullOrEmpty(String? text) {
    return text == null || text.isEmpty;
  }
}
