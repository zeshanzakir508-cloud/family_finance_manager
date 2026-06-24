// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      uid: fields[0] as String,
      name: fields[1] as String,
      fatherName: fields[2] as String,
      phoneNumber: fields[3] as String,
      email: fields[4] as String,
      address: fields[5] as String?,
      city: fields[6] as String?,
      occupation: fields[7] as String?,
      familyMembers: fields[8] as int?,
      monthlyIncome: fields[9] as double?,
      dateOfBirth: fields[10] as DateTime?,
      emergencyContact: fields[11] as String?,
      createdAt: fields[12] as DateTime?,
      isActive: fields[13] as bool,
      lastLogin: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.fatherName)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.occupation)
      ..writeByte(8)
      ..write(obj.familyMembers)
      ..writeByte(9)
      ..write(obj.monthlyIncome)
      ..writeByte(10)
      ..write(obj.dateOfBirth)
      ..writeByte(11)
      ..write(obj.emergencyContact)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.lastLogin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
