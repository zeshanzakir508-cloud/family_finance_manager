import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/family_model.dart';
import '../models/transfer_model.dart';
import '../models/notification_model.dart';
import '../models/backup_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  // ---- User Methods ----
  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(Constants.usersBox);
    await box.put(user.id, user);
  }

  static UserModel? getUser(String userId) {
    final box = Hive.box<UserModel>(Constants.usersBox);
    return box.get(userId);
  }

  static List<UserModel> getAllUsers() {
    final box = Hive.box<UserModel>(Constants.usersBox);
    return box.values.toList();
  }

  static Future<void> deleteUser(String userId) async {
    final box = Hive.box<UserModel>(Constants.usersBox);
    await box.delete(userId);
  }

  // ---- Transaction Methods ----
  static Future<void> saveTransaction(TransactionModel transaction) async {
    final box = Hive.box<TransactionModel>(Constants.transactionsBox);
    await box.add(transaction);
  }

  static List<TransactionModel> getAllTransactions() {
    final box = Hive.box<TransactionModel>(Constants.transactionsBox);
    return box.values.toList();
  }

  static List<TransactionModel> getUserTransactions(String userId) {
    final box = Hive.box<TransactionModel>(Constants.transactionsBox);
    return box.values.where((t) => t.userId == userId).toList();
  }

  static List<TransactionModel> getFamilyTransactions(String familyId) {
    final box = Hive.box<TransactionModel>(Constants.transactionsBox);
    return box.values.where((t) => t.familyId == familyId).toList();
  }

  static Future<void> deleteTransaction(TransactionModel transaction) async {
    await transaction.delete();
  }

  // ---- Family Methods ----
  static Future<void> saveFamily(FamilyModel family) async {
    final box = Hive.box<FamilyModel>(Constants.familiesBox);
    await box.add(family);
  }

  static List<FamilyModel> getAllFamilies() {
    final box = Hive.box<FamilyModel>(Constants.familiesBox);
    return box.values.toList();
  }

  static FamilyModel? getFamily(String familyId) {
    final box = Hive.box<FamilyModel>(Constants.familiesBox);
    try {
      return box.values.firstWhere(
        (f) => f.id == familyId,
        orElse: () => throw Exception('Family not found'),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteFamily(FamilyModel family) async {
    await family.delete();
  }

  // ---- Transfer Methods ----
  static Future<void> saveTransfer(TransferModel transfer) async {
    final box = Hive.box<TransferModel>(Constants.transfersBox);
    await box.add(transfer);
  }

  static List<TransferModel> getAllTransfers() {
    final box = Hive.box<TransferModel>(Constants.transfersBox);
    return box.values.toList();
  }

  static List<TransferModel> getFamilyTransfers(String familyId) {
    final box = Hive.box<TransferModel>(Constants.transfersBox);
    return box.values.where((t) => t.familyId == familyId).toList();
  }

  static List<TransferModel> getUserTransfers(String userId) {
    final box = Hive.box<TransferModel>(Constants.transfersBox);
    return box.values
        .where((t) => t.fromMemberId == userId || t.toMemberId == userId)
        .toList();
  }

  static Future<void> deleteTransfer(TransferModel transfer) async {
    await transfer.delete();
  }

  // ---- Notification Methods ----
  static Future<void> saveNotification(NotificationModel notification) async {
    final box = Hive.box<NotificationModel>(Constants.notificationsBox);
    await box.add(notification);
  }

  static List<NotificationModel> getUserNotifications(String userId) {
    final box = Hive.box<NotificationModel>(Constants.notificationsBox);
    return box.values.where((n) => n.userId == userId).toList();
  }

  static Future<void> markNotificationAsRead(NotificationModel notification) async {
    final updated = notification.copyWith(isRead: true);
    await updated.save();
  }

  static Future<void> deleteNotification(NotificationModel notification) async {
    await notification.delete();
  }

  // ---- Backup Methods ----
  static Future<void> saveBackup(BackupModel backup) async {
    final box = Hive.box<BackupModel>(Constants.backupsBox);
    await box.add(backup);
  }

  static List<BackupModel> getUserBackups(String userId) {
    final box = Hive.box<BackupModel>(Constants.backupsBox);
    return box.values.where((b) => b.userId == userId).toList();
  }

  static Future<void> deleteBackup(BackupModel backup) async {
    await backup.delete();
  }

  // ---- Settings Methods ----
  static Future<void> saveSettings(String key, dynamic value) async {
    final box = Hive.box<dynamic>(Constants.settingsBox);
    await box.put(key, value);
  }

  static dynamic getSettings(String key, {dynamic defaultValue}) {
    final box = Hive.box<dynamic>(Constants.settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  // ---- Clear All Data ----
  static Future<void> clearAllData() async {
    await Hive.box<UserModel>(Constants.usersBox).clear();
    await Hive.box<TransactionModel>(Constants.transactionsBox).clear();
    await Hive.box<FamilyModel>(Constants.familiesBox).clear();
    await Hive.box<TransferModel>(Constants.transfersBox).clear();
    await Hive.box<NotificationModel>(Constants.notificationsBox).clear();
    await Hive.box<BackupModel>(Constants.backupsBox).clear();
    await Hive.box<dynamic>(Constants.settingsBox).clear();
  }
}
