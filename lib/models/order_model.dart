/// ============================================================================
/// ORDER MODELS
///
/// Contains data models for production/delivery orders:
///   • Order      – Represents a delivery order assigned to a driver or vehicle.
///   • OrderItem  – Represents individual line items (bread/biscuits quantities).
///
/// These models track QUANTITY ONLY — no pricing logic is included.
/// ============================================================================

library;

/// ============================================================================
/// ORDER MODEL
/// ----------------------------------------------------------------------------
/// Represents a full delivery/production order.
/// An order can belong to either:
///   • A driver   (driverId + driverName)
///   • A vehicle  (vehicleId + vehicleInfo)
///
/// Fields:
///   • totalQuantity – Combined quantity of all order items.
///   • createdAt     – Timestamp for logging and sorting.
/// ============================================================================
class Order {
  final int? id;

  // Driver-related fields (nullable)
  final int? driverId;            // FK → Employee table
  final String? driverName;       // Display name for driver

  // Vehicle-related fields (nullable)
  final int? vehicleId;           // FK → Vehicle table
  final String? vehicleInfo;      // Display info for vehicle

  final int totalQuantity;        // Total quantity of all OrderItem entries
  final DateTime createdAt;

  Order({
    this.id,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleInfo,
    required this.totalQuantity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // FLAGS
  // ---------------------------------------------------------------------------

  /// True if assigned to a driver.
  bool get isDriverOrder => driverId != null;

  /// True if assigned to a vehicle.
  bool get isVehicleOrder => vehicleId != null;

  /// Display name for UI (driver first, fallback to vehicle).
  String get displayName {
    if (driverName != null) return driverName!;
    if (vehicleInfo != null) return vehicleInfo!;
    return 'Unknown';
  }

  // ---------------------------------------------------------------------------
  // SERIALIZATION
  // ---------------------------------------------------------------------------

  /// Convert this Order into a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehicleInfo': vehicleInfo,
      'totalQuantity': totalQuantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create an Order from a database Map.
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      driverId: map['driverId'] as int?,
      driverName: map['driverName'] as String?,
      vehicleId: map['vehicleId'] as int?,
      vehicleInfo: map['vehicleInfo'] as String?,
      totalQuantity: map['totalQuantity'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // ---------------------------------------------------------------------------
  // COPY
  // ---------------------------------------------------------------------------

  /// Create a new Order with updated fields.
  Order copyWith({
    int? id,
    int? driverId,
    String? driverName,
    int? vehicleId,
    String? vehicleInfo,
    int? totalQuantity,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// ============================================================================
/// ORDER ITEM MODEL
/// ----------------------------------------------------------------------------
/// Represents an individual line item inside an Order.
///
/// Supported item types:
///   • "Brown Bread"
///   • "White Bread"
///   • "Bucket Biscuits"
///
/// QUANTITY RULES:
///   • Bread (Brown/White) → quantity = trollies × 180
///   • Bucket Biscuits     → quantity = trolliesOrQty (1–20 direct)
/// ============================================================================
class OrderItem {
  final int? id;
  final int orderId;              // FK → Order
  final String itemType;          // e.g. Brown Bread / White Bread / Bucket Biscuits
  final int trolliesOrQty;        // Trollies for bread, direct quantity for biscuits
  final int quantity;             // Calculated quantity

  OrderItem({
    this.id,
    required this.orderId,
    required this.itemType,
    required this.trolliesOrQty,
    required this.quantity,
  });

  // ---------------------------------------------------------------------------
  // QUANTITY CALCULATION
  // ---------------------------------------------------------------------------

  /// Calculate quantity based on product type and value.
  ///
  /// Bread = trollies × 180  
  /// Biscuits = direct quantity
  static int calculateQuantity(String itemType, int trolliesOrQty) {
    if (itemType == 'Bucket Biscuits') {
      return trolliesOrQty;
    }
    // Default logic for Brown & White Bread
    return trolliesOrQty * 180;
  }

  // ---------------------------------------------------------------------------
  // COPY
  // ---------------------------------------------------------------------------

  /// Create a modified copy of the OrderItem.
  OrderItem copyWith({
    int? id,
    int? orderId,
    String? itemType,
    int? trolliesOrQty,
    int? quantity,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemType: itemType ?? this.itemType,
      trolliesOrQty: trolliesOrQty ?? this.trolliesOrQty,
      quantity: quantity ?? this.quantity,
    );
  }

  // ---------------------------------------------------------------------------
  // SERIALIZATION
  // ---------------------------------------------------------------------------

  /// Convert this OrderItem into a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'itemType': itemType,
      'trolliesOrQty': trolliesOrQty,
      'quantity': quantity,
    };
  }

  /// Create an OrderItem from a database Map.
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['orderId'] as int,
      itemType: map['itemType'] as String,
      trolliesOrQty: map['trolliesOrQty'] as int,
      quantity: map['quantity'] as int,
    );
  }
}

/// ============================================================================
/// ORDER ITEM TYPES (CONSTANTS)
/// ----------------------------------------------------------------------------
/// Centralized string constants used across the app.
/// ============================================================================
class OrderItemTypes {
  static const String brownBread = 'Brown Bread';
  static const String whiteBread = 'White Bread';
  static const String bucketBiscuits = 'Bucket Biscuits';

  static const List<String> allTypes = [
    brownBread,
    whiteBread,
    bucketBiscuits,
  ];
}
