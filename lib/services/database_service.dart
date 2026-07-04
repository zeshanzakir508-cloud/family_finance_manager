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

  // ==================== USER METHODS ====================

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

  static Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  // ==================== TRANSACTION METHODS ====================

  static Future<void> addPersonalTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toJson());
  }

  static Future<void> addFamilyTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toJson());
  }

  static Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      if (transaction.id != null && transaction.id!.isNotEmpty) {
        // Update existing transaction
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
        // New transaction
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
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return TransactionModel.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TransactionModel>> getFamilyTransactions(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('familyId', isEqualTo: familyId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return TransactionModel.fromJson(doc.data());
      }).toList();
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

  // ==================== FAMILY METHODS ====================

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
      
      // Add user as member
      final newMember = FamilyMember(
        id: userId,
        userId: userId,
        displayName: 'Member',
        email: '',
        role: 'member',
        joinedAt: DateTime.now(),
        isActive: true,
      );
      
      final updatedMembers = List<FamilyMember>.from(family.members ?? []);
      updatedMembers.add(newMember);
      
      await _firestore.collection('families').doc(familyDoc.id).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
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
      final updatedMembers = family.members?.where((m) => m.id != userId).toList() ?? [];
      
      await _firestore.collection('families').doc(familyId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
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
      
      await _firestore.collection('families').doc(familyId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  static Future<List<FamilyModel>> getUserFamilies(String userId) async {
    try {
      // Note: arrayContains on objects doesn't work well in Firestore
      // We need to use a different approach - query all families and filter
      final snapshot = await _firestore.collection('families').get();
      
      return snapshot.docs
          .map((doc) => FamilyModel.fromJson(doc.data()))
          .where((family) => family.members?.any((m) => m.userId == userId) ?? false)
          .toList();
    } catch (e) {
      return [];
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

  // ==================== TRANSFER METHODS ====================

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

  // ==================== NOTIFICATION METHODS ====================

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

  // ==================== BACKUP METHODS ====================

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

  // ==================== GOAL METHODS ====================

  static Future<void> saveGoal(GoalModel goal) async {
    try {
      await _firestore.collection('goals').doc(goal.id).set(goal.toJson());
    } catch (e) {
      throw Exception('Failed to save goal: $e');
    }
  }

  // ==================== CLEAR ALL DATA ====================

  static Future<void> clearAllData() async {
    try {
      // Delete all collections - be careful with this!
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
