/// Vehicle Model
/// 
/// Represents a vehicle in the bakery business.
/// Vehicles can be assigned to employees with "Driver" role.
library;

class Vehicle {
  final int? id;
  final String make;              // e.g., Toyota, Ford
  final String model;             // e.g., Hilux, Ranger
  final int year;                 // Manufacturing year
  final String registrationNumber; // License plate number
  final int? assignedDriverId;    // Foreign key to Employee (nullable)
  final String? assignedDriverName; // Driver name for display
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.registrationNumber,
    this.assignedDriverId,
    this.assignedDriverName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Get full vehicle name
  String get fullName => '$year $make $model';

  /// Check if vehicle is assigned
  bool get isAssigned => assignedDriverId != null;

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'registrationNumber': registrationNumber,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
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
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  Vehicle copyWith({
    int? id,
    String? make,
    String? model,
    int? year,
    String? registrationNumber,
    int? assignedDriverId,
    String? assignedDriverName,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}