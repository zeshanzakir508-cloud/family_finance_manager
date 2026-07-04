// lib/providers/family_provider.dart
import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../models/transaction_model.dart';

class FamilyProvider extends ChangeNotifier {
  List<FamilyModel> _families = []; // ✅ Changed: Family → FamilyModel
  List<TransactionModel> _personalTransactions = [];
  List<TransactionModel> _familyTransactions = [];
  FamilyModel? _currentFamily; // ✅ Changed: Family → FamilyModel

  List<FamilyModel> get families => _families; // ✅ Changed: Family → FamilyModel
  List<TransactionModel> get personalTransactions => _personalTransactions;
  List<TransactionModel> get familyTransactions => _familyTransactions;
  FamilyModel? get currentFamily => _currentFamily; // ✅ Changed: Family → FamilyModel

  // Method to refresh data
  Future<void> refreshData() async {
    // TODO: Implement actual data refresh from Firebase
    notifyListeners();
  }

  // Get family members
  List<FamilyMember> getFamilyMembers() {
    if (_currentFamily == null) return [];
    return _currentFamily!.members ?? [];
  }

  // Add transaction methods
  void addPersonalTransaction(TransactionModel transaction) {
    _personalTransactions.add(transaction);
    notifyListeners();
  }

  void addFamilyTransaction(TransactionModel transaction) {
    _familyTransactions.add(transaction);
    notifyListeners();
  }

  // Family management methods
  void createFamily(FamilyModel family) { // ✅ Changed: Family → FamilyModel
    _families.add(family);
    _currentFamily = family;
    notifyListeners();
  }

  void setCurrentFamily(FamilyModel family) { // ✅ Changed: Family → FamilyModel
    _currentFamily = family;
    notifyListeners();
  }

  // Remove family
  void removeFamily(String familyId) {
    _families.removeWhere((f) => f.id == familyId);
    if (_currentFamily?.id == familyId) {
      _currentFamily = _families.isNotEmpty ? _families.first : null;
    }
    notifyListeners();
  }

  // Update family
  void updateFamily(FamilyModel family) { // ✅ Changed: Family → FamilyModel
    final index = _families.indexWhere((f) => f.id == family.id);
    if (index != -1) {
      _families[index] = family;
      if (_currentFamily?.id == family.id) {
        _currentFamily = family;
      }
      notifyListeners();
    }
  }

  // Clear all data (on logout)
  void clearData() {
    _families.clear();
    _personalTransactions.clear();
    _familyTransactions.clear();
    _currentFamily = null;
    notifyListeners();
  }
}
