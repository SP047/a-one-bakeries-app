/// ---------------------------------------------------------------------------
/// Vehicle Model
/// ---------------------------------------------------------------------------
/// Represents a vehicle used in the bakery business.  
/// Vehicles may be assigned to employees who have the "Driver" role.
/// Includes license disk tracking and KM/service tracking.
/// ---------------------------------------------------------------------------

library;

import 'package:flutter/material.dart';

class Vehicle {
  /// Database primary key (nullable for new entries before insertion).
  final int? id;

  /// Manufacturer of the vehicle (e.g., Toyota, Ford).
  final String make;

  /// Specific model of the vehicle (e.g., Hilux, Ranger).
  final String model;

  /// Manufacturing year of the vehicle.
  final int year;

  /// License plate / registration number.
  final String registrationNumber;

  /// Employee ID of the assigned driver (nullable if unassigned).
  final int? assignedDriverId;

  /// Display name of the assigned driver (optional convenience field).
  final String? assignedDriverName;

  // License Disk Fields
  final DateTime? licenseDiskExpiry;  // When does the disk expire?
  final DateTime? lastRenewalDate;    // When was it last renewed?
  final String? diskNumber;           // Optional disk reference number

  // KM Tracking Fields
  final int currentKm;              // Current odometer reading
  final int lastServiceKm;          // KM at last service
  final int serviceIntervalKm;      // KM between services (default: 10000)
  final int nextServiceKm;          // Calculated: lastServiceKm + serviceIntervalKm

  /// Timestamp when the vehicle record was created.
  final DateTime createdAt;

  /// Timestamp when the vehicle record was last updated.
  final DateTime updatedAt;

  /// -------------------------------------------------------------------------
  /// Constructor
  /// - Automatically assigns current timestamps if not provided.
  /// -------------------------------------------------------------------------
  Vehicle({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.registrationNumber,
    this.assignedDriverId,
    this.assignedDriverName,
    this.licenseDiskExpiry,
    this.lastRenewalDate,
    this.diskNumber,
    this.currentKm = 0,
    this.lastServiceKm = 0,
    this.serviceIntervalKm = 10000,
    int? nextServiceKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : nextServiceKm = nextServiceKm ?? (lastServiceKm + serviceIntervalKm),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// -------------------------------------------------------------------------
  /// Computed Properties
  /// -------------------------------------------------------------------------

  /// Returns a readable full name of the vehicle.
  String get fullName => '$year $make $model';

  /// Indicates whether the vehicle is currently assigned to a driver.
  bool get isAssigned => assignedDriverId != null;

  /// Check if disk is expired
  bool get isDiskExpired {
    if (licenseDiskExpiry == null) return false;
    return licenseDiskExpiry!.isBefore(DateTime.now());
  }

  /// Check if disk is expiring soon (within 90 days)
  bool get isDiskExpiringSoon {
    if (licenseDiskExpiry == null) return false;
    final daysUntilExpiry = licenseDiskExpiry!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 90 && daysUntilExpiry > 0;
  }

  /// Get days until disk expiry
  int get daysUntilDiskExpiry {
    if (licenseDiskExpiry == null) return 999;
    return licenseDiskExpiry!.difference(DateTime.now()).inDays;
  }

  /// Get disk status
  DiskStatus get diskStatus {
    if (licenseDiskExpiry == null) return DiskStatus.noData;
    
    final days = daysUntilDiskExpiry;
    
    if (days < 0) return DiskStatus.expired;
    if (days <= 30) return DiskStatus.critical;
    if (days <= 90) return DiskStatus.warning;
    return DiskStatus.valid;
  }

  /// KM until next service
  int get kmUntilService => nextServiceKm - currentKm;

  /// Check if service is due
  bool get isServiceDue => currentKm >= nextServiceKm;

  /// Check if service is approaching (within 1000 KM)
  bool get isServiceApproaching => kmUntilService <= 1000 && kmUntilService > 0;

  /// Get service status
  ServiceStatus get serviceStatus {
    if (isServiceDue) return ServiceStatus.overdue;
    if (isServiceApproaching) return ServiceStatus.dueSoon;
    return ServiceStatus.ok;
  }

  /// -------------------------------------------------------------------------
  /// Serialization
  /// -------------------------------------------------------------------------

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'registrationNumber': registrationNumber,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'licenseDiskExpiry': licenseDiskExpiry?.toIso8601String(),
      'lastRenewalDate': lastRenewalDate?.toIso8601String(),
      'diskNumber': diskNumber,
      'currentKm': currentKm,
      'lastServiceKm': lastServiceKm,
      'serviceIntervalKm': serviceIntervalKm,
      'nextServiceKm': nextServiceKm,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      registrationNumber: map['registrationNumber'] as String,
      assignedDriverId: map['assignedDriverId'] as int?,
      assignedDriverName: map['assignedDriverName'] as String?,
      licenseDiskExpiry: map['licenseDiskExpiry'] != null 
          ? DateTime.parse(map['licenseDiskExpiry'] as String)
          : null,
      lastRenewalDate: map['lastRenewalDate'] != null
          ? DateTime.parse(map['lastRenewalDate'] as String)
          : null,
      diskNumber: map['diskNumber'] as String?,
      currentKm: (map['currentKm'] as int?) ?? 0,
      lastServiceKm: (map['lastServiceKm'] as int?) ?? 0,
      serviceIntervalKm: (map['serviceIntervalKm'] as int?) ?? 10000,
      nextServiceKm: map['nextServiceKm'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// -------------------------------------------------------------------------
  /// Copy
  /// -------------------------------------------------------------------------

  /// Create a new Vehicle with updated fields
  Vehicle copyWith({
    int? id,
    String? make,
    String? model,
    int? year,
    String? registrationNumber,
    int? assignedDriverId,
    String? assignedDriverName,
    DateTime? licenseDiskExpiry,
    DateTime? lastRenewalDate,
    String? diskNumber,
    int? currentKm,
    int? lastServiceKm,
    int? serviceIntervalKm,
    int? nextServiceKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      licenseDiskExpiry: licenseDiskExpiry ?? this.licenseDiskExpiry,
      lastRenewalDate: lastRenewalDate ?? this.lastRenewalDate,
      diskNumber: diskNumber ?? this.diskNumber,
      currentKm: currentKm ?? this.currentKm,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
      serviceIntervalKm: serviceIntervalKm ?? this.serviceIntervalKm,
      nextServiceKm: nextServiceKm ?? this.nextServiceKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Disk Status Enum
/// ---------------------------------------------------------------------------

enum DiskStatus {
  noData,    // No expiry date set
  valid,     // More than 90 days
  warning,   // 31-90 days
  critical,  // 1-30 days
  expired,   // Past expiry date
}

/// Disk Status Helper Extension
extension DiskStatusHelper on DiskStatus {
  String get label {
    switch (this) {
      case DiskStatus.noData:
        return 'No Data';
      case DiskStatus.valid:
        return 'Valid';
      case DiskStatus.warning:
        return 'Expiring Soon';
      case DiskStatus.critical:
        return 'Critical';
      case DiskStatus.expired:
        return 'EXPIRED';
    }
  }

  Color get color {
    switch (this) {
      case DiskStatus.noData:
        return Colors.grey;
      case DiskStatus.valid:
        return Colors.green;
      case DiskStatus.warning:
        return Colors.orange;
      case DiskStatus.critical:
        return Colors.deepOrange;
      case DiskStatus.expired:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case DiskStatus.noData:
        return Icons.help_outline;
      case DiskStatus.valid:
        return Icons.check_circle;
      case DiskStatus.warning:
        return Icons.warning;
      case DiskStatus.critical:
        return Icons.error;
      case DiskStatus.expired:
        return Icons.cancel;
    }
  }
}

/// ---------------------------------------------------------------------------
/// Service Status Enum
/// ---------------------------------------------------------------------------

enum ServiceStatus {
  ok,        // More than 1000 KM until service
  dueSoon,   // Within 1000 KM of service
  overdue,   // Past service KM
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