/// ============================================================================
/// FINANCE MODELS
/// 
/// Contains data models used to track daily income and expenses in the bakery.
/// Includes:
///   • Income  – Records daily money received (notes + coins)
///   • Expense – Records daily money spent
/// 
/// NOTE:
///   - All models include timestamps for logging and sorting.
///   - Logic and field names intentionally preserved as-is (no changes).
/// ============================================================================

library;

/// ============================================================================
/// INCOME MODEL
/// ----------------------------------------------------------------------------
/// Represents daily income received.
///
/// Fields:
///   • description – Optional note describing the income source.
///   • notes       – Amount received in paper money.
///   • coins       – Amount received in coins.
///   • total       – Automatically calculated sum of notes + coins.
///   • createdAt   – Auto-generated timestamp of when the record was created.
/// ============================================================================
class Income {
  final int? id;
  final String? description;     // Optional description of the income
  final double notes;            // Paper money amount
  final double coins;            // Coin amount (auto-calculated from denominations)
  final double total;            // Total income (notes + coins)
  
  // Coin denomination amounts
  final double amountR5;         // Amount in R5 coins
  final double amountR2;         // Amount in R2 coins
  final double amountR1;         // Amount in R1 coins
  final double amount50c;        // Amount in 50c coins
  
  final DateTime createdAt;

  Income({
    this.id,
    this.description,
    required this.notes,
    this.amountR5 = 0,
    this.amountR2 = 0,
    this.amountR1 = 0,
    this.amount50c = 0,
    DateTime? createdAt,
  })  : coins = amountR5 + amountR2 + amountR1 + amount50c,  // Auto-calculate coins
        total = notes + (amountR5 + amountR2 + amountR1 + amount50c),  // Auto-calculate total
        createdAt = createdAt ?? DateTime.now();         // Default timestamp

  /// Convert this object into a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'notes': notes,
      'coins': coins,
      'total': total,
      'amountR5': amountR5,
      'amountR2': amountR2,
      'amountR1': amountR1,
      'amount50c': amount50c,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create an Income object from a database Map.
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      description: map['description'] as String?,
      notes: map['notes'] as double,
      amountR5: (map['amountR5'] as num?)?.toDouble() ?? 0,
      amountR2: (map['amountR2'] as num?)?.toDouble() ?? 0,
      amountR1: (map['amountR1'] as num?)?.toDouble() ?? 0,
      amount50c: (map['amount50c'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Create a copy of this object with updated fields.
  Income copyWith({
    int? id,
    String? description,
    double? notes,
    double? amountR5,
    double? amountR2,
    double? amountR1,
    double? amount50c,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      amountR5: amountR5 ?? this.amountR5,
      amountR2: amountR2 ?? this.amountR2,
      amountR1: amountR1 ?? this.amountR1,
      amount50c: amount50c ?? this.amount50c,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// ============================================================================
/// EXPENSE MODEL
/// ----------------------------------------------------------------------------
/// Represents daily expenses such as ingredient purchases or operational costs.
///
/// Fields:
///   • description – Description of what the expense was for.
///   • amount      – The cost of the expense.
///   • createdAt   – Timestamp for logging.
/// ============================================================================
class Expense {
  final int? id;
  final String description;      // What the expense was for
  final double notes;            // Paper money amount
  final double coins;            // Coin amount (auto-calculated from denominations)
  final double amount;           // Total expense (notes + coins) - kept for compatibility
  
  // Coin denomination amounts
  final double amountR5;         // Amount in R5 coins
  final double amountR2;         // Amount in R2 coins
  final double amountR1;         // Amount in R1 coins
  final double amount50c;        // Amount in 50c coins
  
  final DateTime createdAt;

  Expense({
    this.id,
    required this.description,
    required this.notes,
    this.amountR5 = 0,
    this.amountR2 = 0,
    this.amountR1 = 0,
    this.amount50c = 0,
    DateTime? createdAt,
  })  : coins = amountR5 + amountR2 + amountR1 + amount50c,  // Auto-calculate coins
        amount = notes + (amountR5 + amountR2 + amountR1 + amount50c),  // Auto-calculate total
        createdAt = createdAt ?? DateTime.now();

  /// Convert this object into a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'notes': notes,
      'coins': coins,
      'amount': amount,
      'amountR5': amountR5,
      'amountR2': amountR2,
      'amountR1': amountR1,
      'amount50c': amount50c,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create an Expense object from a database Map.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      description: map['description'] as String,
      notes: (map['notes'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0,  // Fallback to amount for old data
      amountR5: (map['amountR5'] as num?)?.toDouble() ?? 0,
      amountR2: (map['amountR2'] as num?)?.toDouble() ?? 0,
      amountR1: (map['amountR1'] as num?)?.toDouble() ?? 0,
      amount50c: (map['amount50c'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Create a copy of this object with updated fields.
  Expense copyWith({
    int? id,
    String? description,
    double? notes,
    double? amountR5,
    double? amountR2,
    double? amountR1,
    double? amount50c,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      amountR5: amountR5 ?? this.amountR5,
      amountR2: amountR2 ?? this.amountR2,
      amountR1: amountR1 ?? this.amountR1,
      amount50c: amount50c ?? this.amount50c,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
