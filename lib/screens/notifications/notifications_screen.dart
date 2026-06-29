import '../models/notification_model.dart';
import '../models/transfer_model.dart';
import '../models/family_model.dart';
import '../models/transaction_model.dart';
import 'database_service.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // ============================================================
  // TRANSFER NOTIFICATIONS
  // ============================================================

  static Future<void> notifyTransferRequest(
    String fromName,
    String toName,
    double amount,
    String transferId,
    String toUserId,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: toUserId,
      title: '💰 Transfer Request',
      message: '$fromName requested \$${amount.toStringAsFixed(2)} from you',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transferId,
      relatedId: transferId,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyTransferApproved(
    String transferId,
    String fromUserId,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: fromUserId,
      title: '✅ Transfer Approved',
      message: 'Your transfer request has been approved!',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transferId,
      relatedId: transferId,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyTransferRejected(
    String transferId,
    String fromUserId,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: fromUserId,
      title: '❌ Transfer Rejected',
      message: 'Your transfer request has been rejected.',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transferId,
      relatedId: transferId,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyTransferCompleted(
    String transferId,
    String fromUserId,
    String toUserId,
  ) async {
    final notification1 = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: fromUserId,
      title: '✅ Transfer Completed',
      message: 'Your transfer has been completed successfully!',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transferId,
      relatedId: transferId,
    );
    await DatabaseService.saveNotification(notification1);

    final notification2 = NotificationModel(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      userId: toUserId,
      title: '✅ Transfer Completed',
      message: 'The transfer has been completed successfully!',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transferId,
      relatedId: transferId,
    );
    await DatabaseService.saveNotification(notification2);
  }

  // ============================================================
  // FAMILY NOTIFICATIONS
  // ============================================================

  static Future<void> notifyFamilyInvite(String userId, FamilyModel family) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '👨‍👩‍👦 Family Invite',
      message: 'You have been invited to join "${family.name}"',
      type: NotificationType.family,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: family.id,
      relatedId: family.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyMemberJoined(FamilyModel family, String memberName, String adminId) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: adminId,
      title: '👋 New Member Joined',
      message: '$memberName has joined "${family.name}"',
      type: NotificationType.family,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: family.id,
      relatedId: family.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyMemberRemoved(FamilyModel family, String memberName, String adminId) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: adminId,
      title: '👋 Member Removed',
      message: '$memberName has left "${family.name}"',
      type: NotificationType.family,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: family.id,
      relatedId: family.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  // ============================================================
  // TRANSACTION NOTIFICATIONS
  // ============================================================

  static Future<void> notifyTransactionAdded(String userId, TransactionModel transaction) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '💳 Transaction Added',
      message: '${transaction.typeDisplay} of \$${transaction.amount?.toStringAsFixed(2)} added: ${transaction.description}',
      type: NotificationType.transaction,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transaction.id,
      relatedId: transaction.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyTransactionDeleted(String userId, TransactionModel transaction) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '🗑️ Transaction Deleted',
      message: '${transaction.typeDisplay} of \$${transaction.amount?.toStringAsFixed(2)} was deleted: ${transaction.description}',
      type: NotificationType.transaction,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transaction.id,
      relatedId: transaction.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyBudgetAlert(String userId, String category, double spent, double budget) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '⚠️ Budget Alert',
      message: 'You have spent \$${spent.toStringAsFixed(2)} on "$category". Budget is \$${budget.toStringAsFixed(2)}',
      type: NotificationType.system,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await DatabaseService.saveNotification(notification);
  }

  // ============================================================
  // SYSTEM NOTIFICATIONS
  // ============================================================

  static Future<void> notifySystemMessage(String userId, String title, String message) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.system,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyAppUpdate(String userId, String version, String changes) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '📱 App Update v$version',
      message: changes,
      type: NotificationType.system,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyAnnouncement(String userId, String title, String message) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '📢 $title',
      message: message,
      type: NotificationType.system,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await DatabaseService.saveNotification(notification);
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  static Future<int> getUnreadCount(String userId) async {
    final notifications = await DatabaseService.getUserNotifications(userId);
    return notifications.where((n) => n.isUnread).length;
  }

  static Future<void> markAllAsRead(String userId) async {
    final notifications = await DatabaseService.getUserNotifications(userId);
    for (var notification in notifications) {
      if (notification.isUnread) {
        await DatabaseService.markNotificationAsRead(notification);
      }
    }
  }

  static Future<void> deleteAllNotifications(String userId) async {
    final notifications = await DatabaseService.getUserNotifications(userId);
    for (var notification in notifications) {
      await DatabaseService.deleteNotification(notification);
    }
  }

  static Future<void> sendBulkNotification(List<String> userIds, String title, String message) async {
    for (var userId in userIds) {
      await notifySystemMessage(userId, title, message);
    }
  }

  // ============================================================
  // SCHEDULED NOTIFICATIONS
  // ============================================================

  static Future<void> scheduleDailyReminder(String userId) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '📊 Daily Finance Check',
      message: 'Don\'t forget to check your finances today!',
      type: NotificationType.system,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> scheduleWeeklyReport(String userId, double income, double expense) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '📈 Weekly Report',
      message: 'Income: \$${income.toStringAsFixed(2)} | Expenses: \$${expense.toStringAsFixed(2)} | Balance: \$${(income - expense).toStringAsFixed(2)}',
      type: NotificationType.system,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await DatabaseService.saveNotification(notification);
  }

  // ============================================================
  // TRANSFER STATUS CHECKS
  // ============================================================

  static Future<void> checkPendingTransfers() async {
    final box = Hive.box<TransactionModel>('transactions');
    final pendingTransfers = box.values
        .where((t) => t.transferStatus == 'pending' && t.type == 'transfer')
        .toList();

    // Group by transferId to avoid duplicates
    final transferIds = pendingTransfers.map((t) => t.transferId).toSet();
    
    for (var transferId in transferIds) {
      if (transferId == null) continue;
      
      // Check if transfer is older than 7 days
      final transfer = pendingTransfers.firstWhere((t) => t.transferId == transferId);
      if (transfer.createdAt != null) {
        final days = DateTime.now().difference(transfer.createdAt!).inDays;
        if (days >= 7) {
          // Auto-reject old pending transfers
          final transactions = box.values
              .where((t) => t.transferId == transferId)
              .toList();
          for (var t in transactions) {
            final updated = t.copyWith(transferStatus: 'rejected');
            await updated.save();
          }
        }
      }
    }
  }
}
