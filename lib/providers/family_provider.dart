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

  // Get count of families created by user (where user is admin)
  int getCreatedFamiliesCount(String userId) {
    return _families.where((f) => f.adminId == userId).length;
  }

  // Get count of families joined by user (where user is member but not admin)
  int getJoinedFamiliesCount(String userId) {
    return _families.where((f) => 
      f.adminId != userId && (f.memberIds?.contains(userId) ?? false)
    ).length;
  }

  // Check if user can create a new family
  bool canUserCreateFamily(String userId) {
    final createdCount = getCreatedFamiliesCount(userId);
    return AppConfig.canCreateFamily(createdCount);
  }

  // Check if user can join a new family
  bool canUserJoinFamily(String userId) {
    final joinedCount = getJoinedFamiliesCount(userId);
    return AppConfig.canJoinFamily(joinedCount);
  }

  // Get remaining limits
  int getRemainingCreateLimit(String userId) {
    final createdCount = getCreatedFamiliesCount(userId);
    return AppConfig.maxFamiliesCreated - createdCount;
  }

  int getRemainingJoinLimit(String userId) {
    final joinedCount = getJoinedFamiliesCount(userId);
    return AppConfig.maxFamiliesJoined - joinedCount;
  }

  // Check if user is already in a family
  bool isUserInFamily(String userId, String familyId) {
    final family = _families.firstWhere(
      (f) => f.id == familyId,
      orElse: () => throw Exception('Family not found'),
    );
    return family.memberIds?.contains(userId) ?? false;
  }

  // Check if family can add more members
  bool canFamilyAddMember(String familyId) {
    final family = _families.firstWhere(
      (f) => f.id == familyId,
      orElse: () => throw Exception('Family not found'),
    );
    final currentCount = family.memberIds?.length ?? 0;
    return AppConfig.canAddMember(currentCount);
  }

  // Get remaining member slots
  int getRemainingMemberSlots(String familyId) {
    final family = _families.firstWhere(
      (f) => f.id == familyId,
      orElse: () => throw Exception('Family not found'),
    );
    final currentCount = family.memberIds?.length ?? 0;
    return AppConfig.maxMembersPerFamily - currentCount;
  }

  Future<void> createFamily(String name, String userId, {String? description}) async {
    // Check if user can create more families
    if (!canUserCreateFamily(userId)) {
      final remaining = getRemainingCreateLimit(userId);
      throw Exception('You have reached the maximum limit of ${AppConfig.maxFamiliesCreated} families you can create. You can create $remaining more.');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      
      setState(() {
        _isLoading = false;
      });
      notifyListeners();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      rethrow;
    }
  }

  Future<void> joinFamily(String familyCode, String userId) async {
    // Check if user can join more families
    if (!canUserJoinFamily(userId)) {
      final remaining = getRemainingJoinLimit(userId);
      throw Exception('You have reached the maximum limit of ${AppConfig.maxFamiliesJoined} families you can join. You can join $remaining more.');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      // Check if already a member
      if (targetFamily.memberIds?.contains(userId) ?? false) {
        throw Exception('You are already a member of this family');
      }

      // Check if family is full
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
      
      setState(() {
        _isLoading = false;
      });
      notifyListeners();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      rethrow;
    }
  }

  Future<void> leaveFamily(String userId) async {
    if (_currentFamily == null) return;

    // Check if user is admin
    if (_currentFamily!.adminId == userId) {
      throw Exception('You are the admin. Please transfer admin role to another member or delete the family.');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      
      setState(() {
        _isLoading = false;
      });
      notifyListeners();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      rethrow;
    }
  }

  Future<void> deleteFamily() async {
    if (_currentFamily == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _currentFamily!.delete();
      _currentFamily = null;
      _loadFamilies();
      
      setState(() {
        _isLoading = false;
      });
      notifyListeners();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedFamily = _currentFamily!.copyWith(
        adminId: newAdminId,
      );
      await updatedFamily.save();
      _currentFamily = updatedFamily;
      
      setState(() {
        _isLoading = false;
      });
      notifyListeners();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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

  void _setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  bool get isAdmin {
    if (_currentFamily == null) return false;
    final authService = Provider.of<AuthService>(navigatorKey.currentContext!, listen: false);
    return _currentFamily!.adminId == authService.userId;
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

// Global navigator key for accessing context in providers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
