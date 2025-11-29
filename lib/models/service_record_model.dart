/// ---------------------------------------------------------------------------
/// Service Record Model
/// ---------------------------------------------------------------------------
/// Represents a service performed on a vehicle.
/// Tracks service history including type, cost, and notes.
/// ---------------------------------------------------------------------------

class ServiceRecord {
  final int? id;
  final int vehicleId;
  final int serviceKm;
  final DateTime serviceDate;
  final String serviceType; // 'Regular', 'Major', 'Repair', 'Other'
  final double? cost;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRecord({
    this.id,
    required this.vehicleId,
    required this.serviceKm,
    required this.serviceDate,
    required this.serviceType,
    this.cost,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'serviceKm': serviceKm,
      'serviceDate': serviceDate.toIso8601String(),
      'serviceType': serviceType,
      'cost': cost,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      serviceKm: map['serviceKm'] as int,
      serviceDate: DateTime.parse(map['serviceDate'] as String),
      serviceType: map['serviceType'] as String,
      cost: map['cost'] as double?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  ServiceRecord copyWith({
    int? id,
    int? vehicleId,
    int? serviceKm,
    DateTime? serviceDate,
    String? serviceType,
    double? cost,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceKm: serviceKm ?? this.serviceKm,
      serviceDate: serviceDate ?? this.serviceDate,
      serviceType: serviceType ?? this.serviceType,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Service type constants
class ServiceTypes {
  static const String regular = 'Regular';
  static const String major = 'Major';
  static const String repair = 'Repair';
  static const String other = 'Other';
  
  static List<String> get all => [regular, major, repair, other];
}
