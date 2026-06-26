import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _addSampleNotifications();
  }

  Future<void> _addSampleNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    
    if (userId == null) return;

    final box = Hive.box<NotificationModel>('notifications');
    
    // Only add if empty
    if (box.isEmpty) {
      final notifications = [
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          title: 'Welcome to Family Finance Manager!',
          message: 'Start managing your family finances today.',
          type: NotificationType.system,
          createdAt: DateTime.now(),
          isRead: false,
        ),
        NotificationModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          userId: userId,
          title: 'Add Your First Transaction',
          message: 'Tap the + button to add your first income or expense.',
          type: NotificationType.transaction,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        NotificationModel(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          userId: userId,
          title: 'Family Feature Coming Soon!',
          message: 'Invite your family members to manage finances together.',
          type: NotificationType.family,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
      ];

      for (var notification in notifications) {
        await box.add(notification);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_outlined),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          // Notifications List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<NotificationModel>('notifications').listenable(),
              builder: (context, Box<NotificationModel> box, _) {
                final authService = Provider.of<AuthService>(context);
                final userId = authService.userId;
                
                // Filter by userId
                var notifications = box.values
                    .where((n) => n.userId == userId)
                    .toList()
                  ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
                
                final filteredNotifications = _filterType == 'all'
                    ? notifications
                    : notifications.where((n) => n.type?.name == _filterType).toList();

                if (filteredNotifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationTile(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final types = ['all', 'approval', 'transaction', 'reminder', 'system', 'family', 'budget', 'invite'];
    final displayNames = ['All', 'Approval', 'Transaction', 'Reminder', 'System', 'Family', 'Budget', 'Invite'];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        itemBuilder: (context, index) {
          final isSelected = _filterType == types[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(
                displayNames[index],
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterType = types[index];
                });
              },
              backgroundColor: AppTheme.surfaceColor,
              selectedColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: notification.isUnread 
          ? AppTheme.primaryColor.withOpacity(0.05)
          : null,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notification.typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.typeIcon,
            color: notification.typeColor,
            size: 24,
          ),
        ),
        title: Text(
          notification.title ?? 'Notification',
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message ?? '',
              style: AppTheme.captionStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification.timeAgo,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        trailing: notification.isUnread
            ? IconButton(
                icon: Icon(
                  Icons.mark_as_unread,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                onPressed: () => _markAsRead(notification),
                tooltip: 'Mark as read',
              )
            : null,
        onTap: () {
          _markAsRead(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens',
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isUnread == true) {
      final updated = notification.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      await updated.save();
    }
  }

  Future<void> _markAllAsRead() async {
    final box = Hive.box<NotificationModel>('notifications');
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    
    final unreadNotifications = box.values
        .where((n) => n.isUnread && n.userId == userId)
        .toList();
    
    for (var notification in unreadNotifications) {
      final updated = notification.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      await updated.save();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${unreadNotifications.length} notifications marked as read'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
