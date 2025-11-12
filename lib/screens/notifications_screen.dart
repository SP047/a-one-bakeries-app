import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Notifications Screen
/// 
/// Displays system notifications like low stock alerts,
/// pending tasks, upcoming expiry dates, etc.

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  // Mock notifications (you can replace with real data from database later)
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 1,
      type: 'info',
      title: 'Welcome to A-One Bakeries!',
      message: 'Your business management app is ready to use.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationItem(
      id: 2,
      type: 'success',
      title: 'Order Completed',
      message: 'Driver John completed delivery for 5 trollies of bread.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    NotificationItem(
      id: 3,
      type: 'warning',
      title: 'Low Stock Alert',
      message: 'Flour stock is running low. Consider restocking soon.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read button
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(_notifications[index]);
              },
            ),
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(NotificationItem notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'success':
        icon = Icons.check_circle;
        color = AppTheme.successGreen;
        break;
      case 'warning':
        icon = Icons.warning;
        color = AppTheme.secondaryOrange;
        break;
      case 'error':
        icon = Icons.error;
        color = AppTheme.errorRed;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? null : AppTheme.lightCream,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 8),
            Text(
              _dateFormat.format(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkBrown.withOpacity(0.5),
                  ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: !notification.isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBrown,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  /// Mark notification as read
  void _markAsRead(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });
  }

  /// Mark all notifications as read
  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppTheme.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Notification Item Model
class NotificationItem {
  final int id;
  final String type; // 'info', 'success', 'warning', 'error'
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}