import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/services/notification_scheduler.dart';

/// Notification Settings Screen
/// 
/// Allows users to:
/// - Enable/disable scheduled reminders
/// - Schedule all reminders manually
/// - Test notifications
/// - View pending notifications count

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationScheduler _scheduler = NotificationScheduler();
  int _pendingCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final count = await _scheduler.getPendingNotificationsCount();
    setState(() {
      _pendingCount = count;
    });
  }

  Future<void> _scheduleAllReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _scheduler.scheduleAllReminders();
      await _loadPendingCount();
      
      if (mounted) {
        _showSuccessSnackBar('All reminders scheduled successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error scheduling reminders: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotification() async {
    try {
      await _scheduler.sendImmediateNotification(
        title: '🔔 Test Notification',
        body: 'This is a test notification from A-One Bakeries App!',
      );
      
      if (mounted) {
        _showSuccessSnackBar('Test notification sent!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error sending test notification: $e');
      }
    }
  }

  Future<void> _cancelAllReminders() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel All Reminders?'),
        content: const Text('This will cancel all scheduled notifications. You can reschedule them anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _scheduler.cancelAllNotifications();
      await _loadPendingCount();
      
      if (mounted) {
        _showSuccessSnackBar('All reminders cancelled');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            'Scheduled Reminders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatic notifications for license and vehicle disk renewals',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Pending Notifications Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: AppTheme.primaryBrown,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Reminders',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_pendingCount scheduled notifications',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.darkBrown.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadPendingCount,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reminder Schedule Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryBrown),
                      const SizedBox(width: 8),
                      Text(
                        'Reminder Schedule',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('30 days before expiry'),
                  _buildInfoRow('14 days before expiry'),
                  _buildInfoRow('7 days before expiry'),
                  _buildInfoRow('1 day before expiry'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Schedule All Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _scheduleAllReminders,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.schedule),
            label: Text(_isLoading ? 'Scheduling...' : 'Schedule All Reminders'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Test Notification Button
          OutlinedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications),
            label: const Text('Send Test Notification'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel All Button
          OutlinedButton.icon(
            onPressed: _cancelAllReminders,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel All Reminders'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              side: const BorderSide(color: AppTheme.errorRed),
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reminders are automatically scheduled when you add or update licenses and vehicle disks. Use "Schedule All Reminders" to refresh all notifications.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade900,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.successGreen),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
