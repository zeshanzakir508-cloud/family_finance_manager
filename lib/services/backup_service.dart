// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
// ✅ FIXED: Removed unused import
// import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/family_model.dart';
import '../models/transfer_model.dart';
import '../models/notification_model.dart';
import '../models/backup_model.dart';
import 'database_service.dart';
// ✅ FIXED: Removed unused import or kept for Constants
import '../utils/constants.dart';
import '../utils/helpers.dart';

class BackupService {
  static Future<BackupModel?> createBackup(String userId) async {
    try {
      final user = await DatabaseService.getUser(userId);
      if (user == null) return null;

      final transactions = await DatabaseService.getUserTransactions(userId);
      final families = await DatabaseService.getUserFamilies(userId);
      final transfers = await DatabaseService.getUserTransfers(userId);
      final notifications = await DatabaseService.getUserNotifications(userId);

      final backupData = {
        'user': user.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'families': families.map((f) => f.toJson()).toList(),
        'transfers': transfers.map((t) => t.toJson()).toList(),
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'backupDate': DateTime.now().toIso8601String(),
        'appVersion': Constants.appVersion,
      };

      final jsonString = jsonEncode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final fileName = 'backup_${Helpers.generateId()}.json';
      final filePath = '${backupDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      int totalMembers = 0;
      for (var family in families) {
        totalMembers += (family.members?.length ?? 0);
      }

      final backup = BackupModel(
        id: Helpers.generateId(),
        userId: userId,
        backupDate: DateTime.now(),
        fileName: fileName,
        fileSize: (jsonString.length / (1024 * 1024)),
        transactionCount: transactions.length,
        familyCount: families.length,
        memberCount: totalMembers,
        filePath: filePath,
        isCloudBackup: false,
      );

      await DatabaseService.saveBackup(backup);
      return backup;
    } catch (e) {
      print('❌ Backup error: $e');
      return null;
    }
  }

  static Future<bool> restoreBackup(String filePath, String userId) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Backup file not found: $filePath');
        return false;
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Clear existing data
      await DatabaseService.clearAllData();

      if (backupData['user'] != null) {
        final user = UserModel.fromJson(backupData['user']);
        await DatabaseService.saveUser(user);
      }

      if (backupData['transactions'] != null) {
        final transactions = (backupData['transactions'] as List)
            .map((t) => TransactionModel.fromJson(t))
            .toList();
        for (var transaction in transactions) {
          await DatabaseService.saveTransaction(transaction);
        }
      }

      if (backupData['families'] != null) {
        final families = (backupData['families'] as List)
            .map((f) => FamilyModel.fromJson(f))
            .toList();
        for (var family in families) {
          await DatabaseService.saveFamily(family);
        }
      }

      if (backupData['transfers'] != null) {
        final transfers = (backupData['transfers'] as List)
            .map((t) => TransferModel.fromJson(t))
            .toList();
        for (var transfer in transfers) {
          await DatabaseService.saveTransfer(transfer);
        }
      }

      if (backupData['notifications'] != null) {
        final notifications = (backupData['notifications'] as List)
            .map((n) => NotificationModel.fromJson(n))
            .toList();
        for (var notification in notifications) {
          await DatabaseService.saveNotification(notification);
        }
      }

      print('✅ Backup restored successfully');
      return true;
    } catch (e) {
      print('❌ Restore error: $e');
      return false;
    }
  }

  static Future<List<BackupModel>> getBackups(String userId) async {
    return DatabaseService.getUserBackups(userId);
  }

  static Future<bool> deleteBackup(String backupId) async {
    try {
      final backups = await DatabaseService.getUserBackups('');
      final backup = backups.firstWhere((b) => b.id == backupId);
      
      if (backup.filePath != null) {
        final file = File(backup.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await DatabaseService.deleteBackup(backupId);
      return true;
    } catch (e) {
      print('❌ Delete backup error: $e');
      return false;
    }
  }

  static Future<bool> deleteBackupFile(BackupModel backup) async {
    try {
      if (backup.filePath != null) {
        final file = File(backup.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await DatabaseService.deleteBackup(backup.id);
      return true;
    } catch (e) {
      print('❌ Delete backup file error: $e');
      return false;
    }
  }

  static Future<String?> exportData(String userId) async {
    try {
      final user = await DatabaseService.getUser(userId);
      if (user == null) return null;

      final transactions = await DatabaseService.getUserTransactions(userId);
      final families = await DatabaseService.getUserFamilies(userId);
      final transfers = await DatabaseService.getUserTransfers(userId);

      final exportData = {
        'user': user.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'families': families.map((f) => f.toJson()).toList(),
        'transfers': transfers.map((t) => t.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      print('❌ Export error: $e');
      return null;
    }
  }

  static Future<bool> importData(String jsonString, String userId) async {
    try {
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (importData['user'] != null) {
        final user = UserModel.fromJson(importData['user']);
        await DatabaseService.saveUser(user);
      }

      if (importData['transactions'] != null) {
        final transactions = (importData['transactions'] as List)
            .map((t) => TransactionModel.fromJson(t))
            .toList();
        for (var transaction in transactions) {
          await DatabaseService.saveTransaction(transaction);
        }
      }

      if (importData['families'] != null) {
        final families = (importData['families'] as List)
            .map((f) => FamilyModel.fromJson(f))
            .toList();
        for (var family in families) {
          await DatabaseService.saveFamily(family);
        }
      }

      if (importData['transfers'] != null) {
        final transfers = (importData['transfers'] as List)
            .map((t) => TransferModel.fromJson(t))
            .toList();
        for (var transfer in transfers) {
          await DatabaseService.saveTransfer(transfer);
        }
      }

      print('✅ Data imported successfully');
      return true;
    } catch (e) {
      print('❌ Import error: $e');
      return false;
    }
  }

  static Future<void> deleteOldBackups(String userId, int keepCount) async {
    try {
      final backups = await getBackups(userId);
      if (backups.length <= keepCount) return;

      backups.sort((a, b) => b.backupDate.compareTo(a.backupDate));

      for (int i = keepCount; i < backups.length; i++) {
        await deleteBackupFile(backups[i]);
      }

      print('✅ Deleted ${backups.length - keepCount} old backups');
    } catch (e) {
      print('❌ Delete old backups error: $e');
    }
  }

  static Future<double> getTotalBackupSize(String userId) async {
    try {
      final backups = await getBackups(userId);
      double totalSize = 0;
      for (var backup in backups) {
        totalSize += backup.fileSize ?? 0;
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
