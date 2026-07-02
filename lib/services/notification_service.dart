import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'finfam_channel',
      'FinFam Notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'finfam_scheduled',
      'Scheduled Notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> notifyTransactionAdded({
    required String description,
    required double amount,
    required String type,
  }) async {
    final title = type == 'income' ? '💰 Income Added' : '💳 Expense Added';
    final body = '$description: ${type == 'income' ? '+' : '-'}\$${amount.toStringAsFixed(2)}';
    
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: title,
      body: body,
      payload: 'transaction',
    );
  }

  static Future<void> notifyTransferReceived({
    required String fromMember,
    required double amount,
    required String currency,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: '💸 Transfer Received',
      body: '$fromMember sent you $currency${amount.toStringAsFixed(2)}',
      payload: 'transfer',
    );
  }

  static Future<void> notifyTransferApproved({
    required String toMember,
    required double amount,
    required String currency,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: '✅ Transfer Approved',
      body: 'Your transfer of $currency${amount.toStringAsFixed(2)} to $toMember was approved',
      payload: 'transfer',
    );
  }

  static Future<void> notifyFamilyInvite({
    required String familyName,
    required String inviteCode,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: '👨‍👩‍👧‍👦 Family Invite',
      body: 'You have been invited to join $familyName. Use code: $inviteCode',
      payload: 'invite',
    );
  }

  static Future<void> notifyBudgetAlert({
    required String category,
    required double spent,
    required double budget,
  }) async {
    final percentage = (spent / budget * 100).toStringAsFixed(0);
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: '⚠️ Budget Alert',
      body: 'You have used $percentage% of your $category budget (\$$spent/\$$budget)',
      payload: 'budget',
    );
  }

  static Future<void> notifyDailyReminder() async {
    await scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: '📊 Daily Reminder',
      body: 'Don\'t forget to log your daily expenses!',
      scheduledTime: DateTime.now().add(const Duration(hours: 24)),
      payload: 'reminder',
    );
  }
}
