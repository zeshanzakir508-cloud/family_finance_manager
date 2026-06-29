import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/transfer_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

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
    
    if (box.isEmpty) {
      final notifications = [
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          title: 'Welcome to FinFam!',
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
          title: 'Family Feature Ready!',
          message: 'Create a family group and invite members to manage finances together.',
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
    final types = ['all', 'transfer', 'family', 'transaction', 'system'];
    final displayNames = ['All', 'Transfer', 'Family', 'Transaction', 'System'];

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
    final isTransfer = notification.type == NotificationType.transfer;
    final isPending = notification.actionData != null && notification.actionData!.contains('pending');

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
              Helpers.timeAgo(notification.createdAt ?? DateTime.now()),
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
          _handleNotificationTap(notification);
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
      await DatabaseService.markNotificationAsRead(notification);
      setState(() {});
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
      await DatabaseService.markNotificationAsRead(notification);
    }

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${unreadNotifications.length} notifications marked as read'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (notification.type == NotificationType.transfer && notification.relatedId != null) {
      _showTransferActionsDialog(notification);
    } else if (notification.type == NotificationType.family && notification.relatedId != null) {
      Navigator.pushNamed(context, '/family-management');
    }
  }

  void _showTransferActionsDialog(NotificationModel notification) {
    final transferId = notification.relatedId;
    if (transferId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transfer Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notification.message ?? '',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _approveTransfer(transferId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('✅ Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _rejectTransfer(transferId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('❌ Reject'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveTransfer(String transferId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    try {
      // Find the transfer transactions
      final box = Hive.box<TransactionModel>('transactions');
      final transactions = box.values
          .where((t) => t.transferId == transferId)
          .toList();

      if (transactions.isEmpty) {
        throw Exception('Transfer not found');
      }

      // Update both transactions to 'approved'
      for (var t in transactions) {
        final updated = t.copyWith(transferStatus: 'approved');
        await updated.save();
      }

      // Update notification
      final notificationBox = Hive.box<NotificationModel>('notifications');
      for (var n in notificationBox.values) {
        if (n.relatedId == transferId) {
          final updated = n.copyWith(
            title: 'Transfer Approved ✅',
            message: 'You have approved the transfer.',
            isRead: true,
          );
          await updated.save();
          break;
        }
      }

      // Create completion notification
      await NotificationService.notifyTransferApproved(
        transferId,
        userId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectTransfer(String transferId) async {
    try {
      // Find the transfer transactions
      final box = Hive.box<TransactionModel>('transactions');
      final transactions = box.values
          .where((t) => t.transferId == transferId)
          .toList();

      if (transactions.isEmpty) {
        throw Exception('Transfer not found');
      }

      // Update both transactions to 'rejected'
      for (var t in transactions) {
        final updated = t.copyWith(transferStatus: 'rejected');
        await updated.save();
      }

      // Update notification
      final notificationBox = Hive.box<NotificationModel>('notifications');
      for (var n in notificationBox.values) {
        if (n.relatedId == transferId) {
          final updated = n.copyWith(
            title: 'Transfer Rejected ❌',
            message: 'You have rejected the transfer.',
            isRead: true,
          );
          await updated.save();
          break;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
