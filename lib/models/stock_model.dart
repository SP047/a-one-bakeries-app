/// ------------------------------------------------------------
/// STOCK MODELS
/// ------------------------------------------------------------
/// Contains all data models related to stock items and stock
/// movements within the inventory system.
/// ------------------------------------------------------------

/// ===============================
/// STOCK ITEM MODEL
/// ===============================
/// Represents a single stock item in the inventory.
/// Stores quantities as integers (whole numbers only),
/// with timestamps for creation and last update.
/// -------------------------------

class StockItem {
  final int? id;
  final String name;               // Item name (e.g., Flour, Yeast)
  final String unit;               // Unit type (e.g., kg, bags, litres)
  final int quantityOnHand;        // Current available quantity
  final DateTime createdAt;        // When item was created
  final DateTime updatedAt;        // Last modification timestamp

  StockItem({
    this.id,
    required this.name,
    required this.unit,
    required this.quantityOnHand,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert StockItem to a Map for database storage.
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

  /// Create a StockItem from a database Map.
  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String,

      // Some DBs return numbers as double → convert safely
      quantityOnHand: (map['quantityOnHand'] is double)
          ? (map['quantityOnHand'] as double).toInt()
          : map['quantityOnHand'] as int,

      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Create a copy with selectively updated fields.
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

/// ===============================
/// STOCK MOVEMENT MODEL
/// ===============================
/// Records all stock changes (incoming or outgoing).
/// Examples:
///   • RECEIVED  → stock increase
///   • ALLOCATED → stock decrease (used/assigned)
///
/// All quantities are integers.
/// -------------------------------

class StockMovement {
  final int? id;
  final int stockItemId;           // Foreign key → StockItem
  final String stockItemName;      // Store name for quick display
  final String movementType;       // "RECEIVED" / "ALLOCATED"
  final int quantity;              // Movement amount (int only)
  final String? employeeName;      // Who allocated (optional)
  final String? supplierName;      // Supplier for received stock
  final String? notes;             // Additional details
  final DateTime createdAt;        // Timestamp

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

  /// Convert StockMovement to a Map for database storage.
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

  /// Create StockMovement from a database Map.
  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      stockItemId: map['stockItemId'] as int,
      stockItemName: map['stockItemName'] as String,
      movementType: map['movementType'] as String,

      // Convert potential double → int
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
/// ============================================================================