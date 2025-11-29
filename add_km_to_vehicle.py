# Complete script to add KM tracking to Vehicle model and database helper

import re

# ===== PART 1: Update Vehicle Model =====
print("Updating Vehicle model...")
with open('lib/models/vehicle_model.dart', 'r', encoding='utf-8') as f:
    vehicle_content = f.read()

# Add KM fields to Vehicle class after diskNumber
km_fields = '''  // NEW: KM Tracking Fields
  final int currentKm;              // Current odometer reading
  final int lastServiceKm;          // KM at last service
  final int serviceIntervalKm;      // KM between services (default: 10000)
  final int nextServiceKm;          // Calculated: lastServiceKm + serviceIntervalKm

  '''

# Insert after diskNumber field
vehicle_content = vehicle_content.replace(
    '  final String? diskNumber;           // Optional disk reference number\r\n\r\n  /// Timestamp when the vehicle record was created.',
    '  final String? diskNumber;           // Optional disk reference number\r\n\r\n' + km_fields + '  /// Timestamp when the vehicle record was created.'
)

# Add to constructor parameters
vehicle_content = vehicle_content.replace(
    '    this.diskNumber,\r\n    DateTime? createdAt,',
    '''    this.diskNumber,
    this.currentKm = 0,
    this.lastServiceKm = 0,
    this.serviceIntervalKm = 10000,
    int? nextServiceKm,
    DateTime? createdAt,'''
)

# Update constructor initialization
vehicle_content = vehicle_content.replace(
    '  })  : createdAt = createdAt ?? DateTime.now(),\r\n        updatedAt = updatedAt ?? DateTime.now();',
    '''  })  : nextServiceKm = nextServiceKm ?? (lastServiceKm + serviceIntervalKm),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();'''
)

# Add computed properties for service status after diskStatus
service_properties = '''
  /// NEW: KM until next service
  int get kmUntilService => nextServiceKm - currentKm;

  /// NEW: Check if service is due
  bool get isServiceDue => currentKm >= nextServiceKm;

  /// NEW: Check if service is approaching (within 1000 KM)
  bool get isServiceApproaching => kmUntilService <= 1000 && kmUntilService > 0;

  /// NEW: Get service status
  ServiceStatus get serviceStatus {
    if (isServiceDue) return ServiceStatus.overdue;
    if (isServiceApproaching) return ServiceStatus.dueSoon;
    return ServiceStatus.ok;
  }
'''

# Find the end of diskStatus getter and add service properties
vehicle_content = re.sub(
    r'(  DiskStatus get diskStatus \{[^}]+\})',
    r'\1' + service_properties,
    vehicle_content,
    flags=re.DOTALL
)

# Add toMap updates for KM fields
vehicle_content = vehicle_content.replace(
    "      'diskNumber': diskNumber,\r\n      'createdAt': createdAt.toIso8601String(),",
    '''      'diskNumber': diskNumber,
      'currentKm': currentKm,
      'lastServiceKm': lastServiceKm,
      'serviceIntervalKm': serviceIntervalKm,
      'nextServiceKm': nextServiceKm,
      'createdAt': createdAt.toIso8601String(),'''
)

# Add fromMap updates for KM fields
vehicle_content = vehicle_content.replace(
    "      diskNumber: map['diskNumber'] as String?,\r\n      createdAt: DateTime.parse(map['createdAt'] as String),",
    '''      diskNumber: map['diskNumber'] as String?,
      currentKm: (map['currentKm'] as int?) ?? 0,
      lastServiceKm: (map['lastServiceKm'] as int?) ?? 0,
      serviceIntervalKm: (map['serviceIntervalKm'] as int?) ?? 10000,
      nextServiceKm: map['nextServiceKm'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),'''
)

# Add copyWith updates
vehicle_content = vehicle_content.replace(
    '    DateTime? licenseDiskExpiry,\r\n    DateTime? lastRenewalDate,\r\n    String? diskNumber,\r\n    DateTime? createdAt,',
    '''    DateTime? licenseDiskExpiry,
    DateTime? lastRenewalDate,
    String? diskNumber,
    int? currentKm,
    int? lastServiceKm,
    int? serviceIntervalKm,
    int? nextServiceKm,
    DateTime? createdAt,'''
)

vehicle_content = vehicle_content.replace(
    '      licenseDiskExpiry: licenseDiskExpiry ?? this.licenseDiskExpiry,\r\n      lastRenewalDate: lastRenewalDate ?? this.lastRenewalDate,\r\n      diskNumber: diskNumber ?? this.diskNumber,\r\n      createdAt: createdAt ?? this.createdAt,',
    '''      licenseDiskExpiry: licenseDiskExpiry ?? this.licenseDiskExpiry,
      lastRenewalDate: lastRenewalDate ?? this.lastRenewalDate,
      diskNumber: diskNumber ?? this.diskNumber,
      currentKm: currentKm ?? this.currentKm,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
      serviceIntervalKm: serviceIntervalKm ?? this.serviceIntervalKm,
      nextServiceKm: nextServiceKm ?? this.nextServiceKm,
      createdAt: createdAt ?? this.createdAt,'''
)

# Add ServiceStatus enum at the end
service_status_enum = '''

/// Service Status Enum
enum ServiceStatus {
  ok,
  dueSoon,
  overdue,
}

/// Service Status Helper Extension
extension ServiceStatusHelper on ServiceStatus {
  String get label {
    switch (this) {
      case ServiceStatus.ok:
        return 'OK';
      case ServiceStatus.dueSoon:
        return 'Due Soon';
      case ServiceStatus.overdue:
        return 'OVERDUE';
    }
  }

  Color get color {
    switch (this) {
      case ServiceStatus.ok:
        return Colors.green;
      case ServiceStatus.dueSoon:
        return Colors.orange;
      case ServiceStatus.overdue:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceStatus.ok:
        return Icons.check_circle;
      case ServiceStatus.dueSoon:
        return Icons.warning;
      case ServiceStatus.overdue:
        return Icons.error;
    }
  }
}
'''

# Add at the very end of the file
if 'enum ServiceStatus' not in vehicle_content:
    vehicle_content = vehicle_content.rstrip() + service_status_enum

with open('lib/models/vehicle_model.dart', 'w', encoding='utf-8') as f:
    f.write(vehicle_content)

print("✅ Vehicle model updated with KM tracking fields")

print("\n✅ All updates complete!")
print("   - Vehicle model: Added KM fields and service status")
print("   - Ready for database helper methods")
