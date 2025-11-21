/// Employee Model
/// 
/// Represents an employee in the bakery business.
/// Stores personal info, role, and employment details.
/// 
/// NOTE: License info is stored SEPARATELY in the DriverLicense class!

class Employee {
  final int? id;
  final String firstName;
  final String lastName;
  final String idNumber;           // SA ID or Passport number
  final String idType;             // "ID" or "PASSPORT"
  final DateTime birthDate;
  final String role;               // Baker, Driver, General Worker, Supervisor, Manager
  final String? photoPath;         // Path to employee photo (local file path)
  final DateTime createdAt;
  final DateTime updatedAt;

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

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Calculate age
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Check if employee has photo
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  /// Convert to Map for database
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

  /// Create from database Map
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

  /// Create a copy with updated fields
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

/// Credit Transaction Model
/// 
/// Tracks money borrowed by employees and repayments.

class CreditTransaction {
  final int? id;
  final int employeeId;
  final String employeeName;
  final String transactionType;    // "BORROW" or "REPAY"
  final double amount;
  final String reason;
  final DateTime createdAt;

  CreditTransaction({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.transactionType,
    required this.amount,
    required this.reason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database
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

  /// Create from database Map
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

/// Employee Document Model
/// 
/// Tracks documents uploaded for employees (contracts, payslips, disciplinary records).

class EmployeeDocument {
  final int? id;
  final int employeeId;
  final String documentType;       // "CONTRACT", "PAYSLIP", "DISCIPLINARY"
  final String fileName;
  final String filePath;
  final DateTime uploadedAt;

  EmployeeDocument({
    this.id,
    required this.employeeId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  /// Convert to Map for database
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

  /// Create from database Map
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

/// Employee Roles Constants
class EmployeeRoles {
  static const String baker = 'Baker';
  static const String driver = 'Driver';
  static const String generalWorker = 'General Worker';
  static const String supervisor = 'Supervisor';
  static const String manager = 'Manager';

  static const List<String> allRoles = [
    baker,
    driver,
    generalWorker,
    supervisor,
    manager,
  ];
}

/// Driver License Model
/// 
/// Represents a driver's license information.
/// This is stored in a SEPARATE table (driver_licenses), NOT in employees table!

class DriverLicense {
  final int? id;
  final int employeeId;
  final String licenseNumber;
  final String licenseType;        // "Code 8", "Code 10", "Code 14"
  final String? licenseTypes;      // Additional types: "A, B, C"
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? restrictions;      // e.g., "Glasses required"
  final DateTime createdAt;
  final DateTime updatedAt;

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

  /// Check if license is expired
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  /// Check if license is expiring soon (within 90 days)
  bool get isExpiringSoon {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 90;
  }

  /// Get days until expiry
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  /// Convert to Map for database
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

  /// Create from database Map
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

  /// Create a copy with updated fields
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