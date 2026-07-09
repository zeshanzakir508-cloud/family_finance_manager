// lib/models/backup_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

// ✅ FIXED: Uncommented part directive for build_runner
part 'backup_model.g.dart';

@HiveType(typeId: 15)
class BackupModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime backupDate;

  @HiveField(3)
  final String fileName;

  @HiveField(4)
  final double? fileSize; // in MB

  @HiveField(5)
  final int transactionCount;

  @HiveField(6)
  final int familyCount;

  @HiveField(7)
  final int memberCount;

  @HiveField(8)
  final String? filePath;

  @HiveField(9)
  final bool isCloudBackup;

  @HiveField(10)
  final String? cloudStorageUrl;

  @HiveField(11)
  final String? notes;

  BackupModel({
    required this.id,
    required this.userId,
    required this.backupDate,
    required this.fileName,
    this.fileSize,
    this.transactionCount = 0,
    this.familyCount = 0,
    this.memberCount = 0,
    this.filePath,
    this.isCloudBackup = false,
    this.cloudStorageUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'backupDate': Timestamp.fromDate(backupDate),
      'fileName': fileName,
      'fileSize': fileSize,
      'transactionCount': transactionCount,
      'familyCount': familyCount,
      'memberCount': memberCount,
      'filePath': filePath,
      'isCloudBackup': isCloudBackup,
      'cloudStorageUrl': cloudStorageUrl,
      'notes': notes,
    };
  }

  factory BackupModel.fromJson(Map<String, dynamic> json) {
    return BackupModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      backupDate: (json['backupDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileName: json['fileName'] ?? '',
      fileSize: (json['fileSize'] as num?)?.toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      familyCount: json['familyCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      filePath: json['filePath'],
      isCloudBackup: json['isCloudBackup'] ?? false,
      cloudStorageUrl: json['cloudStorageUrl'],
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
    String? cloudStorageUrl,
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
      cloudStorageUrl: cloudStorageUrl ?? this.cloudStorageUrl,
      notes: notes ?? this.notes,
    );
  }

  // ==================== HELPERS ====================

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1) return '${(fileSize! * 1024).toStringAsFixed(0)} KB';
    return '${fileSize!.toStringAsFixed(2)} MB';
  }

  // ✅ FIXED: Renamed to match expected getter name 'formattedDate'
  String get formattedDate {
    return '${backupDate.day}/${backupDate.month}/${backupDate.year} ${backupDate.hour.toString().padLeft(2, '0')}:${backupDate.minute.toString().padLeft(2, '0')}';
  }

  // ✅ FIXED: Renamed to match expected getter name 'formattedSize'
  String get formattedSize {
    return formattedFileSize;
  }

  String get formattedBackupDate {
    return '${backupDate.day}/${backupDate.month}/${backupDate.year} ${backupDate.hour.toString().padLeft(2, '0')}:${backupDate.minute.toString().padLeft(2, '0')}';
  }

  bool get isEmpty => transactionCount == 0 && familyCount == 0 && memberCount == 0;

  String get summary {
    final parts = <String>[];
    if (transactionCount > 0) parts.add('$transactionCount transactions');
    if (familyCount > 0) parts.add('$familyCount families');
    if (memberCount > 0) parts.add('$memberCount members');
    return parts.isNotEmpty ? parts.join(', ') : 'Empty backup';
  }

  bool get isLocalBackup => !isCloudBackup;
}
