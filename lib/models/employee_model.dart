// ===============================================================
// EMPLOYEE MANAGEMENT MODELS
// ---------------------------------------------------------------
// This file contains the following models used for employee
// management in the bakery business:
// 
// 1. Employee                - Core employee data
// 2. CreditTransaction       - Employee borrow/repayment tracking
// 3. EmployeeDocument        - Uploaded employee documents
// 4. EmployeeRoles           - String constants for employee roles
// 5. DriverLicense           - Separate model for driver licenses
// 
// NOTE:
// - Driver license info is stored in a SEPARATE table.
// - No logic has been changed—only restructuring + comments.
// ===============================================================



// ===============================================================
// 1. EMPLOYEE MODEL
// ---------------------------------------------------------------
// Represents a bakery employee, storing identification,
// personal info, roles, and photo data.
// ===============================================================

class Employee {
  // -------------------------
  // FIELDS
  // -------------------------
  final int? id;
  final String firstName;
  final String lastName;
  final String idNumber;    // SA ID or Passport Number
  final String idType;      // "ID" or "PASSPORT"
  final DateTime birthDate;
  final String role;        // Baker, Driver, General Worker, etc.
  final String? photoPath;  // Local file path to employee photo

  final DateTime createdAt;
  final DateTime updatedAt;

  // -------------------------
  // CONSTRUCTOR
  // -------------------------
  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.idNumber,
    required this.idType,
    required this.birthDate,
    required this.role,
    this.photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // -------------------------
  // COMPUTED FIELDS
  // -------------------------

  /// Full name of employee (First + Last)
  String get fullName => '$firstName $lastName';

  /// Computes age based on birth year
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Returns true if employee has a stored photo
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  // -------------------------
  // SERIALIZATION
  // -------------------------

  /// Convert Employee object → Map (for DB storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'idNumber': idNumber,
      'idType': idType,
      'birthDate': birthDate.toIso8601String(),
      'role': role,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create Employee object ← Map (from DB)
  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      idNumber: map['idNumber'] as String,
      idType: map['idType'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
      role: map['role'] as String,
      photoPath: map['photoPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // -------------------------
  // COPY WITH
  // -------------------------

  /// Creates a new Employee with updated fields
  Employee copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? idNumber,
    String? idType,
    DateTime? birthDate,
    String? role,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      idNumber: idNumber ?? this.idNumber,
      idType: idType ?? this.idType,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



// ===============================================================
// 2. CREDIT TRANSACTION MODEL
// ---------------------------------------------------------------
// Tracks employee loans (BORROW), repayments (REPAY), and reasons.
// ===============================================================

class CreditTransaction {
  // -------------------------
  // FIELDS
  // -------------------------
  final int? id;
  final int employeeId;
  final String employeeName;
  final String transactionType;   // "BORROW" or "REPAY"
  final double amount;
  final String reason;
  final DateTime createdAt;

  // -------------------------
  // CONSTRUCTOR
  // -------------------------
  CreditTransaction({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.transactionType,
    required this.amount,
    required this.reason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // -------------------------
  // SERIALIZATION
  // -------------------------

  /// Convert object → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'transactionType': transactionType,
      'amount': amount,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create object ← Map
  factory CreditTransaction.fromMap(Map<String, dynamic> map) {
    return CreditTransaction(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      employeeName: map['employeeName'] as String,
      transactionType: map['transactionType'] as String,
      amount: map['amount'] as double,
      reason: map['reason'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}



// ===============================================================
// 3. EMPLOYEE DOCUMENT MODEL
// ---------------------------------------------------------------
// Stores uploaded employee files such as contracts, payslips,
// and disciplinary documents.
// ===============================================================

class EmployeeDocument {
  // -------------------------
  // FIELDS
  // -------------------------
  final int? id;
  final int employeeId;
  final String documentType;   // CONTRACT, PAYSLIP, DISCIPLINARY
  final String fileName;
  final String filePath;
  final DateTime uploadedAt;

  // -------------------------
  // CONSTRUCTOR
  // -------------------------
  EmployeeDocument({
    this.id,
    required this.employeeId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  // -------------------------
  // SERIALIZATION
  // -------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'documentType': documentType,
      'fileName': fileName,
      'filePath': filePath,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory EmployeeDocument.fromMap(Map<String, dynamic> map) {
    return EmployeeDocument(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      documentType: map['documentType'] as String,
      fileName: map['fileName'] as String,
      filePath: map['filePath'] as String,
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
    );
  }
}



// ===============================================================
// 4. EMPLOYEE ROLE CONSTANTS
// ---------------------------------------------------------------
// Central location for defining all employee role labels.
// ===============================================================

class EmployeeRoles {
  static const String baker = 'Baker';
  static const String driver = 'Driver';
  static const String generalWorker = 'General Worker';
  static const String supervisor = 'Supervisor';
  static const String manager = 'Manager';

  /// List of all selectable roles
  static const List<String> allRoles = [
    baker,
    driver,
    generalWorker,
    supervisor,
    manager,
  ];
}



// ===============================================================
// 5. DRIVER LICENSE MODEL
// ---------------------------------------------------------------
// Stores driver licensing information. Stored separately from
// employees in its own table (driver_licenses).
// ===============================================================

class DriverLicense {
  // -------------------------
  // FIELDS
  // -------------------------
  final int? id;
  final int employeeId;
  final String licenseNumber;
  final String licenseType;     // Code 8 / Code 10 / Code 14
  final String? licenseTypes;   // Additional types (A, B, C)
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? restrictions;   // e.g. Glasses required
  final DateTime createdAt;
  final DateTime updatedAt;

  // -------------------------
  // CONSTRUCTOR
  // -------------------------
  DriverLicense({
    this.id,
    required this.employeeId,
    required this.licenseNumber,
    required this.licenseType,
    this.licenseTypes,
    required this.issueDate,
    required this.expiryDate,
    this.restrictions,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // -------------------------
  // COMPUTED PROPERTIES
  // -------------------------

  /// Checks if the license is already expired
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  /// True if the license expires within the next 90 days
  bool get isExpiringSoon {
    final daysUntil = expiryDate.difference(DateTime.now()).inDays;
    return daysUntil > 0 && daysUntil <= 90;
  }

  /// Number of days until expiration (can be negative)
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  // -------------------------
  // SERIALIZATION
  // -------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'licenseNumber': licenseNumber,
      'licenseType': licenseType,
      'licenseTypes': licenseTypes,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'restrictions': restrictions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DriverLicense.fromMap(Map<String, dynamic> map) {
    return DriverLicense(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      licenseNumber: map['licenseNumber'] as String,
      licenseType: map['licenseType'] as String,
      licenseTypes: map['licenseTypes'] as String?,
      issueDate: DateTime.parse(map['issueDate'] as String),
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      restrictions: map['restrictions'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // -------------------------
  // COPY WITH
  // -------------------------

  DriverLicense copyWith({
    int? id,
    int? employeeId,
    String? licenseNumber,
    String? licenseType,
    String? licenseTypes,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? restrictions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverLicense(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseType: licenseType ?? this.licenseType,
      licenseTypes: licenseTypes ?? this.licenseTypes,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      restrictions: restrictions ?? this.restrictions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
