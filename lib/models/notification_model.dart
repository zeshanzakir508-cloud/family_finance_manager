import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'notification_model.g.dart'; // ✅ Already correct

@HiveType(typeId: 5)
enum NotificationType {
  @HiveField(0)
  transfer,
  @HiveField(1)
  family,
  @HiveField(2)
  transaction,
  @HiveField(3)
  system,
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
  String? actionData;

  @HiveField(8)
  String? relatedId;

  NotificationModel({
    this.id,
    this.userId,
    this.title,
    this.message,
    this.type,
    this.isRead = false,
    this.createdAt,
    this.actionData,
    this.relatedId,
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
      'actionData': actionData,
      'relatedId': relatedId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: json['type'] != null && json['type'] is int
          ? NotificationType.values[json['type']]
          : null, // ✅ Fixed: added type check
      isRead: json['isRead'] ?? false, // ✅ Fixed: default value
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      actionData: json['actionData'],
      relatedId: json['relatedId'],
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
    String? actionData,
    String? relatedId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionData: actionData ?? this.actionData,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  String get typeDisplay {
    switch (type) {
      case NotificationType.transfer:
        return 'Transfer';
      case NotificationType.family:
        return 'Family';
      case NotificationType.transaction:
        return 'Transaction';
      case NotificationType.system:
        return 'System';
      default:
        return 'Unknown';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.transfer:
        return Icons.swap_horiz;
      case NotificationType.family:
        return Icons.family_restroom;
      case NotificationType.transaction:
        return Icons.attach_money;
      case NotificationType.system:
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.transfer:
        return Colors.blue;
      case NotificationType.family:
        return Colors.teal;
      case NotificationType.transaction:
        return Colors.green;
      case NotificationType.system:
        return Colors.purple;
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
