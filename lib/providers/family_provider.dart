import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/app_config.dart';

class FamilyProvider extends ChangeNotifier {
  FamilyModel? _currentFamily;
  List<FamilyModel> _families = [];
  List<UserModel> _familyMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  FamilyProvider() {
    _loadFamilies();
  }

  FamilyModel? get currentFamily => _currentFamily;
  List<FamilyModel> get families => _families;
  List<UserModel> get familyMembers => _familyMembers;
  int get memberCount => _familyMembers.length;
  bool get hasFamily => _currentFamily != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  int getCreatedFamiliesCount(String userId) {
    return _families.where((f) => f.adminId == userId).length;
  }

  int getJoinedFamiliesCount(String userId) {
    return _families.where((f) => 
      f.adminId != userId && (f.memberIds?.contains(userId) ?? false)
    ).length;
  }

  bool canUserCreateFamily(String userId) {
    final createdCount = getCreatedFamiliesCount(userId);
    return AppConfig.canCreateFamily(createdCount);
  }

  bool canUserJoinFamily(String userId) {
    final joinedCount = getJoinedFamiliesCount(userId);
    return AppConfig.canJoinFamily(joinedCount);
  }

  int getRemainingCreateLimit(String userId) {
    final createdCount = getCreatedFamiliesCount(userId);
    return AppConfig.maxFamiliesCreated - createdCount;
  }

  int getRemainingJoinLimit(String userId) {
    final joinedCount = getJoinedFamiliesCount(userId);
    return AppConfig.maxFamiliesJoined - joinedCount;
  }

  bool isUserInFamily(String userId, String familyId) {
    final family = _families.firstWhere(
      (f) => f.id == familyId,
      orElse: () => throw Exception('Family not found'),
    );
    return family.memberIds?.contains(userId) ?? false;
  }

  bool canFamilyAddMember(String familyId) {
    final family = _families.firstWhere(
      (f) => f.id == familyId,
      orElse: () => throw Exception('Family not found'),
    );
    final currentCount = family.memberIds?.length ?? 0;
    return AppConfig.canAddMember(currentCount);
  }

  int getRemainingMemberSlots(String familyId) {
    final family = _families.firstWhere(
      (f) => f.id == familyId,
      orElse: () => throw Exception('Family not found'),
    );
    final currentCount = family.memberIds?.length ?? 0;
    return AppConfig.maxMembersPerFamily - currentCount;
  }

  Future<void> createFamily(String name, String userId, {String? description}) async {
    if (!canUserCreateFamily(userId)) {
      final remaining = getRemainingCreateLimit(userId);
      throw Exception('You have reached the maximum limit of ${AppConfig.maxFamiliesCreated} families you can create. You can create $remaining more.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
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
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinFamily(String familyCode, String userId) async {
    if (!canUserJoinFamily(userId)) {
      final remaining = getRemainingJoinLimit(userId);
      throw Exception('You have reached the maximum limit of ${AppConfig.maxFamiliesJoined} families you can join. You can join $remaining more.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
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

      if (targetFamily.memberIds?.contains(userId) ?? false) {
        throw Exception('You are already a member of this family');
      }

      if (!canFamilyAddMember(targetFamily.id!)) {
        final remaining = getRemainingMemberSlots(targetFamily.id!);
        throw Exception('This family is full (max ${AppConfig.maxMembersPerFamily} members). $remaining slots remaining.');
      }

      final updatedFamily = targetFamily.copyWith(
        memberIds: [...?targetFamily.memberIds, userId],
      );
      await updatedFamily.save();
      
      _currentFamily = updatedFamily;
      _loadFamilies();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveFamily(String userId) async {
    if (_currentFamily == null) return;

    if (_currentFamily!.adminId == userId) {
      throw Exception('You are the admin. Please transfer admin role to another member or delete the family.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedFamily = _currentFamily!.copyWith(
        memberIds: _currentFamily!.memberIds?.where((id) => id != userId).toList(),
      );
      await updatedFamily.save();

      if (updatedFamily.memberIds?.isEmpty ?? true) {
        await updatedFamily.delete();
      }

      _currentFamily = null;
      _loadFamilies();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFamily() async {
    if (_currentFamily == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _currentFamily!.delete();
      _currentFamily = null;
      _loadFamilies();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> transferAdmin(String currentUserId, String newAdminId) async {
    if (_currentFamily == null) return;

    if (_currentFamily!.adminId != currentUserId) {
      throw Exception('Only the admin can transfer admin rights.');
    }

    if (!(_currentFamily!.memberIds?.contains(newAdminId) ?? false)) {
      throw Exception('The new admin must be a member of the family.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedFamily = _currentFamily!.copyWith(
        adminId: newAdminId,
      );
      await updatedFamily.save();
      _currentFamily = updatedFamily;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
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
    return true;
  }

  bool isUserAdmin(String userId) {
    if (_currentFamily == null) return false;
    return _currentFamily!.adminId == userId;
  }

  UserModel? getMember(String memberId) {
    final userBox = Hive.box<UserModel>('users');
    return userBox.get(memberId);
  }

  String getMemberName(String memberId) {
    final user = getMember(memberId);
    return user?.displayName ?? 'Unknown';
  }
}
