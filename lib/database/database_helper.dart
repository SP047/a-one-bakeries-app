import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/models/order_model.dart';

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
      version: 5, // CHANGED FROM 4 TO 5
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
    
    if (oldVersion < 3) {
      // Add vehicles table for version 3
      await db.execute('''
        CREATE TABLE vehicles(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          make TEXT NOT NULL,
          model TEXT NOT NULL,
          year INTEGER NOT NULL,
          registrationNumber TEXT NOT NULL UNIQUE,
          assignedDriverId INTEGER,
          assignedDriverName TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (assignedDriverId) REFERENCES employees(id) ON DELETE SET NULL
        )
      ''');
      
      await db.execute('''
        CREATE INDEX idx_vehicles_assignedDriverId ON vehicles(assignedDriverId)
      ''');
    }
    
    if (oldVersion < 4) {
      // Add orders tables for version 4
      await db.execute('''
        CREATE TABLE orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          driverId INTEGER,
          driverName TEXT,
          vehicleId INTEGER,
          vehicleInfo TEXT,
          totalAmount REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'PENDING',
          createdAt TEXT NOT NULL,
          FOREIGN KEY (driverId) REFERENCES employees(id) ON DELETE SET NULL,
          FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE SET NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE order_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER NOT NULL,
          itemType TEXT NOT NULL,
          trollies INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          total REAL NOT NULL,
          FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE INDEX idx_orders_driverId ON orders(driverId)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_orders_vehicleId ON orders(vehicleId)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_orders_createdAt ON orders(createdAt)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_order_items_orderId ON order_items(orderId)
      ''');
    }
    
    if (oldVersion < 5) {
      // Update orders table structure for version 5
      // Drop old tables and recreate with new structure
      await db.execute('DROP TABLE IF EXISTS order_items');
      await db.execute('DROP TABLE IF EXISTS orders');
      
      await db.execute('''
        CREATE TABLE orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          driverId INTEGER,
          driverName TEXT,
          vehicleId INTEGER,
          vehicleInfo TEXT,
          totalQuantity INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (driverId) REFERENCES employees(id) ON DELETE SET NULL,
          FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE SET NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE order_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER NOT NULL,
          itemType TEXT NOT NULL,
          trolliesOrQty INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE INDEX idx_orders_driverId ON orders(driverId)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_orders_vehicleId ON orders(vehicleId)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_orders_createdAt ON orders(createdAt)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_order_items_orderId ON order_items(orderId)
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

    // Vehicles Table
    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        registrationNumber TEXT NOT NULL UNIQUE,
        assignedDriverId INTEGER,
        assignedDriverName TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (assignedDriverId) REFERENCES employees(id) ON DELETE SET NULL
      )
    ''');
    
    await db.execute('''
      CREATE INDEX idx_vehicles_assignedDriverId ON vehicles(assignedDriverId)
    ''');

    // Orders Table
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driverId INTEGER,
        driverName TEXT,
        vehicleId INTEGER,
        vehicleInfo TEXT,
        totalQuantity INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (driverId) REFERENCES employees(id) ON DELETE SET NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE SET NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        itemType TEXT NOT NULL,
        trolliesOrQty INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE INDEX idx_orders_driverId ON orders(driverId)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_orders_vehicleId ON orders(vehicleId)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_orders_createdAt ON orders(createdAt)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_order_items_orderId ON order_items(orderId)
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
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('stock_movements');
    await db.delete('stock_items');
    await db.delete('credit_transactions');
    await db.delete('employee_documents');
    await db.delete('employees');
    await db.delete('vehicles');
  }

  // ==================== VEHICLE OPERATIONS ====================

  /// Insert a new vehicle
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  /// Update an existing vehicle
  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  /// Delete a vehicle
  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all vehicles
  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      orderBy: 'make ASC, model ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Get a single vehicle by ID
  Future<Vehicle?> getVehicleById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  /// Get assigned vehicles
  Future<List<Vehicle>> getAssignedVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'assignedDriverId IS NOT NULL',
      orderBy: 'make ASC, model ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Get unassigned vehicles
  Future<List<Vehicle>> getUnassignedVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'assignedDriverId IS NULL',
      orderBy: 'make ASC, model ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Get vehicles assigned to a specific driver
  Future<List<Vehicle>> getVehiclesByDriverId(int driverId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'assignedDriverId = ?',
      whereArgs: [driverId],
      orderBy: 'make ASC, model ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Assign vehicle to driver
  Future<int> assignVehicleToDriver(int vehicleId, int driverId, String driverName) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {
        'assignedDriverId': driverId,
        'assignedDriverName': driverName,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  /// Unassign vehicle from driver
  Future<int> unassignVehicle(int vehicleId) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {
        'assignedDriverId': null,
        'assignedDriverName': null,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }
  
  // ==================== ORDER OPERATIONS ====================

  /// Insert a new order with its items (transaction)
  Future<int> insertOrder(Order order, List<OrderItem> items) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      // Insert order
      final orderId = await txn.insert('orders', order.toMap());
      
      // Insert order items
      for (var item in items) {
        await txn.insert('order_items', item.copyWith(orderId: orderId).toMap());
      }
      
      return orderId;
    });
  }

  /// Update an order (for editing)
  Future<int> updateOrder(Order order, List<OrderItem> items) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      // Update order
      await txn.update(
        'orders',
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );
      
      // Delete old items
      await txn.delete(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [order.id],
      );
      
      // Insert new items
      for (var item in items) {
        await txn.insert('order_items', item.toMap());
      }
      
      return order.id!;
    });
  }

  /// Delete an order (will cascade delete order items)
  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all orders
  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  /// Get a single order by ID
  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  /// Get order items for a specific order
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
    return List.generate(maps.length, (i) => OrderItem.fromMap(maps[i]));
  }

  /// Get orders by driver ID
  Future<List<Order>> getOrdersByDriverId(int driverId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'driverId = ?',
      whereArgs: [driverId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  /// Get orders by vehicle ID
  Future<List<Order>> getOrdersByVehicleId(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  /// Get orders by date range
  Future<List<Order>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  /// Get orders by status
  Future<List<Order>> getOrdersByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  /// Get today's bread quantities (Brown Bread + White Bread only)
  Future<int> getTodayBreadQuantity() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Get all order IDs from today
    final ordersResult = await db.rawQuery(
      'SELECT id FROM orders WHERE createdAt BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    
    if (ordersResult.isEmpty) return 0;
    
    final orderIds = ordersResult.map((row) => row['id'] as int).toList();
    final placeholders = List.filled(orderIds.length, '?').join(',');
    
    // Sum quantities for Brown Bread and White Bread only
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as totalQty FROM order_items WHERE orderId IN ($placeholders) AND (itemType = ? OR itemType = ?)',
      [...orderIds, OrderItemTypes.brownBread, OrderItemTypes.whiteBread],
    );
    
    return result.first['totalQty'] as int? ?? 0;
  }

  /// Get order performance summary
  Future<Map<String, dynamic>> getOrderPerformance({
    int? driverId,
    int? vehicleId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (driverId != null) {
      whereClause += ' AND driverId = ?';
      whereArgs.add(driverId);
    }
    
    if (vehicleId != null) {
      whereClause += ' AND vehicleId = ?';
      whereArgs.add(vehicleId);
    }
    
    if (startDate != null && endDate != null) {
      whereClause += ' AND createdAt BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as totalOrders, SUM(totalAmount) as totalAmount FROM orders WHERE $whereClause',
      whereArgs,
    );
    
    return {
      'totalOrders': result.first['totalOrders'] as int? ?? 0,
      'totalAmount': result.first['totalAmount'] as double? ?? 0.0,
    };
  }
}
