import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/family_model.dart';
import '../models/transfer_model.dart';
import '../models/notification_model.dart';
import '../models/backup_model.dart';
import 'database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class BackupService {
  static Future<BackupModel?> createBackup(String userId) async {
    try {
      final user = DatabaseService.getUser(userId);
      if (user == null) return null;

      final transactions = DatabaseService.getUserTransactions(userId);
      final families = DatabaseService.getAllFamilies();
      final transfers = DatabaseService.getUserTransfers(userId);
      final notifications = DatabaseService.getUserNotifications(userId);

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
      final fileName = 'backup_${Helpers.generateId()}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      int totalMembers = 0;
      for (var family in families) {
        totalMembers += (family.memberIds?.length ?? 0);
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
      print('Backup error: $e');
      return null;
    }
  }

  static Future<bool> restoreBackup(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

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

      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }

  static Future<List<BackupModel>> getBackups(String userId) async {
    return DatabaseService.getUserBackups(userId);
  }

  static Future<bool> deleteBackupFile(BackupModel backup) async {
    try {
      final file = File(backup.filePath ?? '');
      if (await file.exists()) {
        await file.delete();
      }
      await DatabaseService.deleteBackup(backup);
      return true;
    } catch (e) {
      print('Delete backup error: $e');
      return false;
    }
  }

  static Future<String?> exportData(String userId) async {
    try {
      final user = DatabaseService.getUser(userId);
      if (user == null) return null;

      final transactions = DatabaseService.getUserTransactions(userId);
      final families = DatabaseService.getAllFamilies();
      final transfers = DatabaseService.getUserTransfers(userId);

      final exportData = {
        'user': user.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'families': families.map((f) => f.toJson()).toList(),
        'transfers': transfers.map((t) => t.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      print('Export error: $e');
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

      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }
}
