// lib/services/category_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createCategory(CategoryModel category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = category.toJson();
      data['userId'] = user.uid;
      data['createdAt'] = FieldValue.serverTimestamp();

      // Check for duplicate
      final existing = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
          .where('name', isEqualTo: category.name)
          .where('type', isEqualTo: category.type)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Category with this name already exists');
      }

      final docRef = await _firestore.collection('categories').add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<List<CategoryModel>> getCategoriesByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<List<CategoryModel>> getCategoriesByType(String userId, String type) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get categories by type: $e');
    }
  }

  Future<List<CategoryModel>> getCategoriesByFamily(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family categories: $e');
    }
  }

  Future<List<CategoryModel>> getDefaultCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isDefault', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => CategoryModel.fromJson(doc.data()))
            .toList();
      }
      
      // If no default categories in Firestore, return hardcoded ones
      return CategoryModel.defaultCategories;
    } catch (e) {
      return CategoryModel.defaultCategories;
    }
  }

  Future<List<CategoryModel>> getAllCategoriesForUser(String userId) async {
    try {
      final userCategories = await getCategoriesByUser(userId);
      final defaultCategories = await getDefaultCategories();
      
      // Combine and remove duplicates
      final allCategories = <CategoryModel>[];
      final existingNames = <String>{};

      // Add default categories first
      for (var cat in defaultCategories) {
        if (!existingNames.contains(cat.name)) {
          allCategories.add(cat);
          existingNames.add(cat.name);
        }
      }

      // Add user categories (override defaults if same name)
      for (var cat in userCategories) {
        final index = allCategories.indexWhere((c) => c.name == cat.name);
        if (index != -1) {
          allCategories[index] = cat; // Replace with user's version
        } else {
          allCategories.add(cat);
        }
      }

      // Sort by order
      allCategories.sort((a, b) => (a.order ?? 999).compareTo(b.order ?? 999));
      
      return allCategories;
    } catch (e) {
      throw Exception('Failed to get all categories: $e');
    }
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection('categories').doc(id).get();
      if (!doc.exists) return null;
      return CategoryModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  Future<CategoryModel?> getCategoryByName(String userId, String name) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return CategoryModel.fromJson(snapshot.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  Stream<List<CategoryModel>> streamCategoriesByUser(String userId) {
    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<CategoryModel>> streamCategoriesByType(String userId, String type) {
    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromJson(doc.data()))
            .toList());
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('categories').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> updateCategoryOrder(String userId, List<String> categoryIds) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < categoryIds.length; i++) {
        final ref = _firestore.collection('categories').doc(categoryIds[i]);
        batch.update(ref, {
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update category order: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteCategory(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('categories').doc(id).get();
      if (!doc.exists) throw Exception('Category not found');
      
      final data = doc.data()!;
      if (data['isDefault'] == true) {
        throw Exception('Cannot delete default categories');
      }
      if (data['userId'] != user.uid) {
        throw Exception('You can only delete your own categories');
      }

      // Soft delete
      await _firestore.collection('categories').doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Future<void> permanentDelete(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete category: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<void> initializeDefaultCategories(String userId) async {
    try {
      // Check if user already has categories
      final existing = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existing.docs.isNotEmpty) return;

      // Create default categories for user
      final batch = _firestore.batch();
      final defaultCategories = CategoryModel.defaultCategories;

      for (var category in defaultCategories) {
        final data = category.toJson();
        data['userId'] = userId;
        data['familyId'] = null;
        data['createdAt'] = FieldValue.serverTimestamp();
        
        final ref = _firestore.collection('categories').doc();
        batch.set(ref, data);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to initialize default categories: $e');
    }
  }

  Future<Map<String, int>> getCategoryUsageCount(String userId) async {
    try {
      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      final usage = <String, int>{};
      
      for (var doc in transactions.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null) {
          usage[category] = (usage[category] ?? 0) + 1;
        }
      }
      
      return usage;
    } catch (e) {
      return {};
    }
  }

  Future<List<CategoryModel>> getMostUsedCategories(String userId, {int limit = 5}) async {
    try {
      final usage = await getCategoryUsageCount(userId);
      
      if (usage.isEmpty) return [];
      
      // Sort by usage count descending
      final sorted = usage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topCategoryNames = sorted.take(limit).map((e) => e.key).toList();
      
      final categories = <CategoryModel>[];
      for (var name in topCategoryNames) {
        final category = await getCategoryByName(userId, name);
        if (category != null) {
          categories.add(category);
        }
      }
      
      return categories;
    } catch (e) {
      return [];
    }
  }

  Future<double> getTotalSpentByCategory(String userId, String category) async {
    try {
      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('type', isEqualTo: 'expense')
          .where('isDeleted', isEqualTo: false)
          .get();

      double total = 0.0;
      for (var doc in transactions.docs) {
        total += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, double>> getCategorySpendingSummary(String userId) async {
    try {
      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'expense')
          .where('isDeleted', isEqualTo: false)
          .get();

      final summary = <String, double>{};
      
      for (var doc in transactions.docs) {
        final category = doc.data()['category'] as String? ?? 'Other';
        final amount = (doc.data()['amount'] ?? 0.0).toDouble();
        summary[category] = (summary[category] ?? 0.0) + amount;
      }
      
      return summary;
    } catch (e) {
      return {};
    }
  }
}
