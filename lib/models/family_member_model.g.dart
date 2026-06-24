// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FamilyMemberModelAdapter extends TypeAdapter<FamilyMemberModel> {
  @override
  final int typeId = 4;

  @override
  FamilyMemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FamilyMemberModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      relation: fields[2] as MemberRelation,
      dateOfBirth: fields[3] as DateTime?,
      phoneNumber: fields[4] as String?,
      email: fields[5] as String?,
      notes: fields[6] as String?,
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyMemberModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.relation)
      ..writeByte(3)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MemberRelationAdapter extends TypeAdapter<MemberRelation> {
  @override
  final int typeId = 3;

  @override
  MemberRelation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MemberRelation.self;
      case 1:
        return MemberRelation.spouse;
      case 2:
        return MemberRelation.son;
      case 3:
        return MemberRelation.daughter;
      case 4:
        return MemberRelation.father;
      case 5:
        return MemberRelation.mother;
      case 6:
        return MemberRelation.brother;
      case 7:
        return MemberRelation.sister;
      case 8:
        return MemberRelation.grandparent;
      case 9:
        return MemberRelation.uncle;
      case 10:
        return MemberRelation.aunt;
      case 11:
        return MemberRelation.cousin;
      case 12:
        return MemberRelation.other;
      default:
        return MemberRelation.self;
    }
  }

  @override
  void write(BinaryWriter writer, MemberRelation obj) {
    switch (obj) {
      case MemberRelation.self:
        writer.writeByte(0);
        break;
      case MemberRelation.spouse:
        writer.writeByte(1);
        break;
      case MemberRelation.son:
        writer.writeByte(2);
        break;
      case MemberRelation.daughter:
        writer.writeByte(3);
        break;
      case MemberRelation.father:
        writer.writeByte(4);
        break;
      case MemberRelation.mother:
        writer.writeByte(5);
        break;
      case MemberRelation.brother:
        writer.writeByte(6);
        break;
      case MemberRelation.sister:
        writer.writeByte(7);
        break;
      case MemberRelation.grandparent:
        writer.writeByte(8);
        break;
      case MemberRelation.uncle:
        writer.writeByte(9);
        break;
      case MemberRelation.aunt:
        writer.writeByte(10);
        break;
      case MemberRelation.cousin:
        writer.writeByte(11);
        break;
      case MemberRelation.other:
        writer.writeByte(12);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberRelationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
