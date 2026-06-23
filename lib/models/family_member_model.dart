import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'family_member_model.g.dart';

@HiveType(typeId: 3)
enum MemberRelation {
  @HiveField(0)
  self,
  @HiveField(1)
  spouse,
  @HiveField(2)
  son,
  @HiveField(3)
  daughter,
  @HiveField(4)
  father,
  @HiveField(5)
  mother,
  @HiveField(6)
  brother,
  @HiveField(7)
  sister,
  @HiveField(8)
  grandparent,
  @HiveField(9)
  uncle,
  @HiveField(10)
  aunt,
  @HiveField(11)
  cousin,
  @HiveField(12)
  other,
}

@HiveType(typeId: 4)
class FamilyMemberModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  MemberRelation relation;

  @HiveField(3)
  DateTime? dateOfBirth;

  @HiveField(4)
  String? phoneNumber;

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  DateTime createdAt;

  FamilyMemberModel({
    String? id,
    required this.name,
    required this.relation,
    this.dateOfBirth,
    this.phoneNumber,
    this.email,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation.name,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'phoneNumber': phoneNumber,
        'email': email,
        'notes': notes,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) => FamilyMemberModel(
        id: json['id'],
        name: json['name'],
        relation: MemberRelation.values.firstWhere(
          (e) => e.name == json['relation'],
          orElse: () => MemberRelation.other,
        ),
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'])
            : null,
        phoneNumber: json['phoneNumber'],
        email: json['email'],
        notes: json['notes'],
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
      );

  String get relationDisplayName {
    switch (relation) {
      case MemberRelation.self:
        return 'Self';
      case MemberRelation.spouse:
        return 'Spouse';
      case MemberRelation.son:
        return 'Son';
      case MemberRelation.daughter:
        return 'Daughter';
      case MemberRelation.father:
        return 'Father';
      case MemberRelation.mother:
        return 'Mother';
      case MemberRelation.brother:
        return 'Brother';
      case MemberRelation.sister:
        return 'Sister';
      case MemberRelation.grandparent:
        return 'Grandparent';
      case MemberRelation.uncle:
        return 'Uncle';
      case MemberRelation.aunt:
        return 'Aunt';
      case MemberRelation.cousin:
        return 'Cousin';
      case MemberRelation.other:
        return 'Other';
    }
  }

  IconData get relationIcon {
    switch (relation) {
      case MemberRelation.self:
        return Icons.person;
      case MemberRelation.spouse:
        return Icons.favorite;
      case MemberRelation.son:
        return Icons.boy;
      case MemberRelation.daughter:
        return Icons.girl;
      case MemberRelation.father:
        return Icons.man;
      case MemberRelation.mother:
        return Icons.woman;
      case MemberRelation.brother:
        return Icons.person;
      case MemberRelation.sister:
        return Icons.person;
      case MemberRelation.grandparent:
        return Icons.elderly;
      case MemberRelation.uncle:
        return Icons.person;
      case MemberRelation.aunt:
        return Icons.person;
      case MemberRelation.cousin:
        return Icons.person;
      case MemberRelation.other:
        return Icons.person_add;
    }
  }
}