// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = transaction.toJson();
      data['userId'] = user.uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('transactions').add(data);
      
      // Update user balance
      await _updateUserBalance(user.uid, transaction.amount!, transaction.type!);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();

      // ✅ FIXED: Cast to Map<String, dynamic>
      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  Future<List<TransactionModel>> getTransactionsByFamily(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('familyId', isEqualTo: familyId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();

      // ✅ FIXED: Cast to Map<String, dynamic>
      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family transactions: $e');
    }
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final doc = await _firestore.collection('transactions').doc(id).get();
      if (!doc.exists) return null;
      // ✅ FIXED: Cast to Map<String, dynamic>
      return TransactionModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  Stream<List<TransactionModel>> streamTransactionsByUser(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<TransactionModel>> streamTransactionsByFamily(String familyId) {
    return _firestore
        .collection('transactions')
        .where('familyId', isEqualTo: familyId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get existing transaction
      final oldDoc = await _firestore.collection('transactions').doc(id).get();
      if (!oldDoc.exists) throw Exception('Transaction not found');
      
      final oldData = oldDoc.data() as Map<String, dynamic>;
      if (oldData['userId'] != user.uid) {
        throw Exception('You can only update your own transactions');
      }

      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('transactions').doc(id).update(data);

      // Update balance if amount or type changed
      if (data.containsKey('amount') || data.containsKey('type')) {
        final newAmount = data['amount'] ?? oldData['amount'];
        final newType = data['type'] ?? oldData['type'];
        
        // Revert old balance
        await _updateUserBalance(
          user.uid,
          -oldData['amount'].toDouble(),
          oldData['type'],
        );
        // Apply new balance
        await _updateUserBalance(
          user.uid,
          newAmount.toDouble(),
          newType,
        );
      }
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteTransaction(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('transactions').doc(id).get();
      if (!doc.exists) throw Exception('Transaction not found');
      
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user.uid) {
        throw Exception('You can only delete your own transactions');
      }

      // Soft delete
      await _firestore.collection('transactions').doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Revert balance
      await _updateUserBalance(
        user.uid,
        -data['amount'].toDouble(),
        data['type'],
      );
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  Future<void> permanentDelete(String id) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete transaction: $e');
    }
  }

  // ============================================================
  // FILTER & SEARCH
  // ============================================================

  Future<List<TransactionModel>> filterTransactions({
    String? userId,
    String? familyId,
    String? category,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('transactions')
          .where('isDeleted', isEqualTo: false);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (familyId != null) {
        query = query.where('familyId', isEqualTo: familyId);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      if (minAmount != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: minAmount);
      }
      if (maxAmount != null) {
        query = query.where('amount', isLessThanOrEqualTo: maxAmount);
      }
      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      query = query.orderBy('date', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to filter transactions: $e');
    }
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Search by description, category, notes
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();

      final results = snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((t) =>
              t.description?.toLowerCase().contains(query.toLowerCase()) == true ||
              t.category?.toLowerCase().contains(query.toLowerCase()) == true ||
              t.notes?.toLowerCase().contains(query.toLowerCase()) == true)
          .toList();

      return results;
    } catch (e) {
      throw Exception('Failed to search transactions: $e');
    }
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Future<Map<String, double>> getSummary(String userId) async {
    try {
      final transactions = await getTransactionsByUser(userId);
      
      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var t in transactions) {
        if (t.isIncome) {
          totalIncome += t.amount!;
        } else if (t.isExpense) {
          totalExpense += t.amount!;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      throw Exception('Failed to get summary: $e');
    }
  }

  Future<Map<String, double>> getCategorySummary(String userId) async {
    try {
      final transactions = await getTransactionsByUser(userId);
      final Map<String, double> categoryTotals = {};

      for (var t in transactions) {
        if (t.isExpense) {
          final category = t.category ?? 'Other';
          categoryTotals[category] = (categoryTotals[category] ?? 0.0) + t.amount!;
        }
      }

      return categoryTotals;
    } catch (e) {
      throw Exception('Failed to get category summary: $e');
    }
  }

  Future<Map<String, Map<String, double>>> getMonthlySummary(String userId) async {
    try {
      final transactions = await getTransactionsByUser(userId);
      final Map<String, Map<String, double>> monthlyData = {};

      for (var t in transactions) {
        final monthKey = '${t.date!.year}-${t.date!.month.toString().padLeft(2, '0')}';
        
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {'income': 0.0, 'expense': 0.0};
        }

        if (t.isIncome) {
          monthlyData[monthKey]!['income'] = 
              (monthlyData[monthKey]!['income'] ?? 0.0) + t.amount!;
        } else if (t.isExpense) {
          monthlyData[monthKey]!['expense'] = 
              (monthlyData[monthKey]!['expense'] ?? 0.0) + t.amount!;
        }
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to get monthly summary: $e');
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  Future<void> _updateUserBalance(String userId, double amount, String type) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;

        final currentBalance = (doc.data()?['balance'] ?? 0.0).toDouble();
        final currentIncome = (doc.data()?['totalIncome'] ?? 0.0).toDouble();
        final currentExpense = (doc.data()?['totalExpense'] ?? 0.0).toDouble();

        double newBalance = currentBalance;
        double newIncome = currentIncome;
        double newExpense = currentExpense;

        if (type == 'income') {
          newIncome += amount;
          newBalance += amount;
        } else if (type == 'expense') {
          newExpense += amount;
          newBalance -= amount;
        }

        transaction.update(userRef, {
          'balance': newBalance,
          'totalIncome': newIncome,
          'totalExpense': newExpense,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Failed to update user balance: $e');
    }
  }
}
