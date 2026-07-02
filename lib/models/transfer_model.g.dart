// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferModelAdapter extends TypeAdapter<TransferModel> {
  @override
  final int typeId = 4;

  @override
  TransferModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransferModel(
      id: fields[0] as String?,
      familyId: fields[1] as String?,
      fromMemberId: fields[2] as String?,
      fromMemberName: fields[3] as String?,
      toMemberId: fields[4] as String?,
      toMemberName: fields[5] as String?,
      amount: fields[6] as double?,
      note: fields[7] as String?,
      status: fields[8] as TransferStatus?,
      createdAt: fields[9] as DateTime?,
      approvedAt: fields[10] as DateTime?,
      rejectedAt: fields[11] as DateTime?,
      rejectionReason: fields[12] as String?,
      senderTransactionId: fields[13] as String?,
      receiverTransactionId: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransferModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.familyId)
      ..writeByte(2)
      ..write(obj.fromMemberId)
      ..writeByte(3)
      ..write(obj.fromMemberName)
      ..writeByte(4)
      ..write(obj.toMemberId)
      ..writeByte(5)
      ..write(obj.toMemberName)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.approvedAt)
      ..writeByte(11)
      ..write(obj.rejectedAt)
      ..writeByte(12)
      ..write(obj.rejectionReason)
      ..writeByte(13)
      ..write(obj.senderTransactionId)
      ..writeByte(14)
      ..write(obj.receiverTransactionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransferStatusAdapter extends TypeAdapter<TransferStatus> {
  @override
  final int typeId = 3;

  @override
  TransferStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransferStatus.pending;
      case 1:
        return TransferStatus.approved;
      case 2:
        return TransferStatus.rejected;
      case 3:
        return TransferStatus.completed;
      default:
        return TransferStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TransferStatus obj) {
    switch (obj) {
      case TransferStatus.pending:
        writer.writeByte(0);
        break;
      case TransferStatus.approved:
        writer.writeByte(1);
        break;
      case TransferStatus.rejected:
        writer.writeByte(2);
        break;
      case TransferStatus.completed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
