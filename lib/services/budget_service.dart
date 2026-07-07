// lib/services/budget_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createBudget(BudgetModel budget) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = budget.toJson();
      data['userId'] = user.uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('budgets').add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<List<BudgetModel>> getBudgetsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get budgets: $e');
    }
  }

  Future<List<BudgetModel>> getBudgetsByFamily(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family budgets: $e');
    }
  }

  Future<BudgetModel?> getBudgetByMonth(String userId, int month, int year) async {
    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return BudgetModel.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  Future<BudgetModel?> getBudgetById(String id) async {
    try {
      final doc = await _firestore.collection('budgets').doc(id).get();
      if (!doc.exists) return null;
      return BudgetModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  Stream<List<BudgetModel>> streamBudgetsByUser(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromJson(doc.data()))
            .toList());
  }

  Stream<BudgetModel?> streamBudgetByMonth(String userId, int month, int year) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return BudgetModel.fromJson(snapshot.docs.first.data());
        });
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('budgets').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  Future<void> updateBudgetSpending(String budgetId, String categoryId, double amount) async {
    try {
      final doc = await _firestore.collection('budgets').doc(budgetId).get();
      if (!doc.exists) throw Exception('Budget not found');

      final budget = BudgetModel.fromJson(doc.data()!);
      final updatedBudget = budget.updateCategorySpent(categoryId, amount);

      await _firestore.collection('budgets').doc(budgetId).update({
        'categories': updatedBudget.categories.map((c) => c.toJson()).toList(),
        'totalSpent': updatedBudget.totalSpent,
        'totalRemaining': updatedBudget.totalRemaining,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update budget spending: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteBudget(String id) async {
    try {
      await _firestore.collection('budgets').doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  Future<void> permanentDelete(String id) async {
    try {
      await _firestore.collection('budgets').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete budget: $e');
    }
  }

  // ============================================================
  // ROLLOVER
  // ============================================================

  Future<BudgetModel?> rolloverBudget(String budgetId) async {
    try {
      final doc = await _firestore.collection('budgets').doc(budgetId).get();
      if (!doc.exists) throw Exception('Budget not found');

      final oldBudget = BudgetModel.fromJson(doc.data()!);
      
      // Create new budget for next month
      final newMonth = oldBudget.month == 12 ? 1 : oldBudget.month + 1;
      final newYear = oldBudget.month == 12 ? oldBudget.year + 1 : oldBudget.year;

      final newBudget = oldBudget.copyWith(
        id: '', // Will be generated
        month: newMonth,
        year: newYear,
        isRollover: true,
        previousBudgetId: budgetId,
        createdAt: DateTime.now(),
        updatedAt: null,
        totalSpent: 0.0,
        categories: oldBudget.categories.map((c) => c.copyWith(
          spent: 0.0,
          remaining: c.remaining + c.allocated,
        )).toList(),
      );

      final newId = await createBudget(newBudget);
      return await getBudgetById(newId);
    } catch (e) {
      throw Exception('Failed to rollover budget: $e');
    }
  }

  // ============================================================
  // TEMPLATES
  // ============================================================

  Future<BudgetModel> createFromTemplate(String userId, BudgetModel template) async {
    try {
      final newBudget = template.copyWith(
        id: '',
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: null,
        totalSpent: 0.0,
        categories: template.categories.map((c) => c.copyWith(
          spent: 0.0,
          remaining: c.allocated,
        )).toList(),
      );

      final id = await createBudget(newBudget);
      return (await getBudgetById(id))!;
    } catch (e) {
      throw Exception('Failed to create budget from template: $e');
    }
  }

  Future<void> saveAsTemplate(String budgetId) async {
    try {
      final doc = await _firestore.collection('budgets').doc(budgetId).get();
      if (!doc.exists) throw Exception('Budget not found');

      final budget = BudgetModel.fromJson(doc.data()!);
      
      await _firestore.collection('budget_templates').add({
        'name': budget.name,
        'description': budget.description,
        'categories': budget.categories.map((c) => c.toJson()).toList(),
        'userId': budget.userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save as template: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<double> getCurrentMonthBudget(String userId) async {
    try {
      final now = DateTime.now();
      final budget = await getBudgetByMonth(userId, now.month, now.year);
      return budget?.totalAllocated ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getCurrentMonthSpending(String userId) async {
    try {
      final now = DateTime.now();
      final budget = await getBudgetByMonth(userId, now.month, now.year);
      return budget?.totalSpent ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getCategoryBudget(String userId, String category, int month, int year) async {
    try {
      final budget = await getBudgetByMonth(userId, month, year);
      if (budget == null) return 0.0;
      
      final categoryBudget = budget.getCategoryByName(category);
      return categoryBudget?.allocated ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<bool> isBudgetExceeded(String userId, String category, int month, int year) async {
    try {
      final budget = await getBudgetByMonth(userId, month, year);
      if (budget == null) return false;
      
      final categoryBudget = budget.getCategoryByName(category);
      if (categoryBudget == null) return false;
      
      return categoryBudget.isOverBudget;
    } catch (e) {
      return false;
    }
  }
}
