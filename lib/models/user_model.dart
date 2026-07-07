// lib/models/user_model.dart
import 'package:hive/hive.dart';

// ✅ FIXED: Uncommented part directive for build_runner
part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? email;

  @HiveField(2)
  String? username;

  @HiveField(3)
  String? phoneNumber;

  @HiveField(4)
  String? displayName;

  @HiveField(5)
  String? photoUrl;

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
  String? displayCurrency;

  UserModel({
    this.id,
    this.email,
    this.username,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.country,
    this.currency = 'USD',
    this.familyId,
    this.role = 'member',
    this.createdAt,
    this.emailVerified = false,
    this.displayCurrency = 'USD',
  });

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    if (username != null && username!.isNotEmpty) {
      return username![0].toUpperCase();
    }
    return 'U';
  }

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';
  bool get isOwner => role == 'owner';

  // ✅ ADDED: Balance getters for profile screen
  double get balance => 0.0; // Placeholder - should be calculated from transactions
  double get totalIncome => 0.0; // Placeholder
  double get totalExpense => 0.0; // Placeholder

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'country': country,
      'currency': currency,
      'familyId': familyId,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'emailVerified': emailVerified,
      'displayCurrency': displayCurrency,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      phoneNumber: json['phoneNumber'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      country: json['country'],
      currency: json['currency'] ?? 'USD',
      familyId: json['familyId'],
      role: json['role'] ?? 'member',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      emailVerified: json['emailVerified'] ?? false,
      displayCurrency: json['displayCurrency'] ?? 'USD',
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? country,
    String? currency,
    String? familyId,
    String? role,
    DateTime? createdAt,
    bool? emailVerified,
    String? displayCurrency,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
      displayCurrency: displayCurrency ?? this.displayCurrency,
    );
  }
}
