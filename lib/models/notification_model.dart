import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 5)
enum NotificationType {
  @HiveField(0)
  approval,
  @HiveField(1)
  transaction,
  @HiveField(2)
  reminder,
  @HiveField(3)
  system,
  @HiveField(4)
  family,
  @HiveField(5)
  budget,
  @HiveField(6)
  invite,
}

@HiveType(typeId: 6)
class NotificationModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? message;

  @HiveField(4)
  NotificationType? type;

  @HiveField(5)
  bool? isRead;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  String? data;

  @HiveField(8)
  String? actionUrl;

  @HiveField(9)
  String? senderId;

  @HiveField(10)
  String? senderName;

  @HiveField(11)
  String? imageUrl;

  @HiveField(12)
  String? relatedId;

  @HiveField(13)
  String? relatedType;

  @HiveField(14)
  DateTime? readAt;

  NotificationModel({
    this.id,
    this.userId,
    this.title,
    this.message,
    this.type,
    this.isRead = false,
    this.createdAt,
    this.data,
    this.actionUrl,
    this.senderId,
    this.senderName,
    this.imageUrl,
    this.relatedId,
    this.relatedType,
    this.readAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type?.index,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
      'data': data,
      'actionUrl': actionUrl,
      'senderId': senderId,
      'senderName': senderName,
      'imageUrl': imageUrl,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: json['type'] != null 
          ? NotificationType.values[json['type']] 
          : null,
      isRead: json['isRead'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      data: json['data'],
      actionUrl: json['actionUrl'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      imageUrl: json['imageUrl'],
      relatedId: json['relatedId'],
      relatedType: json['relatedType'],
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt']) 
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    String? data,
    String? actionUrl,
    String? senderId,
    String? senderName,
    String? imageUrl,
    String? relatedId,
    String? relatedType,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      imageUrl: imageUrl ?? this.imageUrl,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      readAt: readAt ?? this.readAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.approval:
        return 'Approval';
      case NotificationType.transaction:
        return 'Transaction';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.system:
        return 'System';
      case NotificationType.family:
        return 'Family';
      case NotificationType.budget:
        return 'Budget';
      case NotificationType.invite:
        return 'Invite';
      default:
        return 'Unknown';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.approval:
        return Icons.verified_user;
      case NotificationType.transaction:
        return Icons.attach_money;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.family:
        return Icons.family_restroom;
      case NotificationType.budget:
        return Icons.account_balance;
      case NotificationType.invite:
        return Icons.mail_outline;
      default:
        return Icons.notifications;
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.approval:
        return Colors.green;
      case NotificationType.transaction:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.system:
        return Colors.purple;
      case NotificationType.family:
        return Colors.teal;
      case NotificationType.budget:
        return Colors.amber;
      case NotificationType.invite:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final difference = DateTime.now().difference(createdAt!);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  bool get isUnread => isRead == false;
}
