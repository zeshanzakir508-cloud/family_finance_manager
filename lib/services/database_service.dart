// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/family_model.dart';
import '../models/transfer_model.dart';
import '../models/notification_model.dart';
import '../models/backup_model.dart';
import '../models/goal_model.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // USER / PROFILE METHODS
  // ============================================================

  static Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ✅ Get user by username
  static Future<UserModel?> getUserByUsername(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return UserModel.fromJson(query.docs.first.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ✅ Check if username exists
  static Future<bool> usernameExists(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  static Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // ============================================================
  // FAMILY METHODS
  // ============================================================

  static Future<void> saveFamily(FamilyModel family) async {
    try {
      await _firestore.collection('families').doc(family.id).set(family.toJson());
    } catch (e) {
      throw Exception('Failed to save family: $e');
    }
  }

  static Future<void> createFamily(FamilyModel family) async {
    await _firestore.collection('families').doc(family.id).set(family.toJson());
  }

  static Future<List<FamilyModel>> getAllFamilies() async {
    try {
      final snapshot = await _firestore.collection('families').get();
      return snapshot.docs.map((doc) {
        return FamilyModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<FamilyModel>> getUserFamilies(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .where('memberIds', arrayContains: userId)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          return FamilyModel.fromJson(doc.data());
        }).toList();
      }
      
      final allSnapshot = await _firestore.collection('families').get();
      return allSnapshot.docs
          .map((doc) => FamilyModel.fromJson(doc.data()))
          .where((family) => family.members?.any((m) => m.userId == userId) ?? false)
          .toList();
    } catch (e) {
      try {
        final allSnapshot = await _firestore.collection('families').get();
        return allSnapshot.docs
            .map((doc) => FamilyModel.fromJson(doc.data()))
            .where((family) => family.members?.any((m) => m.userId == userId) ?? false)
            .toList();
      } catch (e2) {
        return [];
      }
    }
  }

  static Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (doc.exists) {
        return FamilyModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isUserInFamily(String userId, String familyId) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) return false;
      return family.members?.any((m) => m.userId == userId) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    try {
      final family = await getFamily(familyId);
      return family?.members ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> joinFamily(String familyCode, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .where('familyCode', isEqualTo: familyCode)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        throw Exception('Family not found with code: $familyCode');
      }

      final familyDoc = snapshot.docs.first;
      final family = FamilyModel.fromJson(familyDoc.data());
      
      final newMember = FamilyMember(
        userId: userId, // ✅ FIXED: Removed 'id' parameter
        displayName: 'Member',
        email: '',
        role: 'member',
        joinedAt: DateTime.now(),
        isActive: true,
      );
      
      final updatedMembers = List<FamilyMember>.from(family.members ?? []);
      updatedMembers.add(newMember);
      
      final updatedMemberIds = List<String>.from(family.memberIds ?? []);
      if (!updatedMemberIds.contains(userId)) {
        updatedMemberIds.add(userId);
      }
      
      await _firestore.collection('families').doc(familyDoc.id).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'memberIds': updatedMemberIds,
      });
    } catch (e) {
      throw Exception('Failed to join family: $e');
    }
  }

  static Future<void> leaveFamily(String familyId, String userId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (!doc.exists) {
        throw Exception('Family not found');
      }
      
      final family = FamilyModel.fromJson(doc.data()!);
      // ✅ FIXED: Changed m.id to m.userId
      final updatedMembers = family.members?.where((m) => m.userId != userId).toList() ?? [];
      
      final updatedMemberIds = List<String>.from(family.memberIds ?? []);
      updatedMemberIds.remove(userId);
      
      await _firestore.collection('families').doc(familyId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'memberIds': updatedMemberIds,
      });
    } catch (e) {
      throw Exception('Failed to leave family: $e');
    }
  }

  static Future<void> addFamilyMember(String familyId, FamilyMember member) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (!doc.exists) {
        throw Exception('Family not found');
      }
      
      final family = FamilyModel.fromJson(doc.data()!);
      final updatedMembers = List<FamilyMember>.from(family.members ?? []);
      updatedMembers.add(member);
      
      final updatedMemberIds = List<String>.from(family.memberIds ?? []);
      if (!updatedMemberIds.contains(member.userId)) {
        updatedMemberIds.add(member.userId);
      }
      
      await _firestore.collection('families').doc(familyId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'memberIds': updatedMemberIds,
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  // ============================================================
  // TRANSACTION METHODS
  // ============================================================

  static Future<void> addPersonalTransaction(TransactionModel transaction) async {
    try {
      final data = transaction.toJson();
      data['type'] = 'personal';
      await _firestore.collection('transactions').add(data);
    } catch (e) {
      throw Exception('Failed to add personal transaction: $e');
    }
  }

  static Future<void> addFamilyTransaction(TransactionModel transaction) async {
    try {
      final data = transaction.toJson();
      data['type'] = 'family';
      await _firestore.collection('transactions').add(data);
    } catch (e) {
      throw Exception('Failed to add family transaction: $e');
    }
  }

  static Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      if (transaction.id != null && transaction.id!.isNotEmpty) {
        final snapshot = await _firestore
            .collection('transactions')
            .where('id', isEqualTo: transaction.id)
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          await _firestore
              .collection('transactions')
              .doc(snapshot.docs.first.id)
              .update(transaction.toJson());
        } else {
          await _firestore.collection('transactions').add(transaction.toJson());
        }
      } else {
        await _firestore.collection('transactions').add(transaction.toJson());
      }
    } catch (e) {
      throw Exception('Failed to save transaction: $e');
    }
  }

  static Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'personal')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return TransactionModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TransactionModel>> getFamilyTransactions(
    String familyId, 
    String userId,
  ) async {
    try {
      final isMember = await isUserInFamily(userId, familyId);
      if (!isMember) {
        print('⚠️ User $userId is not a member of family $familyId');
        return [];
      }

      final snapshot = await _firestore
          .collection('transactions')
          .where('familyId', isEqualTo: familyId)
          .where('type', isEqualTo: 'family')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return TransactionModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TransactionModel>> getAllUserTransactions(String userId) async {
    try {
      final personal = await getUserTransactions(userId);
      
      final families = await getUserFamilies(userId);
      List<TransactionModel> allTransactions = List.from(personal);
      
      for (final family in families) {
        final familyTxn = await getFamilyTransactions(family.id, userId);
        allTransactions.addAll(familyTxn);
      }
      
      allTransactions.sort((a, b) {
        final dateA = a.date ?? DateTime(1970);
        final dateB = b.date ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      return allTransactions;
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteTransaction(String transactionId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('id', isEqualTo: transactionId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await _firestore.collection('transactions').doc(snapshot.docs.first.id).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // ============================================================
  // TRANSFER METHODS
  // ============================================================

  static Future<void> saveTransfer(TransferModel transfer) async {
    try {
      await _firestore.collection('transfers').doc(transfer.id).set(transfer.toJson());
    } catch (e) {
      throw Exception('Failed to save transfer: $e');
    }
  }

  static Future<void> createTransfer(TransferModel transfer) async {
    await _firestore.collection('transfers').add(transfer.toJson());
  }

  static Future<void> updateTransfer(TransferModel transfer) async {
    final snapshot = await _firestore
        .collection('transfers')
        .where('id', isEqualTo: transfer.id)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      await _firestore.collection('transfers').doc(snapshot.docs.first.id).update(transfer.toJson());
    }
  }

  static Future<List<TransferModel>> getFamilyTransfers(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('transfers')
          .where('familyId', isEqualTo: familyId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return TransferModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TransferModel>> getUserTransfers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transfers')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return TransferModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // NOTIFICATION METHODS
  // ============================================================

  static Future<void> saveNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      throw Exception('Failed to save notification: $e');
    }
  }

  static Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return NotificationModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('id', isEqualTo: notificationId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await _firestore
            .collection('notifications')
            .doc(snapshot.docs.first.id)
            .update({'isRead': true});
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // ============================================================
  // BACKUP METHODS
  // ============================================================

  static Future<void> saveBackup(BackupModel backup) async {
    try {
      await _firestore.collection('backups').doc(backup.id).set(backup.toJson());
    } catch (e) {
      throw Exception('Failed to save backup: $e');
    }
  }

  static Future<void> deleteBackup(String backupId) async {
    try {
      final snapshot = await _firestore
          .collection('backups')
          .where('id', isEqualTo: backupId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await _firestore.collection('backups').doc(snapshot.docs.first.id).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  static Future<List<BackupModel>> getUserBackups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('backups')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return BackupModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GOAL METHODS
  // ============================================================

  static Future<void> saveGoal(GoalModel goal) async {
    try {
      await _firestore.collection('goals').doc(goal.id).set(goal.toJson());
    } catch (e) {
      throw Exception('Failed to save goal: $e');
    }
  }

  static Future<List<GoalModel>> getUserGoals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return GoalModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // CLEAR ALL DATA
  // ============================================================

  static Future<void> clearAllData() async {
    try {
      final collections = ['users', 'transactions', 'families', 'transfers', 'notifications', 'backups', 'goals'];
      
      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }
}
