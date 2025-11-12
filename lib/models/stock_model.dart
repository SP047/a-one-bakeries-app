/// Stock Model
/// 
/// Represents a stock item in the inventory system.
/// Uses integer quantities (whole numbers only).

class StockItem {
  final int? id;
  final String name;
  final String unit;
  final int quantityOnHand;      // int is fine here
  final DateTime createdAt;
  final DateTime updatedAt;

  StockItem({
    this.id,
    required this.name,
    required this.unit,
    required this.quantityOnHand,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert StockItem to Map for database
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
      quantityOnHand: (map['quantityOnHand'] is double) 
          ? (map['quantityOnHand'] as double).toInt() 
          : map['quantityOnHand'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  StockItem copyWith({
    int? id,
    String? name,
    String? unit,
    int? quantityOnHand,
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
/// Records all stock movements.
/// Uses integer quantities (whole numbers only).

class StockMovement {
  final int? id;
  final int stockItemId;
  final String stockItemName;
  final String movementType;        // "RECEIVED" or "ALLOCATED"
  final int quantity;                // CHANGED TO INT - This is the key fix!
  final String? employeeName;
  final String? supplierName;        // For receiving from suppliers
  final String? notes;
  final DateTime createdAt;

  StockMovement({
    this.id,
    required this.stockItemId,
    required this.stockItemName,
    required this.movementType,
    required this.quantity,
    this.employeeName,
    this.supplierName,
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
      'supplierName': supplierName,
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
      quantity: (map['quantity'] is double) 
          ? (map['quantity'] as double).toInt() 
          : map['quantity'] as int,
      employeeName: map['employeeName'] as String?,
      supplierName: map['supplierName'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}