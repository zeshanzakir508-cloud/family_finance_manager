// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/currency_service.dart';
import 'auth_provider.dart';
import 'family_provider.dart';
import 'mode_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final CurrencyService _currencyService = CurrencyService();
  
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;
  String? _error;
  
  String? _filterCategory;
  String? _filterType;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _searchQuery;

  TransactionProvider({
    AuthProvider? authProvider,
    FamilyProvider? familyProvider,
    ModeProvider? modeProvider,
  }) {
    if (authProvider != null && authProvider.isAuthenticated) {
      loadTransactions(authProvider.userId);
    }
  }

  // ============================================================
  // GETTERS
  // ============================================================

  List<TransactionModel> get transactions => _filteredTransactions;
  List<TransactionModel> get allTransactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
  }
  
  double get totalExpense {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
  }
  
  double get balance {
    return totalIncome - totalExpense;
  }

  int get transactionCount => _filteredTransactions.length;

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadTransactions(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await _transactionService.getTransactionsByUser(userId);
      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> loadFamilyTransactions(String familyId) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await _transactionService.getTransactionsByFamily(familyId);
      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshTransactions(String userId) async {
    await loadTransactions(userId);
  }

  // ============================================================
  // CRUD
  // ============================================================

  Future<bool> addTransaction(TransactionModel transaction) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _transactionService.addTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);
      _transactions.insert(0, newTransaction);
      _applyFilters();
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

  Future<bool> updateTransaction(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await _transactionService.updateTransaction(id, data);
      
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        final updated = _transactions[index].copyWith(
          description: data['description'] ?? _transactions[index].description,
          amount: data['amount'] ?? _transactions[index].amount,
          category: data['category'] ?? _transactions[index].category,
          type: data['type'] ?? _transactions[index].type,
          date: data['date'] ?? _transactions[index].date,
          notes: data['notes'] ?? _transactions[index].notes,
        );
        _transactions[index] = updated;
        _applyFilters();
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

  Future<bool> deleteTransaction(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _transactionService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      _applyFilters();
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
  // FILTERS
  // ============================================================

  void setCategoryFilter(String? category) {
    _filterCategory = category;
    _applyFilters();
  }

  void setTypeFilter(String? type) {
    _filterType = type;
    _applyFilters();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    _applyFilters();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    _applyFilters();
  }

  void clearFilters() {
    _filterCategory = null;
    _filterType = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = null;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((t) {
      // Category filter
      if (_filterCategory != null && _filterCategory!.isNotEmpty) {
        if (t.category != _filterCategory) return false;
      }
      
      // Type filter
      if (_filterType != null && _filterType!.isNotEmpty) {
        if (_filterType == 'income' && !t.isIncome) return false;
        if (_filterType == 'expense' && !t.isExpense) return false;
        if (_filterType == 'transfer' && !t.isTransfer) return false;
      }
      
      // Date range filter
      if (_filterStartDate != null && t.date != null) {
        if (t.date!.isBefore(_filterStartDate!)) return false;
      }
      if (_filterEndDate != null && t.date != null) {
        if (t.date!.isAfter(_filterEndDate!)) return false;
      }
      
      // Search query
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        final matchesDescription = t.description?.toLowerCase().contains(query) ?? false;
        final matchesCategory = t.category?.toLowerCase().contains(query) ?? false;
        final matchesNotes = t.notes?.toLowerCase().contains(query) ?? false;
        if (!matchesDescription && !matchesCategory && !matchesNotes) return false;
      }
      
      return true;
    }).toList();
    
    // Sort by date (newest first)
    _filteredTransactions.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });
    
    notifyListeners();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Map<String, double> getCategorySummary() {
    final summary = <String, double>{};
    for (var t in _filteredTransactions) {
      if (t.isExpense) {
        final category = t.category ?? 'Other';
        summary[category] = (summary[category] ?? 0.0) + (t.amount ?? 0.0);
      }
    }
    return summary;
  }

  Map<String, Map<String, double>> getMonthlySummary() {
    final summary = <String, Map<String, double>>{};
    for (var t in _transactions) {
      if (t.date == null) continue;
      final key = '${t.date!.year}-${t.date!.month.toString().padLeft(2, '0')}';
      if (!summary.containsKey(key)) {
        summary[key] = {'income': 0.0, 'expense': 0.0};
      }
      if (t.isIncome) {
        summary[key]!['income'] = (summary[key]!['income'] ?? 0.0) + (t.amount ?? 0.0);
      } else if (t.isExpense) {
        summary[key]!['expense'] = (summary[key]!['expense'] ?? 0.0) + (t.amount ?? 0.0);
      }
    }
    return summary;
  }

  Map<String, double> getMonthlyBalance() {
    final summary = getMonthlySummary();
    final balance = <String, double>{};
    for (var entry in summary.entries) {
      balance[entry.key] = (entry.value['income'] ?? 0.0) - (entry.value['expense'] ?? 0.0);
    }
    return balance;
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
