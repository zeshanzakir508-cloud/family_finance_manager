// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 1;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String?,
      userId: fields[1] as String?,
      amount: fields[2] as double?,
      category: fields[3] as String?,
      description: fields[4] as String?,
      type: fields[5] as String?,
      date: fields[6] as DateTime?,
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      familyId: fields[9] as String?,
      memberId: fields[10] as String?,
      memberName: fields[11] as String?,
      isFamilyTransaction: fields[12] as bool?,
      sourceMemberId: fields[13] as String?,
      sourceMemberName: fields[14] as String?,
      transferId: fields[15] as String?,
      transferStatus: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.familyId)
      ..writeByte(10)
      ..write(obj.memberId)
      ..writeByte(11)
      ..write(obj.memberName)
      ..writeByte(12)
      ..write(obj.isFamilyTransaction)
      ..writeByte(13)
      ..write(obj.sourceMemberId)
      ..writeByte(14)
      ..write(obj.sourceMemberName)
      ..writeByte(15)
      ..write(obj.transferId)
      ..writeByte(16)
      ..write(obj.transferStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
