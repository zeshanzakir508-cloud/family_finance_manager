// lib/providers/family_provider.dart
import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../models/transaction_model.dart';

class FamilyProvider extends ChangeNotifier {
  List<FamilyModel> _families = [];
  List<TransactionModel> _personalTransactions = [];
  List<TransactionModel> _familyTransactions = [];
  FamilyModel? _currentFamily;

  List<FamilyModel> get families => _families;
  List<TransactionModel> get personalTransactions => _personalTransactions;
  List<TransactionModel> get familyTransactions => _familyTransactions;
  FamilyModel? get currentFamily => _currentFamily;

  // ✅ ADDED: setFamilies method
  void setFamilies(List<FamilyModel> families) {
    _families = families;
    if (_currentFamily == null && families.isNotEmpty) {
      _currentFamily = families.first;
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    notifyListeners();
  }

  List<FamilyMember> getFamilyMembers() {
    if (_currentFamily == null) return [];
    return _currentFamily!.members ?? [];
  }

  void addPersonalTransaction(TransactionModel transaction) {
    _personalTransactions.add(transaction);
    notifyListeners();
  }

  void addFamilyTransaction(TransactionModel transaction) {
    _familyTransactions.add(transaction);
    notifyListeners();
  }

  void createFamily(FamilyModel family) {
    _families.add(family);
    _currentFamily = family;
    notifyListeners();
  }

  void setCurrentFamily(FamilyModel family) {
    _currentFamily = family;
    notifyListeners();
  }

  void removeFamily(String familyId) {
    _families.removeWhere((f) => f.id == familyId);
    if (_currentFamily?.id == familyId) {
      _currentFamily = _families.isNotEmpty ? _families.first : null;
    }
    notifyListeners();
  }

  void updateFamily(FamilyModel family) {
    final index = _families.indexWhere((f) => f.id == family.id);
    if (index != -1) {
      _families[index] = family;
      if (_currentFamily?.id == family.id) {
        _currentFamily = family;
      }
      notifyListeners();
    }
  }

  void clearData() {
    _families.clear();
    _personalTransactions.clear();
    _familyTransactions.clear();
    _currentFamily = null;
    notifyListeners();
  }
}
