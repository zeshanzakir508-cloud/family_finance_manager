// lib/models/family_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== FAMILY MEMBER MODEL ====================

class FamilyMember {
  final String id;
  final String userId;
  final String displayName;
  final String email;
  final String role; // admin, member
  final DateTime joinedAt;
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

class FamilySettings {
  final String currency;
  final bool allowMembersToAdd;
  final bool requireApproval;

  const FamilySettings({
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

class Family {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String? familyCode;
  final DateTime createdAt;
  final List<FamilyMember>? members;
  final FamilySettings settings;
  final DateTime? updatedAt;

  Family({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.familyCode,
    required this.createdAt,
    this.members,
    this.settings = const FamilySettings(),
    this.updatedAt,
  });

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
    };
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
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
          : const FamilySettings(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Family copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    String? familyCode,
    DateTime? createdAt,
    List<FamilyMember>? members,
    FamilySettings? settings,
    DateTime? updatedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      familyCode: familyCode ?? this.familyCode,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
