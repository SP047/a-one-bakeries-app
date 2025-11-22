import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/models/order_model.dart';
import 'package:a_one_bakeries_app/models/finance_model.dart';
import 'package:a_one_bakeries_app/models/supplier_model.dart';

/// ============================================================================
/// DATABASE HELPER - A-One Bakeries App
/// ============================================================================
/// 
/// This singleton class manages ALL database operations for the app.
/// 
/// Tables in this database:
/// 1. stock_items - Inventory items (flour, sugar, etc.)
/// 2. stock_movements - Track stock received/allocated
/// 3. employees - Employee information
/// 4. credit_transactions - Employee money borrowed/repaid
/// 5. employee_documents - Uploaded PDFs for employees
/// 6. vehicles - Company vehicles
/// 7. orders - Daily orders
/// 8. order_items - Items in each order
/// 9. income - Daily income records
/// 10. expenses - Daily expense records
/// 11. suppliers - Supplier information
/// 12. supplier_invoices - Invoices from suppliers
/// 13. supplier_payments - Payments to suppliers
/// 14. driver_licenses - Driver license information (NEW!)
/// 
/// Version History:
/// - Version 1: Initial database with basic tables
/// - Version 2: Added supplier tables
/// - Version 3: Added driver_licenses table
/// ============================================================================

class DatabaseHelper {
  // Singleton pattern - only one instance of DatabaseHelper exists
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Get the database instance (creates it if it doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    // Setup for Windows/Linux/MacOS (desktop platforms)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Get the database file path
    String path = join(await getDatabasesPath(), 'a_one_bakeries.db');
    
    // Open the database (create if doesn't exist)
    return await openDatabase(
      path,
      version: 3,  // <-- UPDATED: Changed from 2 to 3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================================
  // DATABASE CREATION - Creates all tables when app is first installed
  // ============================================================================
  
  Future<void> _onCreate(Database db, int version) async {
    
    // ==========================================================================
    // TABLE 1: STOCK ITEMS
    // Stores inventory items like flour, sugar, yeast, etc.
    // ==========================================================================
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

    // ==========================================================================
    // TABLE 2: STOCK MOVEMENTS
    // Tracks when stock is received from suppliers or allocated to employees
    // ==========================================================================
    await db.execute('''
      CREATE TABLE stock_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stockItemId INTEGER NOT NULL,
        stockItemName TEXT NOT NULL,
        movementType TEXT NOT NULL,
        quantity REAL NOT NULL,
        employeeName TEXT,
        supplierName TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (stockItemId) REFERENCES stock_items(id) ON DELETE CASCADE
      )
    ''');

    // ==========================================================================
    // TABLE 3: EMPLOYEES
    // Stores employee information (name, ID, role, photo, etc.)
    // NOTE: License info is stored in a SEPARATE table (driver_licenses)
    // ==========================================================================
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

    // ==========================================================================
    // TABLE 4: CREDIT TRANSACTIONS
    // Tracks money borrowed by employees and their repayments
    // ==========================================================================
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

    // ==========================================================================
    // TABLE 5: EMPLOYEE DOCUMENTS
    // Stores uploaded PDFs (contracts, payslips, disciplinary records)
    // ==========================================================================
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

    // ==========================================================================
    // TABLE 6: VEHICLES
    // Stores company vehicle information
    // ==========================================================================
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

    // ==========================================================================
    // TABLE 7: ORDERS
    // Stores daily orders for drivers/vehicles
    // ==========================================================================
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

    // ==========================================================================
    // TABLE 8: ORDER ITEMS
    // Stores individual items in each order (bread, biscuits, etc.)
    // ==========================================================================
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

    // ==========================================================================
    // TABLE 9: INCOME
    // Stores daily income records (notes + coins)
    // ==========================================================================
    await db.execute('''
      CREATE TABLE income(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        notes REAL NOT NULL,
        coins REAL NOT NULL,
        total REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // ==========================================================================
    // TABLE 10: EXPENSES
    // Stores daily expense records
    // ==========================================================================
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // ==========================================================================
    // TABLE 11: SUPPLIERS
    // Stores supplier information
    // ==========================================================================
    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contactPerson TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT,
        address TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // ==========================================================================
    // TABLE 12: SUPPLIER INVOICES
    // Stores invoices received from suppliers
    // ==========================================================================
    await db.execute('''
      CREATE TABLE supplier_invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        supplierName TEXT NOT NULL,
        invoiceNumber TEXT NOT NULL,
        amount REAL NOT NULL,
        invoiceDate TEXT NOT NULL,
        dueDate TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');

    // ==========================================================================
    // TABLE 13: SUPPLIER PAYMENTS
    // Stores payments made to suppliers
    // ==========================================================================
    await db.execute('''
      CREATE TABLE supplier_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        supplierName TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        reference TEXT,
        notes TEXT,
        paymentDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');

    // ==========================================================================
    // TABLE 14: DRIVER LICENSES (NEW!)
    // Stores driver license information - linked to employees by employeeId
    // ==========================================================================
    await db.execute('''
      CREATE TABLE driver_licenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        licenseNumber TEXT NOT NULL,
        licenseType TEXT NOT NULL,
        licenseTypes TEXT,
        issueDate TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        restrictions TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');

    // ==========================================================================
    // INDEXES - Speed up database queries
    // ==========================================================================
    await db.execute('CREATE INDEX idx_stock_movements_stockItemId ON stock_movements(stockItemId)');
    await db.execute('CREATE INDEX idx_stock_movements_createdAt ON stock_movements(createdAt)');
    await db.execute('CREATE INDEX idx_credit_transactions_employeeId ON credit_transactions(employeeId)');
    await db.execute('CREATE INDEX idx_employee_documents_employeeId ON employee_documents(employeeId)');
    await db.execute('CREATE INDEX idx_vehicles_assignedDriverId ON vehicles(assignedDriverId)');
    await db.execute('CREATE INDEX idx_orders_driverId ON orders(driverId)');
    await db.execute('CREATE INDEX idx_orders_vehicleId ON orders(vehicleId)');
    await db.execute('CREATE INDEX idx_orders_createdAt ON orders(createdAt)');
    await db.execute('CREATE INDEX idx_order_items_orderId ON order_items(orderId)');
    await db.execute('CREATE INDEX idx_income_createdAt ON income(createdAt)');
    await db.execute('CREATE INDEX idx_expenses_createdAt ON expenses(createdAt)');
    await db.execute('CREATE INDEX idx_supplier_invoices_supplierId ON supplier_invoices(supplierId)');
    await db.execute('CREATE INDEX idx_supplier_payments_supplierId ON supplier_payments(supplierId)');
    await db.execute('CREATE INDEX idx_driver_licenses_employeeId ON driver_licenses(employeeId)');
  }

  // ============================================================================
  // DATABASE UPGRADE - Handles updates when app is updated
  // ============================================================================
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Upgrade from version 1 to 2: Add supplier tables
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          contactPerson TEXT NOT NULL,
          phoneNumber TEXT NOT NULL,
          email TEXT,
          address TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS supplier_invoices(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierId INTEGER NOT NULL,
          supplierName TEXT NOT NULL,
          invoiceNumber TEXT NOT NULL,
          amount REAL NOT NULL,
          invoiceDate TEXT NOT NULL,
          dueDate TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS supplier_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierId INTEGER NOT NULL,
          supplierName TEXT NOT NULL,
          amount REAL NOT NULL,
          paymentMethod TEXT NOT NULL,
          reference TEXT,
          notes TEXT,
          paymentDate TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_supplier_invoices_supplierId ON supplier_invoices(supplierId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_supplier_payments_supplierId ON supplier_payments(supplierId)');
    }

    // Upgrade from version 2 to 3: Add driver_licenses table
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS driver_licenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER NOT NULL,
          licenseNumber TEXT NOT NULL,
          licenseType TEXT NOT NULL,
          licenseTypes TEXT,
          issueDate TEXT NOT NULL,
          expiryDate TEXT NOT NULL,
          restrictions TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (employeeId) REFERENCES employees(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_driver_licenses_employeeId ON driver_licenses(employeeId)');
    }
  }

  // ============================================================================
  // STOCK OPERATIONS
  // ============================================================================

  /// Insert a new stock item
  Future<int> insertStockItem(StockItem item) async {
    final db = await database;
    return await db.insert('stock_items', item.toMap());
  }

  /// Update an existing stock item
  Future<int> updateStockItem(StockItem item) async {
    final db = await database;
    return await db.update('stock_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  /// Delete a stock item
  Future<int> deleteStockItem(int id) async {
    final db = await database;
    return await db.delete('stock_items', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all stock items
  Future<List<StockItem>> getAllStockItems() async {
    final db = await database;
    final maps = await db.query('stock_items', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  /// Get a stock item by ID
  Future<StockItem?> getStockItemById(int id) async {
    final db = await database;
    final maps = await db.query('stock_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return StockItem.fromMap(maps.first);
  }

  /// Insert a stock movement and update stock quantity
  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    
    int movementId = 0;
    await db.transaction((txn) async {
      // Insert the movement record
      movementId = await txn.insert('stock_movements', movement.toMap());
      
      // Update the stock quantity
      final stockMaps = await txn.query('stock_items', where: 'id = ?', whereArgs: [movement.stockItemId]);
      if (stockMaps.isNotEmpty) {
        final stockItem = StockItem.fromMap(stockMaps.first);
        int newQuantity = (movement.movementType == 'RECEIVED'
            ? stockItem.quantityOnHand + movement.quantity
            : stockItem.quantityOnHand - movement.quantity);
        
        await txn.update(
          'stock_items',
          {'quantityOnHand': newQuantity, 'updatedAt': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [movement.stockItemId],
        );
      }
    });
    
    return movementId;
  }

  /// Get all stock movements
  Future<List<StockMovement>> getAllStockMovements() async {
    final db = await database;
    final maps = await db.query('stock_movements', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  /// Get stock movements within a date range
  Future<List<StockMovement>> getStockMovementsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  // ============================================================================
  // EMPLOYEE OPERATIONS
  // ============================================================================

  /// Insert a new employee
  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap());
  }

  /// Update an existing employee
  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update('employees', employee.toMap(), where: 'id = ?', whereArgs: [employee.id]);
  }

  /// Delete an employee
  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all employees
  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final maps = await db.query('employees', orderBy: 'firstName ASC, lastName ASC');
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  /// Get an employee by ID
  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    final maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  /// Get employees by role (e.g., all drivers)
  Future<List<Employee>> getEmployeesByRole(String role) async {
    final db = await database;
    final maps = await db.query('employees', where: 'role = ?', whereArgs: [role], orderBy: 'firstName ASC');
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  // ============================================================================
  // CREDIT TRANSACTION OPERATIONS
  // ============================================================================

  /// Insert a credit transaction (borrow or repay)
  Future<int> insertCreditTransaction(CreditTransaction transaction) async {
    final db = await database;
    return await db.insert('credit_transactions', transaction.toMap());
  }

  /// Update a credit transaction
  Future<int> updateCreditTransaction(CreditTransaction transaction) async {
    final db = await database;
    return await db.update(
      'credit_transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete a credit transaction
  Future<int> deleteCreditTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'credit_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all credit transactions for an employee
  Future<List<CreditTransaction>> getCreditTransactionsByEmployeeId(int employeeId) async {
    final db = await database;
    final maps = await db.query('credit_transactions', where: 'employeeId = ?', whereArgs: [employeeId], orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => CreditTransaction.fromMap(maps[i]));
  }

  /// Calculate an employee's credit balance
  Future<double> getEmployeeCreditBalance(int employeeId) async {
    final transactions = await getCreditTransactionsByEmployeeId(employeeId);
    double balance = 0;
    for (var t in transactions) {
      balance += t.transactionType == 'BORROW' ? t.amount : -t.amount;
    }
    return balance;
  }

  // ============================================================================
  // EMPLOYEE DOCUMENT OPERATIONS
  // ============================================================================

  /// Insert an employee document
  Future<int> insertEmployeeDocument(EmployeeDocument document) async {
    final db = await database;
    return await db.insert('employee_documents', document.toMap());
  }

  /// Get all documents for an employee
  Future<List<EmployeeDocument>> getEmployeeDocuments(int employeeId) async {
    final db = await database;
    final maps = await db.query('employee_documents', where: 'employeeId = ?', whereArgs: [employeeId], orderBy: 'uploadedAt DESC');
    return List.generate(maps.length, (i) => EmployeeDocument.fromMap(maps[i]));
  }

  /// Delete an employee document
  Future<int> deleteEmployeeDocument(int id) async {
    final db = await database;
    return await db.delete('employee_documents', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================================
  // VEHICLE OPERATIONS
  // ============================================================================

  /// Insert a new vehicle
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  /// Update an existing vehicle
  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update('vehicles', vehicle.toMap(), where: 'id = ?', whereArgs: [vehicle.id]);
  }

  /// Delete a vehicle
  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all vehicles
  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final maps = await db.query('vehicles', orderBy: 'make ASC, model ASC');
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Assign a vehicle to a driver
  Future<int> assignVehicleToDriver(int vehicleId, int driverId, String driverName) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {'assignedDriverId': driverId, 'assignedDriverName': driverName, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  /// Unassign a vehicle from a driver
  Future<int> unassignVehicle(int vehicleId) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {'assignedDriverId': null, 'assignedDriverName': null, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  // ============================================================================
  // ORDER OPERATIONS
  // ============================================================================

  /// Insert a new order with its items
  Future<int> insertOrder(Order order, List<OrderItem> items) async {
    final db = await database;
    
    int orderId = 0;
    await db.transaction((txn) async {
      orderId = await txn.insert('orders', order.toMap());
      for (var item in items) {
        await txn.insert('order_items', item.copyWith(orderId: orderId).toMap());
      }
    });
    
    return orderId;
  }

  /// Update an existing order with its items
  Future<int> updateOrder(Order order, List<OrderItem> items) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
      await txn.delete('order_items', where: 'orderId = ?', whereArgs: [order.id]);
      for (var item in items) {
        await txn.insert('order_items', item.toMap());
      }
    });
    
    return order.id!;
  }

  /// Delete an order
  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all orders
  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.query('orders', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  /// Get an order by ID
  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final maps = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  /// Get all items for an order
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final maps = await db.query('order_items', where: 'orderId = ?', whereArgs: [orderId]);
    return List.generate(maps.length, (i) => OrderItem.fromMap(maps[i]));
  }

  /// Get today's total bread quantity
  Future<int> getTodayBreadQuantity() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final ordersResult = await db.rawQuery(
      'SELECT id FROM orders WHERE createdAt BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    
    if (ordersResult.isEmpty) return 0;
    
    final orderIds = ordersResult.map((row) => row['id'] as int).toList();
    final placeholders = List.filled(orderIds.length, '?').join(',');
    
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as totalQty FROM order_items WHERE orderId IN ($placeholders) AND (itemType = ? OR itemType = ?)',
      [...orderIds, OrderItemTypes.brownBread, OrderItemTypes.whiteBread],
    );
    
    return result.first['totalQty'] as int? ?? 0;
  }

  // ============================================================================
  // FINANCE OPERATIONS (Income & Expenses)
  // ============================================================================

  /// Insert income record
  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert('income', income.toMap());
  }

  /// Insert expense record
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  /// Delete income record
  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete expense record
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all income records
  Future<List<Income>> getAllIncome() async {
    final db = await database;
    final maps = await db.query('income', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  /// Get all expense records
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  /// Get total income (all time)
  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(total) as totalIncome FROM income');
    return result.first['totalIncome'] as double? ?? 0.0;
  }

  /// Get total expenses (all time)
  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as totalExpenses FROM expenses');
    return result.first['totalExpenses'] as double? ?? 0.0;
  }

  /// Get money on hand (income - expenses)
  Future<double> getMoneyOnHand() async {
    final totalIncome = await getTotalIncome();
    final totalExpenses = await getTotalExpenses();
    return totalIncome - totalExpenses;
  }

  /// Get today's income
  Future<double> getTodayIncome() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await db.rawQuery(
      'SELECT SUM(total) as todayIncome FROM income WHERE createdAt BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return result.first['todayIncome'] as double? ?? 0.0;
  }

  /// Get today's expenses
  Future<double> getTodayExpenses() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as todayExpenses FROM expenses WHERE createdAt BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return result.first['todayExpenses'] as double? ?? 0.0;
  }

  // ============================================================================
  // SUPPLIER OPERATIONS
  // ============================================================================

  /// Insert a new supplier
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert('suppliers', supplier.toMap());
  }

  /// Update an existing supplier
  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update('suppliers', supplier.toMap(), 
        where: 'id = ?', whereArgs: [supplier.id]);
  }

  /// Delete a supplier
  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all suppliers
  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
  }

  /// Get a supplier by ID
  Future<Supplier?> getSupplierById(int id) async {
    final db = await database;
    final maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Supplier.fromMap(maps.first);
  }

  // ============================================================================
  // SUPPLIER INVOICE OPERATIONS
  // ============================================================================

  /// Insert a supplier invoice
  Future<int> insertSupplierInvoice(SupplierInvoice invoice) async {
    final db = await database;
    return await db.insert('supplier_invoices', invoice.toMap());
  }

  /// Get all invoices for a supplier
  Future<List<SupplierInvoice>> getSupplierInvoices(int supplierId) async {
    final db = await database;
    final maps = await db.query('supplier_invoices', 
        where: 'supplierId = ?', 
        whereArgs: [supplierId],
        orderBy: 'invoiceDate DESC');
    return List.generate(maps.length, (i) => SupplierInvoice.fromMap(maps[i]));
  }

  /// Get total invoices for a supplier
  Future<double> getTotalInvoices(int supplierId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM supplier_invoices WHERE supplierId = ?',
      [supplierId],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // ============================================================================
  // SUPPLIER PAYMENT OPERATIONS
  // ============================================================================

  /// Insert a supplier payment
  Future<int> insertSupplierPayment(SupplierPayment payment) async {
    final db = await database;
    return await db.insert('supplier_payments', payment.toMap());
  }

  /// Get all payments for a supplier
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async {
    final db = await database;
    final maps = await db.query('supplier_payments', 
        where: 'supplierId = ?', 
        whereArgs: [supplierId],
        orderBy: 'paymentDate DESC');
    return List.generate(maps.length, (i) => SupplierPayment.fromMap(maps[i]));
  }

  /// Get total payments for a supplier
  Future<double> getTotalPayments(int supplierId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM supplier_payments WHERE supplierId = ?',
      [supplierId],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  /// Get supplier balance (invoices - payments)
  Future<double> getSupplierBalance(int supplierId) async {
    final totalInvoices = await getTotalInvoices(supplierId);
    final totalPayments = await getTotalPayments(supplierId);
    return totalInvoices - totalPayments;
  }

  // ============================================================================
  // DRIVER LICENSE OPERATIONS (NEW!)
  // ============================================================================

  /// Insert a new driver license
  Future<int> insertDriverLicense(DriverLicense license) async {
    final db = await database;
    return await db.insert('driver_licenses', license.toMap());
  }

  /// Update an existing driver license
  Future<int> updateDriverLicense(DriverLicense license) async {
    final db = await database;
    return await db.update(
      'driver_licenses',
      license.toMap(),
      where: 'id = ?',
      whereArgs: [license.id],
    );
  }

  /// Delete a driver license
  Future<int> deleteDriverLicense(int id) async {
    final db = await database;
    return await db.delete('driver_licenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Get a driver's license by employee ID
  Future<DriverLicense?> getDriverLicense(int employeeId) async {
    final db = await database;
    final maps = await db.query(
      'driver_licenses',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
    );
    if (maps.isEmpty) return null;
    return DriverLicense.fromMap(maps.first);
  }

  /// Get all driver licenses
  Future<List<DriverLicense>> getAllDriverLicenses() async {
    final db = await database;
    final maps = await db.query('driver_licenses', orderBy: 'expiryDate ASC');
    return List.generate(maps.length, (i) => DriverLicense.fromMap(maps[i]));
  }

  /// Get licenses expiring within a certain number of days
  Future<List<DriverLicense>> getExpiringLicenses({int daysAhead = 90}) async {
    final db = await database;
    final today = DateTime.now();
    final futureDate = today.add(Duration(days: daysAhead));
    
    final maps = await db.query(
      'driver_licenses',
      where: 'expiryDate BETWEEN ? AND ?',
      whereArgs: [today.toIso8601String(), futureDate.toIso8601String()],
      orderBy: 'expiryDate ASC',
    );
    return List.generate(maps.length, (i) => DriverLicense.fromMap(maps[i]));
  }

  // ============================================================================
  // DATABASE UTILITIES
  // ============================================================================

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}