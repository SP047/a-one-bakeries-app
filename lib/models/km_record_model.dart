/// ---------------------------------------------------------------------------
/// KM Record Model
/// ---------------------------------------------------------------------------
/// Represents a kilometer reading record for a vehicle.
/// Used to track odometer readings over time.
/// ---------------------------------------------------------------------------

class KmRecord {
  final int? id;
  final int vehicleId;
  final int kmReading;
  final DateTime recordedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  KmRecord({
    this.id,
    required this.vehicleId,
    required this.kmReading,
    required this.recordedDate,
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
      'kmReading': kmReading,
      'recordedDate': recordedDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory KmRecord.fromMap(Map<String, dynamic> map) {
    return KmRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      kmReading: map['kmReading'] as int,
      recordedDate: DateTime.parse(map['recordedDate'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  KmRecord copyWith({
    int? id,
    int? vehicleId,
    int? kmReading,
    DateTime? recordedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KmRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      kmReading: kmReading ?? this.kmReading,
      recordedDate: recordedDate ?? this.recordedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
