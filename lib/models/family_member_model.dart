import 'package:hive/hive.dart';

part 'family_member_model.g.dart';

@HiveType(typeId: 7)
class FamilyMemberModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? familyId;

  @HiveField(2)
  String? userId;

  @HiveField(3)
  String? fullName;

  @HiveField(4)
  String? email;

  @HiveField(5)
  String? phoneNumber;

  @HiveField(6)
  String? role;

  @HiveField(7)
  bool? isActive;

  @HiveField(8)
  DateTime? joinedAt;

  @HiveField(9)
  String? relation;

  FamilyMemberModel({
    this.id,
    this.familyId,
    this.userId,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.role,
    this.isActive = true,
    this.joinedAt,
    this.relation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isActive': isActive,
      'joinedAt': joinedAt?.toIso8601String(),
      'relation': relation,
    };
  }

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'],
      familyId: json['familyId'],
      userId: json['userId'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      isActive: json['isActive'],
      joinedAt: json['joinedAt'] != null 
          ? DateTime.parse(json['joinedAt']) 
          : null,
      relation: json['relation'],
    );
  }

  FamilyMemberModel copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isActive,
    DateTime? joinedAt,
    String? relation,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      relation: relation ?? this.relation,
    );
  }

  String get displayName => fullName ?? email?.split('@').first ?? 'Member';
}
