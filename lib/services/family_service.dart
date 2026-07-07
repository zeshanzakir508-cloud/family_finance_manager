// lib/services/family_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // CREATE FAMILY
  // ============================================================

  Future<String> createFamily({
    required String name,
    required String currency,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final familyData = {
        'name': name,
        'description': description,
        'currency': currency,
        'createdBy': user.uid,
        'familyCode': _generateFamilyCode(),
        'members': [user.uid],
        'admins': [user.uid],
        'totalBalance': 0.0,
        'totalIncome': 0.0,
        'totalExpense': 0.0,
        'settings': {
          'allowMembersToAdd': true,
          'requireApproval': false,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      final docRef = await _firestore.collection('families').add(familyData);

      // Update user's familyId
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': docRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create family: $e');
    }
  }

  // ============================================================
  // GET FAMILY
  // ============================================================

  Future<FamilyModel?> getFamilyById(String familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (!doc.exists) return null;
      return FamilyModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get family: $e');
    }
  }

  Future<FamilyModel?> getCurrentFamily() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final familyId = userDoc.data()?['familyId'] as String?;
      if (familyId == null || familyId.isEmpty) return null;

      return await getFamilyById(familyId);
    } catch (e) {
      throw Exception('Failed to get current family: $e');
    }
  }

  Stream<FamilyModel?> streamFamily(String familyId) {
    return _firestore.collection('families').doc(familyId).snapshots().map(
      (doc) => doc.exists ? FamilyModel.fromJson(doc.data()!) : null,
    );
  }

  // ============================================================
  // JOIN FAMILY
  // ============================================================

  Future<void> joinFamily(String familyCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Find family by code
      final query = await _firestore
          .collection('families')
          .where('familyCode', isEqualTo: familyCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Invalid family code');
      }

      final familyDoc = query.docs.first;
      final familyId = familyDoc.id;

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(familyDoc.reference);
        if (!doc.exists) throw Exception('Family not found');

        final members = List<String>.from(doc.data()?['members'] ?? []);
        if (members.contains(user.uid)) {
          throw Exception('Already a member');
        }

        members.add(user.uid);
        transaction.update(familyDoc.reference, {
          'members': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update user's familyId
        await _firestore.collection('users').doc(user.uid).update({
          'familyId': familyId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to join family: $e');
    }
  }

  // ============================================================
  // LEAVE FAMILY
  // ============================================================

  Future<void> leaveFamily() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final familyId = userDoc.data()?['familyId'] as String?;
      if (familyId == null) return;

      final familyRef = _firestore.collection('families').doc(familyId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(familyRef);
        if (!doc.exists) return;

        final members = List<String>.from(doc.data()?['members'] ?? []);
        final admins = List<String>.from(doc.data()?['admins'] ?? []);

        members.remove(user.uid);
        admins.remove(user.uid);

        if (members.isEmpty) {
          transaction.delete(familyRef);
        } else {
          if (admins.isEmpty && members.isNotEmpty) {
            transaction.update(familyRef, {
              'admins': [members.first],
            });
          }
          transaction.update(familyRef, {
            'members': members,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Clear user's familyId
        await _firestore.collection('users').doc(user.uid).update({
          'familyId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to leave family: $e');
    }
  }

  // ============================================================
  // MANAGE MEMBERS
  // ============================================================

  Future<void> inviteMember(String email) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final familyId = userDoc.data()?['familyId'] as String?;
      if (familyId == null) throw Exception('No family found');

      // Check if user exists
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found');
      }

      final targetUser = userQuery.docs.first;
      final targetUserId = targetUser.id;
      final targetFamilyId = targetUser.data()['familyId'] as String?;

      if (targetFamilyId != null) {
        throw Exception('User already in a family');
      }

      // Add to family members
      await _firestore.runTransaction((transaction) async {
        final familyRef = _firestore.collection('families').doc(familyId);
        final doc = await transaction.get(familyRef);
        if (!doc.exists) throw Exception('Family not found');

        final members = List<String>.from(doc.data()?['members'] ?? []);
        if (members.contains(targetUserId)) {
          throw Exception('Already a member');
        }

        members.add(targetUserId);
        transaction.update(familyRef, {
          'members': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update user's familyId
        transaction.update(
          _firestore.collection('users').doc(targetUserId),
          {
            'familyId': familyId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });
    } catch (e) {
      throw Exception('Failed to invite member: $e');
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final familyId = userDoc.data()?['familyId'] as String?;
      if (familyId == null) throw Exception('No family found');

      // Check if user is admin
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      final admins = List<String>.from(familyDoc.data()?['admins'] ?? []);
      if (!admins.contains(user.uid)) {
        throw Exception('Only admins can remove members');
      }

      final familyRef = _firestore.collection('families').doc(familyId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(familyRef);
        if (!doc.exists) return;

        final members = List<String>.from(doc.data()?['members'] ?? []);
        members.remove(userId);

        transaction.update(familyRef, {
          'members': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Clear user's familyId
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'familyId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // ============================================================
  // ADMIN MANAGEMENT
  // ============================================================

  Future<void> promoteToAdmin(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final familyId = userDoc.data()?['familyId'] as String?;
      if (familyId == null) throw Exception('No family found');

      final familyRef = _firestore.collection('families').doc(familyId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(familyRef);
        if (!doc.exists) return;

        final admins = List<String>.from(doc.data()?['admins'] ?? []);
        if (!admins.contains(userId)) {
          admins.add(userId);
          transaction.update(familyRef, {
            'admins': admins,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to promote to admin: $e');
    }
  }

  Future<void> demoteFromAdmin(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final familyId = userDoc.data()?['familyId'] as String?;
      if (familyId == null) throw Exception('No family found');

      final familyRef = _firestore.collection('families').doc(familyId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(familyRef);
        if (!doc.exists) return;

        final admins = List<String>.from(doc.data()?['admins'] ?? []);
        admins.remove(userId);
        transaction.update(familyRef, {
          'admins': admins,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to demote from admin: $e');
    }
  }

  // ============================================================
  // UPDATE FAMILY
  // ============================================================

  Future<void> updateFamily(String familyId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('families').doc(familyId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update family: $e');
    }
  }

  Future<void> deleteFamily(String familyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final familyRef = _firestore.collection('families').doc(familyId);
      final doc = await familyRef.get();
      if (!doc.exists) return;

      final admins = List<String>.from(doc.data()?['admins'] ?? []);
      if (!admins.contains(user.uid)) {
        throw Exception('Only admins can delete family');
      }

      // Remove familyId from all members
      final members = List<String>.from(doc.data()?['members'] ?? []);
      for (var memberId in members) {
        await _firestore.collection('users').doc(memberId).update({
          'familyId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await familyRef.delete();
    } catch (e) {
      throw Exception('Failed to delete family: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[DateTime.now().millisecondsSinceEpoch % chars.length];
    }
    return code;
  }

  Future<List<UserModel>> getFamilyMembers(String familyId) async {
    try {
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (!familyDoc.exists) return [];

      final memberIds = List<String>.from(familyDoc.data()?['members'] ?? []);
      if (memberIds.isEmpty) return [];

      final users = await _firestore
          .collection('users')
          .where('uid', whereIn: memberIds)
          .get();

      return users.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get family members: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamFamilyMembers(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data()!;
      final memberIds = List<String>.from(data['members'] ?? []);
      final adminIds = List<String>.from(data['admins'] ?? []);
      
      return memberIds.map((id) {
        return {
          'userId': id,
          'isAdmin': adminIds.contains(id),
        };
      }).toList();
    });
  }

  Future<bool> isMember(String familyId, String userId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (!doc.exists) return false;
      final members = List<String>.from(doc.data()?['members'] ?? []);
      return members.contains(userId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAdmin(String familyId, String userId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (!doc.exists) return false;
      final admins = List<String>.from(doc.data()?['admins'] ?? []);
      return admins.contains(userId);
    } catch (e) {
      return false;
    }
  }
}
