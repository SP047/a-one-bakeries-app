/// Order Model
/// 
/// Represents a production/delivery order for a driver or vehicle.
/// Tracks quantities only (no pricing).

class Order {
  final int? id;
  final int? driverId;           // Foreign key to Employee (nullable)
  final String? driverName;      // Driver name for display
  final int? vehicleId;          // Foreign key to Vehicle (nullable)
  final String? vehicleInfo;     // Vehicle info for display
  final int totalQuantity;       // Total quantity of all items
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

  /// Check if order is for driver or vehicle
  bool get isDriverOrder => driverId != null;
  bool get isVehicleOrder => vehicleId != null;

  /// Get display name (driver or vehicle)
  String get displayName {
    if (driverName != null) return driverName!;
    if (vehicleInfo != null) return vehicleInfo!;
    return 'Unknown';
  }

  /// Convert to Map for database
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

  /// Create from database Map
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

  /// Create a copy with updated fields
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

/// Order Item Model
/// 
/// Represents individual line items in an order.
/// Tracks quantities only (no pricing).

class OrderItem {
  final int? id;
  final int orderId;             // Foreign key to Order
  final String itemType;         // "Brown Bread", "White Bread", "Bucket Biscuits"
  final int trolliesOrQty;       // Trollies for bread, direct quantity for biscuits
  final int quantity;            // Calculated quantity

  OrderItem({
    this.id,
    required this.orderId,
    required this.itemType,
    required this.trolliesOrQty,
    required this.quantity,
  });

  /// Calculate quantity based on item type
  /// Brown/White Bread: trollies × 180
  /// Bucket Biscuits: direct quantity (1-20)
  static int calculateQuantity(String itemType, int trolliesOrQty) {
    if (itemType == 'Bucket Biscuits') {
      return trolliesOrQty; // Direct quantity
    } else {
      // Brown Bread or White Bread
      return trolliesOrQty * 180;
    }
  }

  /// Create a copy with updated fields
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

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'itemType': itemType,
      'trolliesOrQty': trolliesOrQty,
      'quantity': quantity,
    };
  }

  /// Create from database Map
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

/// Order Item Types Constants
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