import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';

/// Database Helper
/// 
/// Singleton class that manages all database operations.
/// Uses SQLite for local data storage.
/// 
/// Features:
/// - Create and manage database tables
/// - CRUD operations for all models
/// - Query operations with filters

class DatabaseHelper {
  // Singleton pattern - only one instance of database helper
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Get database instance (create if doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Get the database path
    String path = join(await getDatabasesPath(), 'a_one_bakeries.db');
    
    // Open/create the database
    return await openDatabase(
      path,
      version: 2, // CHANGED FROM 1 TO 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Upgrade database when version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add employee tables for version 2
      await db.execute('''
        CREATE TABLE employees(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          idNumber TEXT NOT NULL UNIQUE,
          idType TEXT NOT NULL,
          birthDate TEXT NOT NULL,
          role TEXT NOT NULL,
          photoPath TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE credit_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER NOT NULL,
          employeeName TEXT NOT NULL,
          transactionType TEXT NOT NULL,
          amount REAL NOT NULL,
          reason TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (employeeId) REFERENCES employees(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE employee_documents(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER NOT NULL,
          documentType TEXT NOT NULL,
          fileName TEXT NOT NULL,
          filePath TEXT NOT NULL,
          uploadedAt TEXT NOT NULL,
          FOREIGN KEY (employeeId) REFERENCES employees(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_credit_transactions_employeeId ON credit_transactions(employeeId)
      ''');

      await db.execute('''
        CREATE INDEX idx_employee_documents_employeeId ON employee_documents(employeeId)
      ''');
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Stock Items Table
    await db.execute('''
      CREATE TABLE stock_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantityOnHand REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Stock Movements Table
    await db.execute('''
      CREATE TABLE stock_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stockItemId INTEGER NOT NULL,
        stockItemName TEXT NOT NULL,
        movementType TEXT NOT NULL,
        quantity REAL NOT NULL,
        employeeName TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (stockItemId) REFERENCES stock_items(id) ON DELETE CASCADE
      )
    ''');

    // Create index on stockItemId for faster queries
    await db.execute('''
      CREATE INDEX idx_stock_movements_stockItemId ON stock_movements(stockItemId)
    ''');

    // Create index on createdAt for faster date queries
    await db.execute('''
      CREATE INDEX idx_stock_movements_createdAt ON stock_movements(createdAt)
    ''');

    // Employees Table
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        idNumber TEXT NOT NULL UNIQUE,
        idType TEXT NOT NULL,
        birthDate TEXT NOT NULL,
        role TEXT NOT NULL,
        photoPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Credit Transactions Table
    await db.execute('''
      CREATE TABLE credit_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        transactionType TEXT NOT NULL,
        amount REAL NOT NULL,
        reason TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');

    // Employee Documents Table
    await db.execute('''
      CREATE TABLE employee_documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        documentType TEXT NOT NULL,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        uploadedAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for employee-related tables
    await db.execute('''
      CREATE INDEX idx_credit_transactions_employeeId ON credit_transactions(employeeId)
    ''');

    await db.execute('''
      CREATE INDEX idx_employee_documents_employeeId ON employee_documents(employeeId)
    ''');
  }

  // ==================== STOCK ITEMS OPERATIONS ====================

  /// Insert a new stock item
  Future<int> insertStockItem(StockItem item) async {
    final db = await database;
    return await db.insert('stock_items', item.toMap());
  }

  /// Update an existing stock item
  Future<int> updateStockItem(StockItem item) async {
    final db = await database;
    return await db.update(
      'stock_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a stock item
  Future<int> deleteStockItem(int id) async {
    final db = await database;
    // This will also delete related stock movements due to CASCADE
    return await db.delete(
      'stock_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all stock items
  Future<List<StockItem>> getAllStockItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_items',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  /// Get a single stock item by ID
  Future<StockItem?> getStockItemById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return StockItem.fromMap(maps.first);
  }

  /// Search stock items by name
  Future<List<StockItem>> searchStockItems(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  // ==================== STOCK MOVEMENTS OPERATIONS ====================

  /// Insert a new stock movement and update stock quantity
  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    
    // Start transaction to ensure both operations succeed or fail together
    return await db.transaction((txn) async {
      // Insert the movement record
      final movementId = await txn.insert('stock_movements', movement.toMap());
      
      // Update the stock quantity
      final stockItem = await getStockItemById(movement.stockItemId);
      if (stockItem != null) {
        double newQuantity;
        if (movement.movementType == 'RECEIVED') {
          newQuantity = stockItem.quantityOnHand + movement.quantity;
        } else {
          // ALLOCATED
          newQuantity = stockItem.quantityOnHand - movement.quantity;
        }
        
        await txn.update(
          'stock_items',
          {
            'quantityOnHand': newQuantity,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [movement.stockItemId],
        );
      }
      
      return movementId;
    });
  }

  /// Get all stock movements
  Future<List<StockMovement>> getAllStockMovements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  /// Get stock movements for a specific stock item
  Future<List<StockMovement>> getStockMovementsByItemId(int stockItemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'stockItemId = ?',
      whereArgs: [stockItemId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  /// Get stock movements filtered by date range
  Future<List<StockMovement>> getStockMovementsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  /// Get stock movements filtered by type (RECEIVED or ALLOCATED)
  Future<List<StockMovement>> getStockMovementsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'movementType = ?',
      whereArgs: [type],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  // ==================== EMPLOYEE OPERATIONS ====================

  /// Insert a new employee
  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap());
  }

  /// Update an existing employee
  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  /// Delete an employee
  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all employees
  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      orderBy: 'firstName ASC, lastName ASC',
    );
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  /// Get a single employee by ID
  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  /// Search employees by name
  Future<List<Employee>> searchEmployees(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'firstName LIKE ? OR lastName LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'firstName ASC, lastName ASC',
    );
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  /// Get employees by role
  Future<List<Employee>> getEmployeesByRole(String role) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'firstName ASC, lastName ASC',
    );
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  // ==================== CREDIT TRANSACTION OPERATIONS ====================

  /// Insert a new credit transaction
  Future<int> insertCreditTransaction(CreditTransaction transaction) async {
    final db = await database;
    return await db.insert('credit_transactions', transaction.toMap());
  }

  /// Get all credit transactions for an employee
  Future<List<CreditTransaction>> getCreditTransactionsByEmployeeId(
      int employeeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'credit_transactions',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(
        maps.length, (i) => CreditTransaction.fromMap(maps[i]));
  }

  /// Calculate total credit balance for an employee
  Future<double> getEmployeeCreditBalance(int employeeId) async {
    final transactions = await getCreditTransactionsByEmployeeId(employeeId);
    double balance = 0;
    for (var transaction in transactions) {
      if (transaction.transactionType == 'BORROW') {
        balance += transaction.amount;
      } else {
        // REPAY
        balance -= transaction.amount;
      }
    }
    return balance;
  }

  // ==================== EMPLOYEE DOCUMENT OPERATIONS ====================

  /// Insert a new employee document
  Future<int> insertEmployeeDocument(EmployeeDocument document) async {
    final db = await database;
    return await db.insert('employee_documents', document.toMap());
  }

  /// Delete an employee document
  Future<int> deleteEmployeeDocument(int id) async {
    final db = await database;
    return await db.delete(
      'employee_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all documents for an employee
  Future<List<EmployeeDocument>> getEmployeeDocuments(int employeeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employee_documents',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'uploadedAt DESC',
    );
    return List.generate(maps.length, (i) => EmployeeDocument.fromMap(maps[i]));
  }

  /// Get documents by type for an employee
  Future<List<EmployeeDocument>> getEmployeeDocumentsByType(
    int employeeId,
    String documentType,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employee_documents',
      where: 'employeeId = ? AND documentType = ?',
      whereArgs: [employeeId, documentType],
      orderBy: 'uploadedAt DESC',
    );
    return List.generate(maps.length, (i) => EmployeeDocument.fromMap(maps[i]));
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Delete all data (for testing purposes)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('stock_movements');
    await db.delete('stock_items');
    await db.delete('credit_transactions');
    await db.delete('employee_documents');
    await db.delete('employees');
  }
}