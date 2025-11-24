import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/services/notification_service.dart';
import 'package:a_one_bakeries_app/screens/employee_details_screen.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// NOTIFICATIONS SCREEN - COMPLETE VERSION
/// ============================================================================
/// 
/// Displays real notifications from the app:
/// - Expiring driver licenses (90, 60, 30 days)
/// - Expired driver licenses
/// - Beautiful color-coded severity system
/// - Direct navigation to employee details
/// ============================================================================

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Load all notifications
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getAllNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Navigate to employee details
  Future<void> _navigateToEmployee(int? employeeId) async {
    if (employeeId == null) return;

    final employee = await _dbHelper.getEmployeeById(employeeId);
    if (employee != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmployeeDetailsScreen(employee: employee),
        ),
      ).then((_) => _loadNotifications()); // Refresh on return
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_notifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primaryBrown,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
                ),
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(NotificationItem notification) {
    final colors = _getNotificationColors(notification.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors['border']!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: notification.employeeId != null
            ? () => _navigateToEmployee(notification.employeeId)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors['background'],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification),
                      color: colors['icon'],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors['text'],
                              ),
                        ),
                        const SizedBox(height: 4),

                        // Message
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.darkBrown.withOpacity(0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Footer
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors['background'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(notification.category),
                          size: 14,
                          color: colors['icon'],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getCategoryLabel(notification.category),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors['icon'],
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Days indicator
                  if (notification.daysUntilExpiry != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors['icon']!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notification.daysUntilExpiry < 0
                            ? '${notification.daysUntilExpiry.abs()} days overdue'
                            : '${notification.daysUntilExpiry} days left',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors['icon'],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),

              // View Details Button
              if (notification.employeeId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEmployee(notification.employeeId),
                    icon: const Icon(Icons.person, size: 18),
                    label: Text('View ${notification.employeeName ?? "Employee"}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors['icon'],
                      side: BorderSide(color: colors['icon']!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state (All clear!)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.successGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Clear! 🎉',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending notifications',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'All licenses are up to date',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  /// Get colors based on severity
  Map<String, Color> _getNotificationColors(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return {
          'background': Colors.red.shade50,
          'border': Colors.red.shade200,
          'icon': Colors.red.shade700,
          'text': Colors.red.shade800,
        };
      case NotificationSeverity.high:
        return {
          'background': Colors.orange.shade50,
          'border': Colors.orange.shade200,
          'icon': Colors.orange.shade700,
          'text': Colors.orange.shade800,
        };
      case NotificationSeverity.medium:
        return {
          'background': Colors.amber.shade50,
          'border': Colors.amber.shade200,
          'icon': Colors.amber.shade700,
          'text': Colors.amber.shade800,
        };
      case NotificationSeverity.low:
        return {
          'background': Colors.blue.shade50,
          'border': Colors.blue.shade200,
          'icon': Colors.blue.shade700,
          'text': Colors.blue.shade800,
        };
    }
  }

  /// Get icon based on notification type
  IconData _getNotificationIcon(NotificationItem notification) {
    if (notification.type == 'expired') {
      return Icons.error;
    } else if (notification.type == 'expiring_soon') {
      return Icons.warning;
    } else if (notification.type == 'expiring') {
      return Icons.schedule;
    }
    return Icons.info;
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'license':
        return Icons.badge;
      case 'vehicle_disk':
        return Icons.directions_car;
      default:
        return Icons.notifications;
    }
  }

  /// Get category label
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'license':
        return 'Driver License';
      case 'vehicle_disk':
        return 'Vehicle Disk';
      default:
        return 'Alert';
    }
  }
}