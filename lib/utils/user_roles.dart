// lib/utils/user_roles.dart
import 'package:flutter/material.dart';

class UserRoles {
  // ============================================================
  // FIXED ROLES
  // ============================================================

  static const String ownerEmail = 'zeshanzakir508@gmail.com';
  static const String moderatorEmail = 'mrszeshanzakir508@gmail.com';

  // ============================================================
  // ROLE CHECKS
  // ============================================================

  static bool isOwner(String? email) {
    if (email == null) return false;
    return email.toLowerCase() == ownerEmail.toLowerCase();
  }

  static bool isModerator(String? email) {
    if (email == null) return false;
    return email.toLowerCase() == moderatorEmail.toLowerCase();
  }

  static bool isAdmin(String? email) {
    return isOwner(email) || isModerator(email);
  }

  static bool isOwnerByEmail(String email) {
    return email.toLowerCase() == ownerEmail.toLowerCase();
  }

  static bool isModeratorByEmail(String email) {
    return email.toLowerCase() == moderatorEmail.toLowerCase();
  }

  static bool isAdminByEmail(String email) {
    return isOwnerByEmail(email) || isModeratorByEmail(email);
  }

  // ============================================================
  // ROLE FROM FIRESTORE
  // ============================================================

  static bool isOwnerByRole(String? role) {
    return role?.toLowerCase() == 'owner';
  }

  static bool isModeratorByRole(String? role) {
    return role?.toLowerCase() == 'moderator';
  }

  static bool isAdminByRole(String? role) {
    return isOwnerByRole(role) || isModeratorByRole(role);
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  static bool canSendMessages(String? email) {
    return isAdmin(email);
  }

  static bool canManageUsers(String? email) {
    return isOwner(email);
  }

  static bool canManageSettings(String? email) {
    return isOwner(email);
  }

  static bool canViewSystemStats(String? email) {
    return isAdmin(email);
  }

  static bool canDeleteUsers(String? email) {
    return isOwner(email);
  }

  // ============================================================
  // ROLE DISPLAY
  // ============================================================

  static String getRoleDisplayName(String? role) {
    if (role == null) return 'Member';
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'moderator':
        return 'Moderator';
      case 'admin':
        return 'Admin';
      default:
        return 'Member';
    }
  }

  static Color getRoleColor(String? role) {
    if (role == null) return Colors.grey;
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.amber;
      case 'moderator':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static IconData getRoleIcon(String? role) {
    if (role == null) return Icons.person;
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.crown;
      case 'moderator':
        return Icons.shield;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}
