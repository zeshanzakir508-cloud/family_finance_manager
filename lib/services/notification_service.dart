import '../models/notification_model.dart';
import '../models/transfer_model.dart';
import '../models/family_model.dart';
import 'database_service.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Create a transfer notification
  static Future<void> notifyTransferRequest(TransferModel transfer) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: transfer.toMemberId,
      title: 'Transfer Request',
      message: '${transfer.fromMemberName} requested \$${transfer.amount?.toStringAsFixed(2)} from you',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transfer.id,
      relatedId: transfer.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  // Create transfer approval notification
  static Future<void> notifyTransferApproved(TransferModel transfer) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: transfer.fromMemberId,
      title: 'Transfer Approved',
      message: '${transfer.toMemberName} approved your transfer of \$${transfer.amount?.toStringAsFixed(2)}',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transfer.id,
      relatedId: transfer.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  // Create transfer rejection notification
  static Future<void> notifyTransferRejected(TransferModel transfer) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: transfer.fromMemberId,
      title: 'Transfer Rejected',
      message: '${transfer.toMemberName} rejected your transfer of \$${transfer.amount?.toStringAsFixed(2)}',
      type: NotificationType.transfer,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transfer.id,
      relatedId: transfer.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  // Create family invite notification
  static Future<void> notifyFamilyInvite(String userId, FamilyModel family) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'Family Invite',
      message: 'You have been invited to join "${family.name}"',
      type: NotificationType.family,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: family.id,
      relatedId: family.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  // Create member joined notification
  static Future<void> notifyMemberJoined(FamilyModel family, String memberName, String adminId) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: adminId,
      title: 'New Member Joined',
      message: '$memberName has joined "${family.name}"',
      type: NotificationType.family,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: family.id,
      relatedId: family.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  // Create transaction notification
  static Future<void> notifyTransactionAdded(String userId, TransactionModel transaction) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'Transaction Added',
      message: '${transaction.typeDisplay} of \$${transaction.amount?.toStringAsFixed(2)} added: ${transaction.description}',
      type: NotificationType.transaction,
      createdAt: DateTime.now(),
      isRead: false,
      actionData: transaction.id,
      relatedId: transaction.id,
    );
    await DatabaseService.saveNotification(notification);
  }

  // Get unread count for user
  static Future<int> getUnreadCount(String userId) async {
    final notifications = await DatabaseService.getUserNotifications(userId);
    return notifications.where((n) => n.isUnread).length;
  }

  // Mark all as read for user
  static Future<void> markAllAsRead(String userId) async {
    final notifications = await DatabaseService.getUserNotifications(userId);
    for (var notification in notifications) {
      if (notification.isUnread) {
        await DatabaseService.markNotificationAsRead(notification);
      }
    }
  }
}
