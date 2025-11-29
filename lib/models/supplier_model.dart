/// ------------------------------------------------------------
/// SUPPLIER MODELS
/// ------------------------------------------------------------
/// Contains all supplier-related models:
///   • Supplier
///   • SupplierInvoice
///   • SupplierPayment
///   • PaymentMethods (constants)
/// ------------------------------------------------------------
library;

/// ===============================
/// SUPPLIER MODEL
/// ===============================
/// Represents a supplier and their contact information.
/// Tracks creation/update timestamps for record changes.
/// -------------------------------

class Supplier {
  final int? id;
  final String name;
  final String contactPerson;
  final String phoneNumber;
  final String? email;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    this.id,
    required this.name,
    required this.contactPerson,
    required this.phoneNumber,
    this.email,
    this.address,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert Supplier to a Map for storing in database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create Supplier from database Map.
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      contactPerson: map['contactPerson'] as String,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Return a new instance with updated fields.
  Supplier copyWith({
    int? id,
    String? name,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// ===============================
/// SUPPLIER INVOICE MODEL
/// ===============================
/// Represents a supplier invoice:
///   • Includes invoice number
///   • Amount due
///   • Optional due date
///   • Optional notes
/// -------------------------------

class SupplierInvoice {
  final int? id;
  final int supplierId;
  final String supplierName;
  final String invoiceNumber;
  final double amount;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;

  SupplierInvoice({
    this.id,
    required this.supplierId,
    required this.supplierName,
    required this.invoiceNumber,
    required this.amount,
    required this.invoiceDate,
    this.dueDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert invoice to Map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create invoice from persisted Map.
  factory SupplierInvoice.fromMap(Map<String, dynamic> map) {
    return SupplierInvoice(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int,
      supplierName: map['supplierName'] as String,
      invoiceNumber: map['invoiceNumber'] as String,
      amount: map['amount'] as double,
      invoiceDate: DateTime.parse(map['invoiceDate'] as String),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

/// ===============================
/// SUPPLIER PAYMENT MODEL
/// ===============================
/// Represents payments made to suppliers.
/// Supports multiple payment types:
///   • CASH
///   • EFT
///   • CHEQUE
///
/// Also stores notes & references.
/// -------------------------------

class SupplierPayment {
  final int? id;
  final int supplierId;
  final String supplierName;
  final double amount;
  final String paymentMethod;     // "CASH", "EFT", "CHEQUE"
  final String? reference;        // Optional reference number
  final String? notes;            // Optional notes
  final DateTime paymentDate;
  final DateTime createdAt;

  SupplierPayment({
    this.id,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    required this.paymentDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert payment to Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'reference': reference,
      'notes': notes,
      'paymentDate': paymentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create payment from Map.
  factory SupplierPayment.fromMap(Map<String, dynamic> map) {
    return SupplierPayment(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int,
      supplierName: map['supplierName'] as String,
      amount: map['amount'] as double,
      paymentMethod: map['paymentMethod'] as String,
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

/// ===============================
/// PAYMENT METHOD CONSTANTS
/// ===============================

class PaymentMethods {
  static const String cash = 'CASH';
  static const String eft = 'EFT';
  static const String cheque = 'CHEQUE';

  static const List<String> allMethods = [
    cash,
    eft,
    cheque,
  ];

  static Null card() => null; // Placeholder if card is added later
}
/// ============================================================================