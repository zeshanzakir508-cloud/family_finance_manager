import 'package:hive/hive.dart';

part 'family_model.g.dart';

@HiveType(typeId: 4)
class FamilyModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? createdBy;

  @HiveField(3)
  List<String>? memberIds;

  @HiveField(4)
  String? description;

  @HiveField(5)
  String? familyImageUrl;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  @HiveField(8)
  bool? isActive;

  @HiveField(9)
  String? currency;

  @HiveField(10)
  double? monthlyBudget;

  @HiveField(11)
  String? inviteCode;

  @HiveField(12)
  String? familyCode;

  @HiveField(13)
  String? adminId;

  @HiveField(14)
  List<String>? pendingMemberIds;

  @HiveField(15)
  Map<String, dynamic>? settings;

  FamilyModel({
    this.id,
    this.name,
    this.createdBy,
    this.memberIds,
    this.description,
    this.familyImageUrl,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.currency = 'USD',
    this.monthlyBudget,
    this.inviteCode,
    this.familyCode,
    this.adminId,
    this.pendingMemberIds,
    this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'description': description,
      'familyImageUrl': familyImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'currency': currency,
      'monthlyBudget': monthlyBudget,
      'inviteCode': inviteCode,
      'familyCode': familyCode,
      'adminId': adminId,
      'pendingMemberIds': pendingMemberIds,
      'settings': settings,
    };
  }

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'],
      name: json['name'],
      createdBy: json['createdBy'],
      memberIds: json['memberIds'] != null 
          ? List<String>.from(json['memberIds']) 
          : null,
      description: json['description'],
      familyImageUrl: json['familyImageUrl'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      isActive: json['isActive'],
      currency: json['currency'],
      monthlyBudget: json['monthlyBudget'],
      inviteCode: json['inviteCode'],
      familyCode: json['familyCode'],
      adminId: json['adminId'],
      pendingMemberIds: json['pendingMemberIds'] != null 
          ? List<String>.from(json['pendingMemberIds']) 
          : null,
      settings: json['settings'],
    );
  }

  FamilyModel copyWith({
    String? id,
    String? name,
    String? createdBy,
    List<String>? memberIds,
    String? description,
    String? familyImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? currency,
    double? monthlyBudget,
    String? inviteCode,
    String? familyCode,
    String? adminId,
    List<String>? pendingMemberIds,
    Map<String, dynamic>? settings,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      description: description ?? this.description,
      familyImageUrl: familyImageUrl ?? this.familyImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      inviteCode: inviteCode ?? this.inviteCode,
      familyCode: familyCode ?? this.familyCode,
      adminId: adminId ?? this.adminId,
      pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
      settings: settings ?? this.settings,
    );
  }

  String get displayName => name ?? 'Family';
  int get memberCount => memberIds?.length ?? 0;
  int get pendingCount => pendingMemberIds?.length ?? 0;
  bool get hasAdmin => adminId != null;
}
