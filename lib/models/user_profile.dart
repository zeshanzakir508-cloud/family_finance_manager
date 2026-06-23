import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String name;

  @HiveField(2)
  String fatherName;

  @HiveField(3)
  String phoneNumber;

  @HiveField(4)
  String email;

  @HiveField(5)
  String? address;

  @HiveField(6)
  String? city;

  @HiveField(7)
  String? occupation;

  @HiveField(8)
  int? familyMembers;

  @HiveField(9)
  double? monthlyIncome;

  @HiveField(10)
  DateTime? dateOfBirth;

  @HiveField(11)
  String? emergencyContact;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  bool isActive;

  @HiveField(14)
  DateTime? lastLogin;

  UserProfile({
    required this.uid,
    required this.name,
    required this.fatherName,
    required this.phoneNumber,
    required this.email,
    this.address,
    this.city,
    this.occupation,
    this.familyMembers,
    this.monthlyIncome,
    this.dateOfBirth,
    this.emergencyContact,
    DateTime? createdAt,
    this.isActive = true,
    this.lastLogin,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'fatherName': fatherName,
        'phoneNumber': phoneNumber,
        'email': email,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (occupation != null) 'occupation': occupation,
        if (familyMembers != null) 'familyMembers': familyMembers,
        if (monthlyIncome != null) 'monthlyIncome': monthlyIncome,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        if (lastLogin != null) 'lastLogin': lastLogin!.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'],
        name: json['name'],
        fatherName: json['fatherName'],
        phoneNumber: json['phoneNumber'],
        email: json['email'],
        address: json['address'],
        city: json['city'],
        occupation: json['occupation'],
        familyMembers: json['familyMembers'],
        monthlyIncome: json['monthlyIncome']?.toDouble(),
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'])
            : null,
        emergencyContact: json['emergencyContact'],
        createdAt: DateTime.parse(json['createdAt']),
        isActive: json['isActive'] ?? true,
        lastLogin: json['lastLogin'] != null
            ? DateTime.parse(json['lastLogin'])
            : null,
      );
}