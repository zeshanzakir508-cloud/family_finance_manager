// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/local_storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  // ✅ FIXED: Removed unused field or kept as is (it's used in commented code)
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => n.isUnread).toList();
  }

  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => !n.isUnread).toList();
  }

  int get unreadCount => unreadNotifications.length;

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadNotifications(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Try local storage first
      _notifications = await LocalStorageService.getNotificationsByUser(userId);
      
      // If no local notifications, load from Firestore
      if (_notifications.isEmpty) {
        // TODO: Implement Firestore fetch
        // _notifications = await _notificationService.getNotificationsByUser(userId);
        // await LocalStorageService.saveNotifications(_notifications);
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshNotifications(String userId) async {
    await loadNotifications(userId);
  }

  // ============================================================
  // CRUD
  // ============================================================

  Future<void> addNotification(NotificationModel notification) async {
    try {
      _notifications.insert(0, notification);
      await LocalStorageService.saveNotification(notification);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await LocalStorageService.saveNotification(_notifications[index]);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      for (var i = 0; i < _notifications.length; i++) {
        if (_notifications[i].isUnread) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
          await LocalStorageService.saveNotification(_notifications[i]);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      _notifications.removeWhere((n) => n.id == id);
      await LocalStorageService.deleteNotification(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      _notifications.clear();
      await LocalStorageService.clearNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // ============================================================
  // SYSTEM NOTIFICATIONS
  // ============================================================

  Future<void> sendTransactionNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: title,
        body: body,
        payload: payload,
      );
      
      // Add to local list
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: title,
        message: body,
        type: NotificationType.transaction,
        isRead: false,
        createdAt: DateTime.now(),
        actionData: payload,
      );
      
      await addNotification(notification);
    } catch (e) {
      debugPrint('Error sending transaction notification: $e');
    }
  }

  Future<void> sendFamilyNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: title,
        body: body,
        payload: payload,
      );
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: title,
        message: body,
        type: NotificationType.family,
        isRead: false,
        createdAt: DateTime.now(),
        actionData: payload,
      );
      
      await addNotification(notification);
    } catch (e) {
      debugPrint('Error sending family notification: $e');
    }
  }

  Future<void> sendSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: title,
        body: body,
        payload: payload,
      );
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: title,
        message: body,
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
        actionData: payload,
      );
      
      await addNotification(notification);
    } catch (e) {
      debugPrint('Error sending system notification: $e');
    }
  }

  // ============================================================
  // SCHEDULED NOTIFICATIONS
  // ============================================================

  Future<void> scheduleDailyReminder() async {
    try {
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: '📊 Daily Reminder',
        body: 'Don\'t forget to log your daily expenses!',
        scheduledTime: DateTime.now().add(const Duration(hours: 24)),
        payload: 'reminder',
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  Future<void> scheduleBudgetAlert({
    required String category,
    required double spent,
    required double budget,
  }) async {
    try {
      final percentage = (spent / budget * 100).toStringAsFixed(0);
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: '⚠️ Budget Alert',
        body: 'You have used $percentage% of your $category budget (\$$spent/\$$budget)',
        payload: 'budget',
      );
    } catch (e) {
      debugPrint('Error scheduling budget alert: $e');
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
