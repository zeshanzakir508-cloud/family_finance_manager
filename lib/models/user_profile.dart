import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? email;

  @HiveField(2)
  String? fullName;

  @HiveField(3)
  String? fatherOrHusbandName;

  @HiveField(4)
  String? phoneNumber;

  @HiveField(5)
  String? profileImageUrl;

  @HiveField(6)
  String? familyId;

  @HiveField(7)
  String? role;

  @HiveField(8)
  bool? isApproved;

  @HiveField(9)
  bool? isEmailVerified;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  DateTime? lastLogin;

  @HiveField(12)
  String? address;

  @HiveField(13)
  String? occupation;

  @HiveField(14)
  String? dateOfBirth;

  @HiveField(15)
  String? profileImageLocalPath;

  @HiveField(16)
  bool? isActive;

  @HiveField(17)
  String? deviceToken;

  @HiveField(18)
  String? preferredLanguage;

  @HiveField(19)
  bool? isDarkMode;

  @HiveField(20)
  String? notificationPreference;

  @HiveField(21)
  String? currency;  // ADD THIS FIELD

  UserProfile({
    this.id,
    this.email,
    this.fullName,
    this.fatherOrHusbandName,
    this.phoneNumber,
    this.profileImageUrl,
    this.familyId,
    this.role,
    this.isApproved = false,
    this.isEmailVerified = false,
    this.createdAt,
    this.lastLogin,
    this.address,
    this.occupation,
    this.dateOfBirth,
    this.profileImageLocalPath,
    this.isActive = true,
    this.deviceToken,
    this.preferredLanguage = 'en',
    this.isDarkMode = false,
    this.notificationPreference = 'all',
    this.currency = 'USD',  // ADD THIS
  });

  // Convert to JSON for Firebase/Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'fatherOrHusbandName': fatherOrHusbandName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'familyId': familyId,
      'role': role,
      'isApproved': isApproved,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'address': address,
      'occupation': occupation,
      'dateOfBirth': dateOfBirth,
      'profileImageLocalPath': profileImageLocalPath,
      'isActive': isActive,
      'deviceToken': deviceToken,
      'preferredLanguage': preferredLanguage,
      'isDarkMode': isDarkMode,
      'notificationPreference': notificationPreference,
      'currency': currency,  // ADD THIS
    };
  }

  // Create from JSON (Firebase/Firestore)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      fatherOrHusbandName: json['fatherOrHusbandName'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      familyId: json['familyId'],
      role: json['role'],
      isApproved: json['isApproved'],
      isEmailVerified: json['isEmailVerified'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      address: json['address'],
      occupation: json['occupation'],
      dateOfBirth: json['dateOfBirth'],
      profileImageLocalPath: json['profileImageLocalPath'],
      isActive: json['isActive'],
      deviceToken: json['deviceToken'],
      preferredLanguage: json['preferredLanguage'],
      isDarkMode: json['isDarkMode'],
      notificationPreference: json['notificationPreference'],
      currency: json['currency'] ?? 'USD',  // ADD THIS
    );
  }

  // Create copy with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? fatherOrHusbandName,
    String? phoneNumber,
    String? profileImageUrl,
    String? familyId,
    String? role,
    bool? isApproved,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? address,
    String? occupation,
    String? dateOfBirth,
    String? profileImageLocalPath,
    bool? isActive,
    String? deviceToken,
    String? preferredLanguage,
    bool? isDarkMode,
    String? notificationPreference,
    String? currency,  // ADD THIS
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      fatherOrHusbandName: fatherOrHusbandName ?? this.fatherOrHusbandName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageLocalPath: profileImageLocalPath ?? this.profileImageLocalPath,
      isActive: isActive ?? this.isActive,
      deviceToken: deviceToken ?? this.deviceToken,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationPreference: notificationPreference ?? this.notificationPreference,
      currency: currency ?? this.currency,  // ADD THIS
    );
  }

  // Helper method to display user's display name
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return email?.split('@').first ?? 'User';
  }

  // Helper method to get initials
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

  @override
  String toString() {
    return 'UserProfile{id: $id, email: $email, fullName: $fullName, phoneNumber: $phoneNumber, role: $role}';
  }
}
