import 'package:hive/hive.dart';

part 'backup_model.g.dart';

@HiveType(typeId: 7)
class BackupModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  DateTime? backupDate;

  @HiveField(3)
  String? fileName;

  @HiveField(4)
  double? fileSize; // in MB

  @HiveField(5)
  int? transactionCount;

  @HiveField(6)
  int? familyCount;

  @HiveField(7)
  int? memberCount;

  @HiveField(8)
  String? filePath;

  @HiveField(9)
  bool? isCloudBackup;

  @HiveField(10)
  String? notes;

  BackupModel({
    this.id,
    this.userId,
    this.backupDate,
    this.fileName,
    this.fileSize,
    this.transactionCount,
    this.familyCount,
    this.memberCount,
    this.filePath,
    this.isCloudBackup = false,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'backupDate': backupDate?.toIso8601String(),
      'fileName': fileName,
      'fileSize': fileSize,
      'transactionCount': transactionCount,
      'familyCount': familyCount,
      'memberCount': memberCount,
      'filePath': filePath,
      'isCloudBackup': isCloudBackup,
      'notes': notes,
    };
  }

  factory BackupModel.fromJson(Map<String, dynamic> json) {
    return BackupModel(
      id: json['id'],
      userId: json['userId'],
      backupDate: json['backupDate'] != null
          ? DateTime.parse(json['backupDate'])
          : null,
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      transactionCount: json['transactionCount'],
      familyCount: json['familyCount'],
      memberCount: json['memberCount'],
      filePath: json['filePath'],
      isCloudBackup: json['isCloudBackup'] ?? false,
      notes: json['notes'],
    );
  }

  BackupModel copyWith({
    String? id,
    String? userId,
    DateTime? backupDate,
    String? fileName,
    double? fileSize,
    int? transactionCount,
    int? familyCount,
    int? memberCount,
    String? filePath,
    bool? isCloudBackup,
    String? notes,
  }) {
    return BackupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      backupDate: backupDate ?? this.backupDate,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      transactionCount: transactionCount ?? this.transactionCount,
      familyCount: familyCount ?? this.familyCount,
      memberCount: memberCount ?? this.memberCount,
      filePath: filePath ?? this.filePath,
      isCloudBackup: isCloudBackup ?? this.isCloudBackup,
      notes: notes ?? this.notes,
    );
  }

  String get formattedDate {
    if (backupDate == null) return '';
    return '${backupDate!.day}/${backupDate!.month}/${backupDate!.year} ${backupDate!.hour}:${backupDate!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (fileSize == null) return '0 MB';
    return '${fileSize!.toStringAsFixed(1)} MB';
  }

  String get summary {
    return '$transactionCount transactions, $familyCount families, $memberCount members';
  }
}
