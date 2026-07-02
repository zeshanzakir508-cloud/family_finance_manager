// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupModelAdapter extends TypeAdapter<BackupModel> {
  @override
  final int typeId = 7;

  @override
  BackupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupModel(
      id: fields[0] as String?,
      userId: fields[1] as String?,
      backupDate: fields[2] as DateTime?,
      fileName: fields[3] as String?,
      fileSize: fields[4] as double?,
      transactionCount: fields[5] as int?,
      familyCount: fields[6] as int?,
      memberCount: fields[7] as int?,
      filePath: fields[8] as String?,
      isCloudBackup: fields[9] as bool?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BackupModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.backupDate)
      ..writeByte(3)
      ..write(obj.fileName)
      ..writeByte(4)
      ..write(obj.fileSize)
      ..writeByte(5)
      ..write(obj.transactionCount)
      ..writeByte(6)
      ..write(obj.familyCount)
      ..writeByte(7)
      ..write(obj.memberCount)
      ..writeByte(8)
      ..write(obj.filePath)
      ..writeByte(9)
      ..write(obj.isCloudBackup)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
