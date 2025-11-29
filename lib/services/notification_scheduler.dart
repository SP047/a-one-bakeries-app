import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';

/// ============================================================================
/// NOTIFICATION SCHEDULER SERVICE
/// ============================================================================
/// 
/// Schedules local notifications for:
/// - Driver license expiry reminders (30, 14, 7, 1 days before)
/// - Vehicle license disk expiry reminders (30, 14, 7, 1 days before)
/// 
/// Works on Android and iOS mobile platforms.
/// ============================================================================

class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  bool _initialized = false;

  /// Initialize the notification system
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _requestPermissions();

    _initialized = true;
  }

  /// Request notification permissions (iOS)
  Future<void> _requestPermissions() async {
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation when notification is tapped
    // You can navigate to specific screens based on payload
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule all reminders (licenses + vehicle disks)
  Future<void> scheduleAllReminders() async {
    await initialize();
    
    // Cancel all existing notifications first
    await _notificationsPlugin.cancelAll();
    
    // Schedule driver license reminders
    await _scheduleLicenseReminders();
    
    // Schedule vehicle disk reminders
    await _scheduleVehicleDiskReminders();
    
    print('✅ All reminders scheduled successfully');
  }

  /// Schedule driver license expiry reminders
  Future<void> _scheduleLicenseReminders() async {
    final licenses = await _dbHelper.getAllDriverLicenses();
    
    for (var license in licenses) {
      final employee = await _dbHelper.getEmployeeById(license.employeeId);
      if (employee == null) continue;
      
      final expiryDate = license.expiryDate;
      final now = DateTime.now();
      
      // Schedule reminders at 30, 14, 7, and 1 day before expiry
      final reminderDays = [30, 14, 7, 1];
      
      for (var days in reminderDays) {
        final reminderDate = expiryDate.subtract(Duration(days: days));
        
        // Only schedule if reminder date is in the future
        if (reminderDate.isAfter(now)) {
          await _scheduleNotification(
            id: license.id! * 1000 + days, // Unique ID
            title: '🚗 Driver License Expiring Soon',
            body: '${employee.fullName}\'s license expires in $days days on ${_formatDate(expiryDate)}',
            scheduledDate: reminderDate,
            payload: 'license_${license.id}',
          );
        }
      }
    }
  }

  /// Schedule vehicle license disk expiry reminders
  Future<void> _scheduleVehicleDiskReminders() async {
    final vehicles = await _dbHelper.getAllVehicles();
    
    for (var vehicle in vehicles) {
      // Skip vehicles without disk data
      if (vehicle.licenseDiskExpiry == null) continue;
      
      final expiryDate = vehicle.licenseDiskExpiry!;
      final now = DateTime.now();
      
      // Schedule reminders at 30, 14, 7, and 1 day before expiry
      final reminderDays = [30, 14, 7, 1];
      
      for (var days in reminderDays) {
        final reminderDate = expiryDate.subtract(Duration(days: days));
        
        // Only schedule if reminder date is in the future
        if (reminderDate.isAfter(now)) {
          await _scheduleNotification(
            id: vehicle.id! * 10000 + days, // Unique ID (different range from licenses)
            title: '🚙 Vehicle Disk Expiring Soon',
            body: '${vehicle.fullName} (${vehicle.registrationNumber}) disk expires in $days days on ${_formatDate(expiryDate)}',
            scheduledDate: reminderDate,
            payload: 'vehicle_disk_${vehicle.id}',
          );
        }
      }
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'renewal_reminders', // Channel ID
      'Renewal Reminders', // Channel name
      channelDescription: 'Reminders for license and vehicle disk renewals',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert to timezone-aware datetime
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Send immediate notification (for testing or critical alerts)
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'immediate_alerts',
      'Immediate Alerts',
      channelDescription: 'Critical alerts that need immediate attention',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.length;
  }

  /// Format date for notification
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
