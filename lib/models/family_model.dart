// lib/models/family_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'family_model.g.dart';

// ==================== FAMILY MEMBER MODEL ====================

@HiveType(typeId: 0)
class FamilyMember extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String displayName;
  
  @HiveField(3)
  final String email;
  
  @HiveField(4)
  final String role; // admin, member
  
  @HiveField(5)
  final DateTime joinedAt;
  
  @HiveField(6)
  final bool isActive;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.email,
    this.role = 'member',
    required this.joinedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Unknown',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  FamilyMember copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? email,
    String? role,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ==================== FAMILY SETTINGS MODEL ====================

@HiveType(typeId: 1)
class FamilySettings extends HiveObject {
  @HiveField(0)
  final String currency;
  
  @HiveField(1)
  final bool allowMembersToAdd;
  
  @HiveField(2)
  final bool requireApproval;

  FamilySettings({
    this.currency = 'USD',
    this.allowMembersToAdd = true,
    this.requireApproval = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'allowMembersToAdd': allowMembersToAdd,
      'requireApproval': requireApproval,
    };
  }

  factory FamilySettings.fromJson(Map<String, dynamic> json) {
    return FamilySettings(
      currency: json['currency'] ?? 'USD',
      allowMembersToAdd: json['allowMembersToAdd'] ?? true,
      requireApproval: json['requireApproval'] ?? true,
    );
  }
}

// ==================== FAMILY MODEL ====================

@HiveType(typeId: 2)
class FamilyModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final String createdBy;
  
  @HiveField(4)
  final String? familyCode;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final List<FamilyMember>? members;
  
  @HiveField(7)
  final FamilySettings settings;
  
  @HiveField(8)
  final DateTime? updatedAt;

  // ✅ ADDED: memberIds field for efficient querying
  @HiveField(9)
  final List<String>? memberIds;

  FamilyModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.familyCode,
    required this.createdAt,
    this.members,
    FamilySettings? settings,
    this.updatedAt,
    this.memberIds,
  }) : settings = settings ?? FamilySettings();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'familyCode': familyCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'members': members?.map((m) => m.toJson()).toList() ?? [],
      'settings': settings.toJson(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'memberIds': memberIds ?? members?.map((m) => m.userId).toList() ?? [],
    };
  }

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Family',
      description: json['description'],
      createdBy: json['createdBy'] ?? '',
      familyCode: json['familyCode'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      members: json['members'] != null
          ? (json['members'] as List).map((m) => FamilyMember.fromJson(m)).toList()
          : [],
      settings: json['settings'] != null
          ? FamilySettings.fromJson(json['settings'])
          : FamilySettings(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      memberIds: json['memberIds'] != null
          ? List<String>.from(json['memberIds'])
          : null,
    );
  }

  FamilyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    String? familyCode,
    DateTime? createdAt,
    List<FamilyMember>? members,
    FamilySettings? settings,
    DateTime? updatedAt,
    List<String>? memberIds,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      familyCode: familyCode ?? this.familyCode,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
