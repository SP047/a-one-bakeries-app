/// Income Model
/// 
/// Represents daily income recorded.
/// Separated into notes (paper money) and coins.

class Income {
  final int? id;
  final String? description;   // Optional description
  final double notes;           // Paper money amount
  final double coins;           // Coins amount (can be 0)
  final double total;           // Total (notes + coins)
  final DateTime createdAt;

  Income({
    this.id,
    this.description,
    required this.notes,
    required this.coins,
    DateTime? createdAt,
  })  : total = notes + coins,
        createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'notes': notes,
      'coins': coins,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      description: map['description'] as String?,
      notes: map['notes'] as double,
      coins: map['coins'] as double,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Create a copy with updated fields
  Income copyWith({
    int? id,
    String? description,
    double? notes,
    double? coins,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      coins: coins ?? this.coins,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Expense Model
/// 
/// Represents daily expenses recorded.

class Expense {
  final int? id;
  final String description;     // What the expense was for
  final double amount;          // Expense amount
  final DateTime createdAt;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      description: map['description'] as String,
      amount: map['amount'] as double,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Create a copy with updated fields
  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}