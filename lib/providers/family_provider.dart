import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class FamilyProvider extends ChangeNotifier {
  FamilyModel? _currentFamily;
  List<FamilyModel> _families = [];
  List<UserModel> _familyMembers = [];

  FamilyProvider() {
    _loadFamilies();
  }

  FamilyModel? get currentFamily => _currentFamily;
  List<FamilyModel> get families => _families;
  List<UserModel> get familyMembers => _familyMembers;
  int get memberCount => _familyMembers.length;
  bool get hasFamily => _currentFamily != null;

  void _loadFamilies() {
    final box = Hive.box<FamilyModel>('families');
    _families = box.values.toList();
    
    if (_families.isNotEmpty && _currentFamily == null) {
      _currentFamily = _families.first;
      _loadFamilyMembers();
    }
    notifyListeners();
  }

  void _loadFamilyMembers() {
    if (_currentFamily == null) return;
    final userBox = Hive.box<UserModel>('users');
    _familyMembers = _currentFamily!.memberIds
        ?.map((id) => userBox.get(id))
        .where((user) => user != null)
        .cast<UserModel>()
        .toList() ?? [];
    notifyListeners();
  }

  Future<void> createFamily(String name, String userId, {String? description}) async {
    final family = FamilyModel(
      id: Helpers.generateId(),
      name: name,
      description: description,
      adminId: userId,
      memberIds: [userId],
      createdAt: DateTime.now(),
      familyCode: Helpers.generateFamilyCode(),
    );

    final box = Hive.box<FamilyModel>('families');
    await box.add(family);
    
    _families = box.values.toList();
    _currentFamily = family;
    _loadFamilyMembers();
    notifyListeners();
  }

  Future<void> joinFamily(String familyCode, String userId) async {
    final box = Hive.box<FamilyModel>('families');
    FamilyModel? targetFamily;
    
    for (var family in box.values) {
      if (family.familyCode == familyCode) {
        targetFamily = family;
        break;
      }
    }

    if (targetFamily == null) {
      throw Exception('Invalid family code');
    }

    int memberCount = targetFamily.memberIds?.length ?? 0;
    if (memberCount >= Constants.maxFamilyMembers) {
      throw Exception('Family is full (max ${Constants.maxFamilyMembers} members)');
    }

    if (targetFamily.memberIds?.contains(userId) ?? false) {
      throw Exception('Already a member of this family');
    }

    final updatedFamily = targetFamily.copyWith(
      memberIds: [...?targetFamily.memberIds, userId],
    );
    await updatedFamily.save();
    
    _currentFamily = updatedFamily;
    _loadFamilies();
    notifyListeners();
  }

  Future<void> leaveFamily(String userId) async {
    if (_currentFamily == null) return;

    final updatedFamily = _currentFamily!.copyWith(
      memberIds: _currentFamily!.memberIds?.where((id) => id != userId).toList(),
    );
    await updatedFamily.save();

    if (updatedFamily.memberIds?.isEmpty ?? true) {
      await updatedFamily.delete();
    }

    _currentFamily = null;
    _loadFamilies();
    notifyListeners();
  }

  Future<void> deleteFamily() async {
    if (_currentFamily == null) return;
    await _currentFamily!.delete();
    _currentFamily = null;
    _loadFamilies();
    notifyListeners();
  }

  void setCurrentFamily(String familyId) {
    final box = Hive.box<FamilyModel>('families');
    final family = box.values.firstWhere(
      (f) => f.id == familyId,
      orElse: () => throw Exception('Family not found'),
    );
    _currentFamily = family;
    _loadFamilyMembers();
    notifyListeners();
  }

  bool get isAdmin {
    if (_currentFamily == null) return false;
    // Return true only if user is admin - will be checked in UI
    return true;
  }

  // Get member by ID
  UserModel? getMember(String memberId) {
    final userBox = Hive.box<UserModel>('users');
    return userBox.get(memberId);
  }

  // Get member name by ID
  String getMemberName(String memberId) {
    final user = getMember(memberId);
    return user?.displayName ?? 'Unknown';
  }

  // Check if user is admin
  bool isUserAdmin(String userId) {
    if (_currentFamily == null) return false;
    return _currentFamily!.adminId == userId;
  }
}
