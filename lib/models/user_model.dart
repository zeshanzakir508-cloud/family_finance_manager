import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? email;

  @HiveField(2)
  String? fullName;

  @HiveField(3)
  String? phoneNumber;

  @HiveField(4)
  String? fatherOrHusbandName;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  String? familyId;

  @HiveField(7)
  bool? isEmailVerified;

  @HiveField(8)
  String? currency;

  @HiveField(9)
  bool? isDarkMode;

  UserModel({
    this.id,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.fatherOrHusbandName,
    this.createdAt,
    this.familyId,
    this.isEmailVerified = false,
    this.currency = 'USD',
    this.isDarkMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'fatherOrHusbandName': fatherOrHusbandName,
      'createdAt': createdAt?.toIso8601String(),
      'familyId': familyId,
      'isEmailVerified': isEmailVerified,
      'currency': currency,
      'isDarkMode': isDarkMode,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      fatherOrHusbandName: json['fatherOrHusbandName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      familyId: json['familyId'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      currency: json['currency'] ?? 'USD',
      isDarkMode: json['isDarkMode'] ?? false,
    );
  }

  String get displayName => fullName ?? email?.split('@').first ?? 'User';
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}';
      }
      return parts[0][0];
    }
    return email?.substring(0, 1).toUpperCase() ?? 'U';
  }
}
