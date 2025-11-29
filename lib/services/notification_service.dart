import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';

/// ============================================================================
/// NOTIFICATION SERVICE
/// ============================================================================
/// 
/// This service checks for important alerts like:
/// - Expiring driver licenses
/// - Expired driver licenses
/// - Expiring vehicle license disks
/// - Expired vehicle license disks
/// 
/// Used by Dashboard and Notifications screens.
/// ============================================================================

class NotificationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ==========================================================================
  // NOTIFICATION ITEM CLASS
  // ==========================================================================
  
  /// Get all notifications (combines all alert types)
  Future<List<NotificationItem>> getAllNotifications() async {
    List<NotificationItem> notifications = [];

    // Get license notifications
    final licenseNotifications = await getLicenseNotifications();
    notifications.addAll(licenseNotifications);

    // Get vehicle disk notifications
    final vehicleDiskNotifications = await getVehicleDiskNotifications();
    notifications.addAll(vehicleDiskNotifications);

    // Sort by priority (expired first, then by days until expiry)
    notifications.sort((a, b) {
      // Expired items first
      if (a.type == 'expired' && b.type != 'expired') return -1;
      if (b.type == 'expired' && a.type != 'expired') return 1;
      // Then by timestamp (newest first)
      return b.timestamp.compareTo(a.timestamp);
    });

    return notifications;
  }

  // ==========================================================================
  // DRIVER LICENSE NOTIFICATIONS
  // ==========================================================================

  /// Get all license-related notifications
  Future<List<NotificationItem>> getLicenseNotifications() async {
    List<NotificationItem> notifications = [];

    // Get all driver licenses
    final licenses = await _dbHelper.getAllDriverLicenses();

    for (var license in licenses) {
      // Get the employee name
      final employee = await _dbHelper.getEmployeeById(license.employeeId);
      if (employee == null) continue;

      final daysUntilExpiry = license.daysUntilExpiry;

      if (daysUntilExpiry < 0) {
        // EXPIRED
        notifications.add(NotificationItem(
          id: license.id!,
          type: 'expired',
          category: 'license',
          title: 'License EXPIRED!',
          message: '${employee.fullName}\'s driver license expired ${daysUntilExpiry.abs()} days ago. Please renew immediately!',
          timestamp: DateTime.now(),
          severity: NotificationSeverity.critical,
          employeeId: employee.id,
          employeeName: employee.fullName,
          daysUntilExpiry: daysUntilExpiry,
        ));
      } else if (daysUntilExpiry <= 30) {
        // EXPIRING VERY SOON (within 30 days)
        notifications.add(NotificationItem(
          id: license.id!,
          type: 'expiring_soon',
          category: 'license',
          title: 'License Expiring Soon!',
          message: '${employee.fullName}\'s driver license expires in $daysUntilExpiry days. Schedule a renewal.',
          timestamp: DateTime.now(),
          severity: NotificationSeverity.high,
          employeeId: employee.id,
          employeeName: employee.fullName,
          daysUntilExpiry: daysUntilExpiry,
        ));
      } else if (daysUntilExpiry <= 90) {
        // EXPIRING (within 90 days)
        notifications.add(NotificationItem(
          id: license.id!,
          type: 'expiring',
          category: 'license',
          title: 'License Expiring',
          message: '${employee.fullName}\'s driver license expires in $daysUntilExpiry days.',
          timestamp: DateTime.now(),
          severity: NotificationSeverity.medium,
          employeeId: employee.id,
          employeeName: employee.fullName,
          daysUntilExpiry: daysUntilExpiry,
        ));
      }
    }

    return notifications;
  }

  /// Get count of critical notifications (for badge)
  Future<int> getCriticalNotificationCount() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => 
      n.severity == NotificationSeverity.critical || 
      n.severity == NotificationSeverity.high
    ).length;
  }

  /// Get count of all notifications
  Future<int> getTotalNotificationCount() async {
    final notifications = await getAllNotifications();
    return notifications.length;
  }

  /// Get expiring licenses summary for dashboard
  Future<LicenseExpiryStats> getLicenseExpiryStats() async {
    final licenses = await _dbHelper.getAllDriverLicenses();
    
    int expired = 0;
    int expiringSoon = 0; // within 30 days
    int expiringLater = 0; // within 90 days

    for (var license in licenses) {
      final days = license.daysUntilExpiry;
      if (days < 0) {
        expired++;
      } else if (days <= 30) {
        expiringSoon++;
      } else if (days <= 90) {
        expiringLater++;
      }
    }

    return LicenseExpiryStats(
      expired: expired,
      expiringSoon: expiringSoon,
      expiringLater: expiringLater,
      total: licenses.length,
    );
  }

  // ==========================================================================
  // VEHICLE DISK NOTIFICATIONS
  // ==========================================================================

  /// Get all vehicle disk-related notifications
  Future<List<NotificationItem>> getVehicleDiskNotifications() async {
    List<NotificationItem> notifications = [];

    // Get all vehicles
    final vehicles = await _dbHelper.getAllVehicles();

    for (var vehicle in vehicles) {
      // Skip vehicles without disk data
      if (vehicle.licenseDiskExpiry == null) continue;

      final daysUntilExpiry = vehicle.daysUntilDiskExpiry;

      if (daysUntilExpiry < 0) {
        // EXPIRED
        notifications.add(NotificationItem(
          id: vehicle.id!,
          type: 'expired',
          category: 'vehicle_disk',
          title: 'Vehicle Disk EXPIRED!',
          message: '${vehicle.fullName} (${vehicle.registrationNumber}) license disk expired ${daysUntilExpiry.abs()} days ago. Renew immediately!',
          timestamp: DateTime.now(),
          severity: NotificationSeverity.critical,
          vehicleId: vehicle.id,
          vehicleName: vehicle.fullName,
          daysUntilExpiry: daysUntilExpiry,
        ));
      } else if (daysUntilExpiry <= 30) {
        // EXPIRING VERY SOON (within 30 days)
        notifications.add(NotificationItem(
          id: vehicle.id!,
          type: 'expiring_soon',
          category: 'vehicle_disk',
          title: 'Vehicle Disk Expiring Soon!',
          message: '${vehicle.fullName} (${vehicle.registrationNumber}) license disk expires in $daysUntilExpiry days. Schedule a renewal.',
          timestamp: DateTime.now(),
          severity: NotificationSeverity.high,
          vehicleId: vehicle.id,
          vehicleName: vehicle.fullName,
          daysUntilExpiry: daysUntilExpiry,
        ));
      } else if (daysUntilExpiry <= 90) {
        // EXPIRING (within 90 days)
        notifications.add(NotificationItem(
          id: vehicle.id!,
          type: 'expiring',
          category: 'vehicle_disk',
          title: 'Vehicle Disk Expiring',
          message: '${vehicle.fullName} (${vehicle.registrationNumber}) license disk expires in $daysUntilExpiry days.',
          timestamp: DateTime.now(),
          severity: NotificationSeverity.medium,
          vehicleId: vehicle.id,
          vehicleName: vehicle.fullName,
          daysUntilExpiry: daysUntilExpiry,
        ));
      }
    }

    return notifications;
  }

  /// Get combined expiry stats for dashboard (licenses + vehicle disks)
  Future<CombinedExpiryStats> getCombinedExpiryStats() async {
    final licenseStats = await getLicenseExpiryStats();
    final vehicleDiskStats = await getVehicleDiskExpiryStats();
    
    return CombinedExpiryStats(
      licenseStats: licenseStats,
      vehicleDiskStats: vehicleDiskStats,
    );
  }

  /// Get vehicle disk expiry statistics
  Future<VehicleDiskExpiryStats> getVehicleDiskExpiryStats() async {
    final vehicles = await _dbHelper.getAllVehicles();
    
    int expired = 0;
    int expiringSoon = 0; // within 30 days
    int expiringLater = 0; // within 90 days
    int total = 0;

    for (var vehicle in vehicles) {
      if (vehicle.licenseDiskExpiry == null) continue;
      
      total++;
      final days = vehicle.daysUntilDiskExpiry;
      
      if (days < 0) {
        expired++;
      } else if (days <= 30) {
        expiringSoon++;
      } else if (days <= 90) {
        expiringLater++;
      }
    }

    return VehicleDiskExpiryStats(
      expired: expired,
      expiringSoon: expiringSoon,
      expiringLater: expiringLater,
      total: total,
    );
  }
}

// ============================================================================
// NOTIFICATION ITEM MODEL
// ============================================================================

/// Severity levels for notifications
enum NotificationSeverity {
  critical,  // Red - Expired
  high,      // Orange - Expiring within 30 days
  medium,    // Yellow - Expiring within 90 days
  low,       // Blue - Information
}

/// Represents a single notification
class NotificationItem {
  final int id;
  final String type;           // 'expired', 'expiring_soon', 'expiring', 'info'
  final String category;       // 'license', 'vehicle_disk', 'stock', etc.
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationSeverity severity;
  final int? employeeId;
  final String? employeeName;
  final int? vehicleId;
  final String? vehicleName;
  final int daysUntilExpiry;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.severity,
    this.employeeId,
    this.employeeName,
    this.vehicleId,
    this.vehicleName,
    this.daysUntilExpiry = 0,
    this.isRead = false,
  });
}

// ============================================================================
// LICENSE EXPIRY STATS MODEL
// ============================================================================

/// Statistics about license expiry for dashboard
class LicenseExpiryStats {
  final int expired;
  final int expiringSoon;   // within 30 days
  final int expiringLater;  // within 90 days
  final int total;

  LicenseExpiryStats({
    required this.expired,
    required this.expiringSoon,
    required this.expiringLater,
    required this.total,
  });

  /// Check if there are any alerts
  bool get hasAlerts => expired > 0 || expiringSoon > 0 || expiringLater > 0;

  /// Get total alerts count
  int get totalAlerts => expired + expiringSoon + expiringLater;
}

// ============================================================================
// VEHICLE DISK EXPIRY STATS MODEL
// ============================================================================

/// Statistics about vehicle disk expiry for dashboard
class VehicleDiskExpiryStats {
  final int expired;
  final int expiringSoon;   // within 30 days
  final int expiringLater;  // within 90 days
  final int total;

  VehicleDiskExpiryStats({
    required this.expired,
    required this.expiringSoon,
    required this.expiringLater,
    required this.total,
  });

  /// Check if there are any alerts
  bool get hasAlerts => expired > 0 || expiringSoon > 0 || expiringLater > 0;

  /// Get total alerts count
  int get totalAlerts => expired + expiringSoon + expiringLater;
}

// ============================================================================
// COMBINED EXPIRY STATS MODEL
// ============================================================================

/// Combined statistics for both licenses and vehicle disks
class CombinedExpiryStats {
  final LicenseExpiryStats licenseStats;
  final VehicleDiskExpiryStats vehicleDiskStats;

  CombinedExpiryStats({
    required this.licenseStats,
    required this.vehicleDiskStats,
  });

  /// Check if there are any alerts (licenses or vehicle disks)
  bool get hasAlerts => licenseStats.hasAlerts || vehicleDiskStats.hasAlerts;

  /// Get total alerts count (licenses + vehicle disks)
  int get totalAlerts => licenseStats.totalAlerts + vehicleDiskStats.totalAlerts;

  /// Get total expired count
  int get totalExpired => licenseStats.expired + vehicleDiskStats.expired;

  /// Get total expiring soon count
  int get totalExpiringSoon => licenseStats.expiringSoon + vehicleDiskStats.expiringSoon;
}