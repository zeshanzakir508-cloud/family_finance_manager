// lib/providers/goal_provider.dart
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/goal_service.dart';

class GoalProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();
  
  List<GoalModel> _goals = [];
  List<GoalModel> _completedGoals = [];
  GoalModel? _currentGoal;
  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<GoalModel> get goals => _goals;
  List<GoalModel> get completedGoals => _completedGoals;
  GoalModel? get currentGoal => _currentGoal;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeGoalsCount => _goals.length;
  int get completedGoalsCount => _completedGoals.length;
  
  double get totalSaved {
    double total = 0.0;
    for (var goal in _goals) {
      total += goal.currentAmount ?? 0.0;
    }
    for (var goal in _completedGoals) {
      total += goal.currentAmount ?? 0.0;
    }
    return total;
  }

  double get totalTarget {
    double total = 0.0;
    for (var goal in _goals) {
      total += goal.targetAmount ?? 0.0;
    }
    for (var goal in _completedGoals) {
      total += goal.targetAmount ?? 0.0;
    }
    return total;
  }

  double get overallProgress {
    if (totalTarget == 0) return 0.0;
    return (totalSaved / totalTarget).clamp(0.0, 1.0);
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadGoals(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _goals = await _goalService.getGoalsByUser(userId);
      _completedGoals = await _goalService.getCompletedGoalsByUser(userId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> loadFamilyGoals(String familyId) async {
    _setLoading(true);
    _clearError();

    try {
      _goals = await _goalService.getGoalsByFamily(familyId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshGoals(String userId) async {
    await loadGoals(userId);
  }

  // ============================================================
  // CRUD
  // ============================================================

  Future<bool> createGoal(GoalModel goal) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _goalService.createGoal(goal);
      final newGoal = goal.copyWith(id: id);
      _goals.add(newGoal);
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

  Future<bool> updateGoal(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await _goalService.updateGoal(id, data);
      
      // Update in lists
      _updateGoalInList(id, data);
      
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

  Future<bool> addContribution(String goalId, double amount, {String? note}) async {
    _setLoading(true);
    _clearError();

    try {
      await _goalService.addContribution(goalId, amount, note: note);
      
      // Refresh to get updated goal
      await _refreshGoal(goalId);
      
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

  Future<bool> removeContribution(String goalId, String contributionId) async {
    _setLoading(true);
    _clearError();

    try {
      await _goalService.removeContribution(goalId, contributionId);
      
      // Refresh to get updated goal
      await _refreshGoal(goalId);
      
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

  Future<bool> deleteGoal(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _goalService.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      _completedGoals.removeWhere((g) => g.id == id);
      if (_currentGoal?.id == id) {
        _currentGoal = null;
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
  // SET CURRENT
  // ============================================================

  void setCurrentGoal(GoalModel goal) {
    _currentGoal = goal;
    notifyListeners();
  }

  // ✅ FIXED: Removed redundant null check
  void setCurrentGoalById(String id) {
    try {
      final goal = _goals.firstWhere((g) => g.id == id);
      _currentGoal = goal;
      notifyListeners();
    } catch (_) {
      // Goal not found, do nothing
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<GoalModel> getOverdueGoals() {
    return _goals.where((g) => g.isOverdue).toList();
  }

  List<GoalModel> getOnTrackGoals() {
    return _goals.where((g) => g.isOnTrack).toList();
  }

  List<GoalModel> getGoalsByCategory(String category) {
    return _goals.where((g) => g.category == category).toList();
  }

  double getCategoryProgress(String category) {
    final categoryGoals = getGoalsByCategory(category);
    if (categoryGoals.isEmpty) return 0.0;
    
    double totalTarget = 0.0;
    double totalCurrent = 0.0;
    
    for (var goal in categoryGoals) {
      totalTarget += goal.targetAmount ?? 0.0;
      totalCurrent += goal.currentAmount ?? 0.0;
    }
    
    if (totalTarget == 0) return 0.0;
    return (totalCurrent / totalTarget).clamp(0.0, 1.0);
  }

  Map<String, double> getCategoryProgressMap() {
    final categories = <String, double>{};
    final allGoals = [..._goals, ..._completedGoals];
    
    for (var goal in allGoals) {
      final category = goal.category ?? 'Other';
      if (!categories.containsKey(category)) {
        categories[category] = 0.0;
      }
      categories[category] = (categories[category] ?? 0.0) + (goal.currentAmount ?? 0.0);
    }
    
    return categories;
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

  void _updateGoalInList(String id, Map<String, dynamic> data) {
    // Update in active goals
    final activeIndex = _goals.indexWhere((g) => g.id == id);
    if (activeIndex != -1) {
      _goals[activeIndex] = _goals[activeIndex].copyWith(
        name: data['name'] ?? _goals[activeIndex].name,
        targetAmount: data['targetAmount'] ?? _goals[activeIndex].targetAmount,
        currentAmount: data['currentAmount'] ?? _goals[activeIndex].currentAmount,
        deadline: data['deadline'] ?? _goals[activeIndex].deadline,
        category: data['category'] ?? _goals[activeIndex].category,
        isCompleted: data['isCompleted'] ?? _goals[activeIndex].isCompleted,
      );
      
      // Move to completed if completed
      if (_goals[activeIndex].isAchieved) {
        _completedGoals.add(_goals[activeIndex]);
        _goals.removeAt(activeIndex);
      }
    }
    
    // Update in completed goals
    final completedIndex = _completedGoals.indexWhere((g) => g.id == id);
    if (completedIndex != -1) {
      _completedGoals[completedIndex] = _completedGoals[completedIndex].copyWith(
        name: data['name'] ?? _completedGoals[completedIndex].name,
        targetAmount: data['targetAmount'] ?? _completedGoals[completedIndex].targetAmount,
        currentAmount: data['currentAmount'] ?? _completedGoals[completedIndex].currentAmount,
      );
    }
    
    if (_currentGoal?.id == id) {
      final updated = _goals.firstWhere((g) => g.id == id);
      _currentGoal = updated;
    }
  }

  Future<void> _refreshGoal(String goalId) async {
    final goal = await _goalService.getGoalById(goalId);
    if (goal != null) {
      // Remove from both lists
      _goals.removeWhere((g) => g.id == goalId);
      _completedGoals.removeWhere((g) => g.id == goalId);
      
      // Add to appropriate list
      if (goal.isAchieved) {
        _completedGoals.add(goal);
      } else {
        _goals.add(goal);
      }
      
      if (_currentGoal?.id == goalId) {
        _currentGoal = goal;
      }
    }
  }
}
