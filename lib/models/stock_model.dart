/// Stock Model
/// 
/// Represents a stock item in the inventory system.
/// This model handles the database structure for stock items.

class StockItem {
  final int? id;                    // Auto-generated ID (null for new items)
  final String name;                // Stock item name (e.g., "Flour", "Sugar")
  final String unit;                // Unit of measurement (e.g., "kg", "L", "bags")
  final double quantityOnHand;      // Current quantity in stock
  final DateTime createdAt;         // When item was created
  final DateTime updatedAt;         // Last update timestamp

  StockItem({
    this.id,
    required this.name,
    required this.unit,
    required this.quantityOnHand,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert StockItem to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'quantityOnHand': quantityOnHand,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create StockItem from database Map
  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String,
      quantityOnHand: map['quantityOnHand'] as double,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Create a copy of StockItem with updated fields
  StockItem copyWith({
    int? id,
    String? name,
    String? unit,
    double? quantityOnHand,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Stock Movement Model
/// 
/// Records all stock movements (received from supplier or allocated to employees).
/// This creates an audit trail of all stock changes.

class StockMovement {
  final int? id;                    // Auto-generated ID
  final int stockItemId;            // Foreign key to StockItem
  final String stockItemName;       // Stock item name (for display)
  final String movementType;        // "RECEIVED" or "ALLOCATED"
  final double quantity;            // Quantity moved
  final String? employeeName;       // Employee name (for allocations)
  final String? notes;              // Additional notes/reason
  final DateTime createdAt;         // When movement occurred

  StockMovement({
    this.id,
    required this.stockItemId,
    required this.stockItemName,
    required this.movementType,
    required this.quantity,
    this.employeeName,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stockItemId': stockItemId,
      'stockItemName': stockItemName,
      'movementType': movementType,
      'quantity': quantity,
      'employeeName': employeeName,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      stockItemId: map['stockItemId'] as int,
      stockItemName: map['stockItemName'] as String,
      movementType: map['movementType'] as String,
      quantity: map['quantity'] as double,
      employeeName: map['employeeName'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}