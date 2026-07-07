// lib/providers/category_provider.dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import 'auth_provider.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<CategoryModel> _categories = [];
  List<CategoryModel> _incomeCategories = [];
  List<CategoryModel> _expenseCategories = [];
  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories => _incomeCategories;
  List<CategoryModel> get expenseCategories => _expenseCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadCategories(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Initialize default categories if needed
      await _categoryService.initializeDefaultCategories(userId);
      
      // Load all categories
      _categories = await _categoryService.getAllCategoriesForUser(userId);
      
      // Split by type
      _incomeCategories = _categories.where((c) => c.isIncome).toList();
      _expenseCategories = _categories.where((c) => c.isExpense).toList();
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> loadFamilyCategories(String familyId) async {
    _setLoading(true);
    _clearError();

    try {
      _categories = await _categoryService.getCategoriesByFamily(familyId);
      _incomeCategories = _categories.where((c) => c.isIncome).toList();
      _expenseCategories = _categories.where((c) => c.isExpense).toList();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshCategories(String userId) async {
    await loadCategories(userId);
  }

  // ============================================================
  // CRUD
  // ============================================================

  Future<bool> createCategory(CategoryModel category) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _categoryService.createCategory(category);
      final newCategory = category.copyWith(id: id);
      _categories.add(newCategory);
      _updateSplitCategories();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryService.updateCategory(id, data);
      
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(
          name: data['name'] ?? _categories[index].name,
          icon: data['icon'] ?? _categories[index].icon,
          color: data['color'] ?? _categories[index].color,
          type: data['type'] ?? _categories[index].type,
        );
        _updateSplitCategories();
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _updateSplitCategories();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategoryOrder(List<String> categoryIds) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryService.updateCategoryOrder(categoryIds);
      
      // Update order locally
      for (int i = 0; i < categoryIds.length; i++) {
        final index = _categories.indexWhere((c) => c.id == categoryIds[i]);
        if (index != -1) {
          _categories[index] = _categories[index].copyWith(order: i);
        }
      }
      
      _categories.sort((a, b) => (a.order ?? 999).compareTo(b.order ?? 999));
      _updateSplitCategories();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  List<CategoryModel> getCategoriesByType(String type) {
    return _categories.where((c) => c.type == type || c.type == 'both').toList();
  }

  List<CategoryModel> getIncomeCategoriesWithBoth() {
    return _categories.where((c) => c.isIncome).toList();
  }

  List<CategoryModel> getExpenseCategoriesWithBoth() {
    return _categories.where((c) => c.isExpense).toList();
  }

  bool hasCategory(String name) {
    return _categories.any((c) => c.name.toLowerCase() == name.toLowerCase());
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _updateSplitCategories() {
    _incomeCategories = _categories.where((c) => c.isIncome).toList();
    _expenseCategories = _categories.where((c) => c.isExpense).toList();
  }
}
