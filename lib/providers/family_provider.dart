// lib/providers/family_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADDED
import '../models/family_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart'; // ✅ ADDED

class FamilyProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService(); // ✅ ADDED
  
  List<FamilyModel> _families = [];
  final List<TransactionModel> _personalTransactions = [];
  final List<TransactionModel> _familyTransactions = [];
  FamilyModel? _currentFamily;
  bool _isLoading = false;
  String? _error; // ✅ ADDED

  List<FamilyModel> get families => _families;
  List<TransactionModel> get personalTransactions => _personalTransactions;
  List<TransactionModel> get familyTransactions => _familyTransactions;
  FamilyModel? get currentFamily => _currentFamily;
  bool get isLoading => _isLoading;
  String? get error => _error; // ✅ ADDED

  // ✅ ADDED: Load families from Firestore
  Future<void> loadFamilies(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('families')
          .where('memberIds', arrayContains: userId)
          .get();

      _families = snapshot.docs
          .map((doc) => FamilyModel.fromJson(doc.data()))
          .toList();

      if (_families.isNotEmpty && _currentFamily == null) {
        _currentFamily = _families.first;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ✅ ADDED: Load family by ID
  Future<void> loadFamilyById(String familyId) async {
    _setLoading(true);
    _clearError();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .get();

      if (doc.exists) {
        _currentFamily = FamilyModel.fromJson(doc.data()!);
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ✅ ADDED: Create family in Firestore
  Future<String?> createFamilyInFirestore(FamilyModel family) async {
    _setLoading(true);
    _clearError();

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('families')
          .add(family.toJson());
      
      final newFamily = family.copyWith(id: docRef.id);
      _families.add(newFamily);
      _currentFamily = newFamily;
      
      _setLoading(false);
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // ✅ ADDED: Update family in Firestore
  Future<bool> updateFamilyInFirestore(String familyId, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .update(data);

      final index = _families.indexWhere((f) => f.id == familyId);
      if (index != -1) {
        _families[index] = _families[index].copyWith(
          name: data['name'] ?? _families[index].name,
          description: data['description'] ?? _families[index].description,
          settings: data['settings'] ?? _families[index].settings,
        );
        if (_currentFamily?.id == familyId) {
          _currentFamily = _families[index];
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

  // ✅ ADDED: Delete family from Firestore
  Future<bool> deleteFamilyFromFirestore(String familyId) async {
    _setLoading(true);
    _clearError();

    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .delete();

      _families.removeWhere((f) => f.id == familyId);
      if (_currentFamily?.id == familyId) {
        _currentFamily = _families.isNotEmpty ? _families.first : null;
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

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  List<FamilyMember> getFamilyMembers() {
    if (_currentFamily == null) return [];
    return _currentFamily!.members;
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
    _isLoading = false;
    _error = null;
    notifyListeners();
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
