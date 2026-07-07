// lib/providers/budget_provider.dart
import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import 'auth_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  
  List<BudgetModel> _budgets = [];
  BudgetModel? _currentBudget;
  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<BudgetModel> get budgets => _budgets;
  BudgetModel? get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalAllocated {
    return _budgets.fold(0.0, (sum, b) => sum + b.totalAllocated);
  }

  double get totalSpent {
    return _budgets.fold(0.0, (sum, b) => sum + b.totalSpent);
  }

  double get totalRemaining {
    return _budgets.fold(0.0, (sum, b) => sum + b.totalRemaining);
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadBudgets(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _budgets = await _budgetService.getBudgetsByUser(userId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> loadFamilyBudgets(String familyId) async {
    _setLoading(true);
    _clearError();

    try {
      _budgets = await _budgetService.getBudgetsByFamily(familyId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> loadCurrentMonthBudget(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final now = DateTime.now();
      _currentBudget = await _budgetService.getBudgetByMonth(
        userId,
        now.month,
        now.year,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshBudgets(String userId) async {
    await loadBudgets(userId);
  }

  // ============================================================
  // CRUD
  // ============================================================

  Future<bool> createBudget(BudgetModel budget) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _budgetService.createBudget(budget);
      final newBudget = budget.copyWith(id: id);
      _budgets.add(newBudget);
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

  Future<bool> updateBudget(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await _budgetService.updateBudget(id, data);
      
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index != -1) {
        _budgets[index] = _budgets[index].copyWith(
          name: data['name'] ?? _budgets[index].name,
          totalAllocated: data['totalAllocated'] ?? _budgets[index].totalAllocated,
          categories: data['categories'] ?? _budgets[index].categories,
        );
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

  Future<bool> updateBudgetSpending(String budgetId, String categoryId, double amount) async {
    _setLoading(true);
    _clearError();

    try {
      await _budgetService.updateBudgetSpending(budgetId, categoryId, amount);
      
      final index = _budgets.indexWhere((b) => b.id == budgetId);
      if (index != -1) {
        final updated = _budgets[index].updateCategorySpent(categoryId, amount);
        _budgets[index] = updated;
        if (_currentBudget?.id == budgetId) {
          _currentBudget = updated;
        }
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

  Future<bool> deleteBudget(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _budgetService.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      if (_currentBudget?.id == id) {
        _currentBudget = null;
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

  // ============================================================
  // ROLLOVER
  // ============================================================

  Future<BudgetModel?> rolloverBudget(String budgetId) async {
    _setLoading(true);
    _clearError();

    try {
      final newBudget = await _budgetService.rolloverBudget(budgetId);
      if (newBudget != null) {
        _budgets.add(newBudget);
        _currentBudget = newBudget;
        _setLoading(false);
        notifyListeners();
        return newBudget;
      }
      _setLoading(false);
      return null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // SET CURRENT
  // ============================================================

  void setCurrentBudget(BudgetModel budget) {
    _currentBudget = budget;
    notifyListeners();
  }

  void setCurrentBudgetById(String id) {
    final budget = _budgets.firstWhere((b) => b.id == id);
    if (budget != null) {
      _currentBudget = budget;
      notifyListeners();
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  BudgetModel? getBudgetByMonth(int month, int year) {
    try {
      return _budgets.firstWhere((b) => b.month == month && b.year == year);
    } catch (_) {
      return null;
    }
  }

  List<BudgetModel> getActiveBudgets() {
    return _budgets.where((b) => b.isActive).toList();
  }

  double getCategoryBudget(String category) {
    if (_currentBudget == null) return 0.0;
    final categoryBudget = _currentBudget!.getCategoryByName(category);
    return categoryBudget?.allocated ?? 0.0;
  }

  double getCategorySpent(String category) {
    if (_currentBudget == null) return 0.0;
    final categoryBudget = _currentBudget!.getCategoryByName(category);
    return categoryBudget?.spent ?? 0.0;
  }

  double getCategoryRemaining(String category) {
    if (_currentBudget == null) return 0.0;
    final categoryBudget = _currentBudget!.getCategoryByName(category);
    return categoryBudget?.remaining ?? 0.0;
  }

  bool isCategoryOverBudget(String category) {
    if (_currentBudget == null) return false;
    final categoryBudget = _currentBudget!.getCategoryByName(category);
    return categoryBudget?.isOverBudget ?? false;
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
}
