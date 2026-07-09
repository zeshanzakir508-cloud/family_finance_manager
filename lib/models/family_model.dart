// lib/models/family_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

// ✅ FIXED: Uncommented part directive for build_runner
part 'family_model.g.dart';

// ==================== FAMILY SETTINGS ====================

@HiveType(typeId: 5)
class FamilySettings extends HiveObject {
  @HiveField(0)
  final String? currency;

  @HiveField(1)
  final String? language;

  @HiveField(2)
  final bool? allowMemberInvites;

  @HiveField(3)
  final bool? requireApprovalForTransfers;

  @HiveField(4)
  final bool? showMemberBalances;

  FamilySettings({
    this.currency = 'USD',
    this.language = 'en',
    this.allowMemberInvites = true,
    this.requireApprovalForTransfers = false,
    this.showMemberBalances = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'language': language,
      'allowMemberInvites': allowMemberInvites,
      'requireApprovalForTransfers': requireApprovalForTransfers,
      'showMemberBalances': showMemberBalances,
    };
  }

  factory FamilySettings.fromJson(Map<String, dynamic> json) {
    return FamilySettings(
      currency: json['currency'] ?? 'USD',
      language: json['language'] ?? 'en',
      allowMemberInvites: json['allowMemberInvites'] ?? true,
      requireApprovalForTransfers: json['requireApprovalForTransfers'] ?? false,
      showMemberBalances: json['showMemberBalances'] ?? true,
    );
  }

  FamilySettings copyWith({
    String? currency,
    String? language,
    bool? allowMemberInvites,
    bool? requireApprovalForTransfers,
    bool? showMemberBalances,
  }) {
    return FamilySettings(
      currency: currency ?? this.currency,
      language: language ?? this.language,
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
      requireApprovalForTransfers: requireApprovalForTransfers ?? this.requireApprovalForTransfers,
      showMemberBalances: showMemberBalances ?? this.showMemberBalances,
    );
  }
}

// ==================== FAMILY MEMBER ====================

@HiveType(typeId: 6)
class FamilyMember extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final String? phoneNumber;

  @HiveField(4)
  final String? photoUrl;

  @HiveField(5)
  final String role; // 'admin', 'member', 'viewer'

  @HiveField(6)
  final DateTime joinedAt;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final double? balance; // Optional: member's balance in family

  // ✅ FIXED: Removed 'id' parameter - using 'userId' as the identifier
  FamilyMember({
    required this.userId,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.role = 'member',
    required this.joinedAt,
    this.isActive = true,
    this.balance,
  });

  bool get isAdmin => role == 'admin';
  bool get isViewer => role == 'viewer';

  // ✅ ADDED: 'id' getter for backward compatibility
  String get id => userId;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'balance': balance,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Unknown',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
      role: json['role'] ?? 'member',
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      balance: (json['balance'] as num?)?.toDouble(),
    );
  }

  FamilyMember copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    DateTime? joinedAt,
    bool? isActive,
    double? balance,
  }) {
    return FamilyMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      balance: balance ?? this.balance,
    );
  }
}

// ==================== FAMILY MODEL ====================

@HiveType(typeId: 7)
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
  final DateTime createdAt;

  @HiveField(5)
  final String? familyCode;

  @HiveField(6)
  final FamilySettings settings;

  @HiveField(7)
  final List<FamilyMember> members;

  @HiveField(8)
  final List<String> memberIds;

  @HiveField(9)
  final double? totalBalance;

  @HiveField(10)
  final bool isActive;

  FamilyModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.familyCode,
    required this.settings,
    this.members = const [],
    this.memberIds = const [],
    this.totalBalance,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'familyCode': familyCode,
      'settings': settings.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'memberIds': memberIds,
      'totalBalance': totalBalance,
      'isActive': isActive,
    };
  }

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Family',
      description: json['description'],
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      familyCode: json['familyCode'],
      settings: json['settings'] != null
          ? FamilySettings.fromJson(json['settings'])
          : FamilySettings(),
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => FamilyMember.fromJson(m))
              .toList()
          : [],
      memberIds: json['memberIds'] != null
          ? List<String>.from(json['memberIds'])
          : [],
      totalBalance: (json['totalBalance'] as num?)?.toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }

  FamilyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    String? familyCode,
    FamilySettings? settings,
    List<FamilyMember>? members,
    List<String>? memberIds,
    double? totalBalance,
    bool? isActive,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      familyCode: familyCode ?? this.familyCode,
      settings: settings ?? this.settings,
      members: members ?? this.members,
      memberIds: memberIds ?? this.memberIds,
      totalBalance: totalBalance ?? this.totalBalance,
      isActive: isActive ?? this.isActive,
    );
  }

  // ==================== HELPERS ====================

  String get memberCount => '${members.length} members';

  List<FamilyMember> get admins => members.where((m) => m.isAdmin).toList();
  List<FamilyMember> get activeMembers => members.where((m) => m.isActive).toList();

  bool get hasMembers => members.isNotEmpty;

  FamilyMember? getMemberById(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  bool isMember(String userId) {
    return members.any((m) => m.userId == userId);
  }

  bool isAdmin(String userId) {
    return members.any((m) => m.userId == userId && m.isAdmin);
  }

  String getDisplayName(String userId) {
    final member = getMemberById(userId);
    return member?.displayName ?? 'Unknown';
  }

  String get currency => settings.currency ?? 'USD';
}
