// lib/utils/user_roles.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRoles {
  static const String ownerEmail = 'zeshanzakir508@gmail.com';
  static const String moderatorEmail = 'mrszeshanzakir508@gmail.com';
  static const String ownerUid = 'p5i0CiIZCkV2ri0HQ04UWmRlUCv1';
  static const String moderatorUid = 'kIswcj0Do9VtvAxcy9ad9ej6IKz1';

  static bool isOwner(String? email, String? uid) {
    return email == ownerEmail || uid == ownerUid;
  }

  static bool isModerator(String? email, String? uid) {
    return email == moderatorEmail || uid == moderatorUid;
  }

  static bool hasAdminAccess(String? email, String? uid) {
    return isOwner(email, uid) || isModerator(email, uid);
  }

  static String getRole(String? email, String? uid) {
    if (isOwner(email, uid)) return '👑 Owner';
    if (isModerator(email, uid)) return '🛡️ Moderator';
    return 'Member';
  }

  static Color getRoleColor(String? email, String? uid) {
    if (isOwner(email, uid)) return const Color(0xFFFFD700);
    if (isModerator(email, uid)) return Colors.blue;
    return Colors.grey;
  }

  static Future<void> ensureOwnerAndModeratorInFirestore() async {
    final firestore = FirebaseFirestore.instance;
    
    // Owner
    await firestore.collection('users').doc(ownerUid).set({
      'uid': ownerUid,
      'email': ownerEmail,
      'displayName': 'Zeshan Zakir',
      'role': 'owner',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Moderator
    await firestore.collection('users').doc(moderatorUid).set({
      'uid': moderatorUid,
      'email': moderatorEmail,
      'displayName': 'Mrs Zeshan Zakir',
      'role': 'moderator',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
