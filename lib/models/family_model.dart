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
  String? familyCode;

  @HiveField(6)
  String? baseCurrency;  // ✅ ADDED

  @HiveField(7)
  DateTime? createdAt;

  @HiveField(8)
  DateTime? updatedAt;

  FamilyModel({
    this.id,
    this.name,
    this.description,
    this.adminId,
    this.memberIds,
    this.familyCode,
    this.baseCurrency = 'USD',  // ✅ ADDED
    this.createdAt,
    this.updatedAt,
  });

  int get memberCount => memberIds?.length ?? 0;

  bool isAdmin(String userId) => adminId == userId;

  bool isMember(String userId) => memberIds?.contains(userId) ?? false;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'memberIds': memberIds,
      'familyCode': familyCode,
      'baseCurrency': baseCurrency,  // ✅ ADDED
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      adminId: json['adminId'],
      memberIds: json['memberIds'] != null ? List<String>.from(json['memberIds']) : null,
      familyCode: json['familyCode'],
      baseCurrency: json['baseCurrency'] ?? 'USD',  // ✅ ADDED
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  FamilyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    List<String>? memberIds,
    String? familyCode,
    String? baseCurrency,  // ✅ ADDED
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      familyCode: familyCode ?? this.familyCode,
      baseCurrency: baseCurrency ?? this.baseCurrency,  // ✅ ADDED
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
