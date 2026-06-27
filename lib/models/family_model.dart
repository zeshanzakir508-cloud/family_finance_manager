import 'package:hive/hive.dart';

part 'family_model.g.dart';

@HiveType(typeId: 2)
class FamilyModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? adminId;

  @HiveField(4)
  List<String>? memberIds;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  String? familyCode;

  @HiveField(7)
  bool? isActive;

  @HiveField(8)
  String? currency;

  @HiveField(9)
  double? monthlyBudget;

  FamilyModel({
    this.id,
    this.name,
    this.description,
    this.adminId,
    this.memberIds,
    this.createdAt,
    this.familyCode,
    this.isActive = true,
    this.currency = 'USD',
    this.monthlyBudget,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'memberIds': memberIds,
      'createdAt': createdAt?.toIso8601String(),
      'familyCode': familyCode,
      'isActive': isActive,
      'currency': currency,
      'monthlyBudget': monthlyBudget,
    };
  }

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      adminId: json['adminId'],
      memberIds: json['memberIds'] != null
          ? List<String>.from(json['memberIds'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      familyCode: json['familyCode'],
      isActive: json['isActive'],
      currency: json['currency'] ?? 'USD',
      monthlyBudget: json['monthlyBudget'],
    );
  }

  FamilyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    List<String>? memberIds,
    DateTime? createdAt,
    String? familyCode,
    bool? isActive,
    String? currency,
    double? monthlyBudget,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      familyCode: familyCode ?? this.familyCode,
      isActive: isActive ?? this.isActive,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  String get displayName => name ?? 'Family';
  
  int get memberCount => memberIds?.length ?? 0;
}
