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

  static Future<void> notifyTransferRequest(TransferModel transfer) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: transfer.toMemberId,
      title: '💰 Transfer Request',
      message: '${transfer.fromMemberName} requested \$${transfer.amount?.toStringAsFixed(2)} from you',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transfer.id,
      relatedId: transfer.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  static Future<void> notifyTransferApproved(String transferId, String fromUserId) async {
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

  static Future<void> notifyTransferRejected(String transferId, String fromUserId) async {
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
}
