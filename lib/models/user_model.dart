import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? email;

  @HiveField(2)
  String? username;  // ✅ ADDED

  @HiveField(3)
  String? phoneNumber;

  @HiveField(4)
  String? displayName;

  @HiveField(5)
  String? photoUrl;  // ✅ ADDED

  @HiveField(6)
  String? country;

  @HiveField(7)
  String? currency;

  @HiveField(8)
  String? familyId;

  @HiveField(9)
  String? role;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  bool? emailVerified;

  @HiveField(12)
  String? displayCurrency;  // ✅ ADDED

  UserModel({
    this.id,
    this.email,
    this.username,  // ✅ ADDED
    this.phoneNumber,
    this.displayName,
    this.photoUrl,  // ✅ ADDED
    this.country,
    this.currency = 'USD',
    this.familyId,
    this.role = 'member',
    this.createdAt,
    this.emailVerified = false,
    this.displayCurrency = 'USD',  // ✅ ADDED
  });

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    if (username != null && username!.isNotEmpty) {
      return username![0].toUpperCase();
    }
    return 'U';
  }

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';
  bool get isOwner => role == 'owner';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,  // ✅ ADDED
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,  // ✅ ADDED
      'country': country,
      'currency': currency,
      'familyId': familyId,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'emailVerified': emailVerified,
      'displayCurrency': displayCurrency,  // ✅ ADDED
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],  // ✅ ADDED
      phoneNumber: json['phoneNumber'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],  // ✅ ADDED
      country: json['country'],
      currency: json['currency'] ?? 'USD',
      familyId: json['familyId'],
      role: json['role'] ?? 'member',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      emailVerified: json['emailVerified'] ?? false,
      displayCurrency: json['displayCurrency'] ?? 'USD',  // ✅ ADDED
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,  // ✅ ADDED
    String? phoneNumber,
    String? displayName,
    String? photoUrl,  // ✅ ADDED
    String? country,
    String? currency,
    String? familyId,
    String? role,
    DateTime? createdAt,
    bool? emailVerified,
    String? displayCurrency,  // ✅ ADDED
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,  // ✅ ADDED
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,  // ✅ ADDED
      country: country ?? this.country,
      currency: currency ?? this.currency,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
      displayCurrency: displayCurrency ?? this.displayCurrency,  // ✅ ADDED
    );
  }
}
