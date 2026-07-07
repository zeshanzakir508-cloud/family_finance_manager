// lib/utils/validators.dart
import 'package:flutter/material.dart';

class Validators {
  // ============================================================
  // REQUIRED
  // ============================================================

  static String? Function(String?)? required(String field) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$field is required';
      }
      return null;
    };
  }

  // ============================================================
  // EMAIL
  // ============================================================

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ============================================================
  // PASSWORD
  // ============================================================

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ============================================================
  // USERNAME
  // ============================================================

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Username must be 3-20 characters (letters, numbers, underscore)';
    }
    return null;
  }

  // ============================================================
  // PHONE
  // ============================================================

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9+\- ]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number (10-15 digits)';
    }
    return null;
  }

  // ============================================================
  // AMOUNT
  // ============================================================

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amountRegex = RegExp(r'^[0-9]+(\.[0-9]{1,2})?$');
    if (!amountRegex.hasMatch(value.trim())) {
      return 'Please enter a valid amount (e.g., 100 or 100.50)';
    }
    final doubleValue = double.tryParse(value.trim());
    if (doubleValue == null || doubleValue <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  // ============================================================
  // NUMBER
  // ============================================================

  static String? number(String? value, {double min = 0, String? field}) {
    if (value == null || value.trim().isEmpty) {
      return '${field ?? 'Value'} is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < min) {
      return 'Value must be at least $min';
    }
    return null;
  }

  // ============================================================
  // SELECTION
  // ============================================================

  static String? selected(String? value, {String field = 'Selection'}) {
    if (value == null || value.isEmpty) {
      return 'Please select a $field';
    }
    return null;
  }

  // ============================================================
  // DATE
  // ============================================================

  static String? date(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    return null;
  }

  // ✅ FIXED: Added proper return type
  static String? dateRange(DateTimeRange? value) {
    if (value == null) {
      return 'Date range is required';
    }
    return null;
  }

  // ============================================================
  // TEXT LENGTH
  // ============================================================

  static String? maxLength(String? value, int maxLength, {String field = 'Text'}) {
    if (value == null) return null;
    if (value.length > maxLength) {
      return '$field cannot exceed $maxLength characters';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, {String field = 'Text'}) {
    if (value == null || value.isEmpty) {
      return '$field is required';
    }
    if (value.length < minLength) {
      return '$field must be at least $minLength characters';
    }
    return null;
  }

  // ============================================================
  // URL
  // ============================================================

  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    final urlRegex = RegExp(r'^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$');
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // ============================================================
  // COMBINED
  // ============================================================

  static String? requiredEmail(String? value) {
    final requiredError = required('Email')!(value);
    if (requiredError != null) return requiredError;
    return email(value);
  }

  static String? requiredPassword(String? value) {
    final requiredError = required('Password')!(value);
    if (requiredError != null) return requiredError;
    return password(value);
  }

  static String? requiredUsername(String? value) {
    final requiredError = required('Username')!(value);
    if (requiredError != null) return requiredError;
    return username(value);
  }
}
