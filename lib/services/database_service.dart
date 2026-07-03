// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/family_model.dart';
import '../models/transfer_model.dart';

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

  // ==================== FAMILY METHODS ====================

  static Future<void> createFamily(Family family) async {
    await _firestore.collection('families').doc(family.id).set(family.toJson());
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
      final family = Family.fromJson(familyDoc.data());
      
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
      
      final family = Family.fromJson(doc.data()!);
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
      
      final family = Family.fromJson(doc.data()!);
      final updatedMembers = List<FamilyMember>.from(family.members ?? []);
      updatedMembers.add(member);
      
      await _firestore.collection('families').doc(familyId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  static Future<List<Family>> getUserFamilies(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .where('members', arrayContains: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        return Family.fromJson(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Family?> getFamily(String familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (doc.exists) {
        return Family.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== TRANSFER METHODS ====================

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

  // ==================== TRANSACTION DELETE ====================

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
}
