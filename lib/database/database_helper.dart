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

/// Database Helper - Complete Working Version
/// 
/// Singleton class that manages all database operations.
/// Version 1: Clean start with all tables properly structured.

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    String path = join(await getDatabasesPath(), 'a_one_bakeries.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,  // <-- Add this
    );
  }

  Future<void> _onCreate(Database db, int version) async {
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add supplier tables
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

    // Add supplierName column to stock_movements
    await db.execute('ALTER TABLE stock_movements ADD COLUMN supplierName TEXT');

    // Add indexes
    await db.execute('CREATE INDEX idx_supplier_invoices_supplierId ON supplier_invoices(supplierId)');
    await db.execute('CREATE INDEX idx_supplier_payments_supplierId ON supplier_payments(supplierId)');
  }
} 
    // Stock Items
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

    // Stock Movements
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

    // Employees
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

    // Credit Transactions
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

    // Employee Documents
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

    // Vehicles
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

    // Orders
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

    // Order Items
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

    // Income (with description column from start)
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

    // Expenses
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    

    // Suppliers
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

// Supplier Invoices
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

// Supplier Payments
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

    // Create all indexes
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
  }

  // ==================== STOCK OPERATIONS ====================

  Future<int> insertStockItem(StockItem item) async {
    final db = await database;
    return await db.insert('stock_items', item.toMap());
  }

  Future<int> updateStockItem(StockItem item) async {
    final db = await database;
    return await db.update('stock_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteStockItem(int id) async {
    final db = await database;
    return await db.delete('stock_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StockItem>> getAllStockItems() async {
    final db = await database;
    final maps = await db.query('stock_items', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  Future<StockItem?> getStockItemById(int id) async {
    final db = await database;
    final maps = await db.query('stock_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return StockItem.fromMap(maps.first);
  }

  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    
    int movementId = 0;
    await db.transaction((txn) async {
      movementId = await txn.insert('stock_movements', movement.toMap());
      
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

  Future<List<StockMovement>> getAllStockMovements() async {
    final db = await database;
    final maps = await db.query('stock_movements', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

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

  // ==================== EMPLOYEE OPERATIONS ====================

  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap());
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update('employees', employee.toMap(), where: 'id = ?', whereArgs: [employee.id]);
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final maps = await db.query('employees', orderBy: 'firstName ASC, lastName ASC');
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    final maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  Future<List<Employee>> getEmployeesByRole(String role) async {
    final db = await database;
    final maps = await db.query('employees', where: 'role = ?', whereArgs: [role], orderBy: 'firstName ASC');
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  Future<int> insertCreditTransaction(CreditTransaction transaction) async {
    final db = await database;
    return await db.insert('credit_transactions', transaction.toMap());
  }

  /// Update credit transaction - NEW METHOD
  Future<int> updateCreditTransaction(CreditTransaction transaction) async {
  final db = await database;
  return await db.update(
    'credit_transactions',
    transaction.toMap(),
    where: 'id = ?',
    whereArgs: [transaction.id],
  );
  } 

  /// Delete credit transaction - NEW METHOD
  Future<int> deleteCreditTransaction(int id) async {
  final db = await database;
  return await db.delete(
    'credit_transactions',
    where: 'id = ?',
    whereArgs: [id],
  );
  }

  Future<List<CreditTransaction>> getCreditTransactionsByEmployeeId(int employeeId) async {
    final db = await database;
    final maps = await db.query('credit_transactions', where: 'employeeId = ?', whereArgs: [employeeId], orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => CreditTransaction.fromMap(maps[i]));
  }

  Future<double> getEmployeeCreditBalance(int employeeId) async {
    final transactions = await getCreditTransactionsByEmployeeId(employeeId);
    double balance = 0;
    for (var t in transactions) {
      balance += t.transactionType == 'BORROW' ? t.amount : -t.amount;
    }
    return balance;
  }

  Future<int> insertEmployeeDocument(EmployeeDocument document) async {
    final db = await database;
    return await db.insert('employee_documents', document.toMap());
  }

  Future<List<EmployeeDocument>> getEmployeeDocuments(int employeeId) async {
    final db = await database;
    final maps = await db.query('employee_documents', where: 'employeeId = ?', whereArgs: [employeeId], orderBy: 'uploadedAt DESC');
    return List.generate(maps.length, (i) => EmployeeDocument.fromMap(maps[i]));
  }

  Future<int> deleteEmployeeDocument(int id) async {
  final db = await database;
  return await db.delete('employee_documents', where: 'id = ?', whereArgs: [id]);
}

  // ==================== VEHICLE OPERATIONS ====================

  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update('vehicles', vehicle.toMap(), where: 'id = ?', whereArgs: [vehicle.id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final maps = await db.query('vehicles', orderBy: 'make ASC, model ASC');
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  Future<int> assignVehicleToDriver(int vehicleId, int driverId, String driverName) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {'assignedDriverId': driverId, 'assignedDriverName': driverName, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  Future<int> unassignVehicle(int vehicleId) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {'assignedDriverId': null, 'assignedDriverName': null, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  // ==================== ORDER OPERATIONS ====================

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

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.query('orders', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final maps = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final maps = await db.query('order_items', where: 'orderId = ?', whereArgs: [orderId]);
    return List.generate(maps.length, (i) => OrderItem.fromMap(maps[i]));
  }

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

  // ==================== FINANCE OPERATIONS ====================

  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert('income', income.toMap());
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Income>> getAllIncome() async {
    final db = await database;
    final maps = await db.query('income', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(total) as totalIncome FROM income');
    return result.first['totalIncome'] as double? ?? 0.0;
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as totalExpenses FROM expenses');
    return result.first['totalExpenses'] as double? ?? 0.0;
  }

  Future<double> getMoneyOnHand() async {
    final totalIncome = await getTotalIncome();
    final totalExpenses = await getTotalExpenses();
    return totalIncome - totalExpenses;
  }

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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ==================== SUPPLIER OPERATIONS ====================

Future<int> insertSupplier(Supplier supplier) async {
  final db = await database;
  return await db.insert('suppliers', supplier.toMap());
}

Future<int> updateSupplier(Supplier supplier) async {
  final db = await database;
  return await db.update('suppliers', supplier.toMap(), 
      where: 'id = ?', whereArgs: [supplier.id]);
}

Future<int> deleteSupplier(int id) async {
  final db = await database;
  return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
}

Future<List<Supplier>> getAllSuppliers() async {
  final db = await database;
  final maps = await db.query('suppliers', orderBy: 'name ASC');
  return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
}

Future<Supplier?> getSupplierById(int id) async {
  final db = await database;
  final maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
  if (maps.isEmpty) return null;
  return Supplier.fromMap(maps.first);
}

// Supplier Invoices
Future<int> insertSupplierInvoice(SupplierInvoice invoice) async {
  final db = await database;
  return await db.insert('supplier_invoices', invoice.toMap());
}

Future<List<SupplierInvoice>> getSupplierInvoices(int supplierId) async {
  final db = await database;
  final maps = await db.query('supplier_invoices', 
      where: 'supplierId = ?', 
      whereArgs: [supplierId],
      orderBy: 'invoiceDate DESC');
  return List.generate(maps.length, (i) => SupplierInvoice.fromMap(maps[i]));
}

Future<double> getTotalInvoices(int supplierId) async {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT SUM(amount) as total FROM supplier_invoices WHERE supplierId = ?',
    [supplierId],
  );
  return result.first['total'] as double? ?? 0.0;
}

// Supplier Payments
Future<int> insertSupplierPayment(SupplierPayment payment) async {
  final db = await database;
  return await db.insert('supplier_payments', payment.toMap());
}

Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async {
  final db = await database;
  final maps = await db.query('supplier_payments', 
      where: 'supplierId = ?', 
      whereArgs: [supplierId],
      orderBy: 'paymentDate DESC');
  return List.generate(maps.length, (i) => SupplierPayment.fromMap(maps[i]));
}

Future<double> getTotalPayments(int supplierId) async {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT SUM(amount) as total FROM supplier_payments WHERE supplierId = ?',
    [supplierId],
  );
  return result.first['total'] as double? ?? 0.0;
}

Future<double> getSupplierBalance(int supplierId) async {
  final totalInvoices = await getTotalInvoices(supplierId);
  final totalPayments = await getTotalPayments(supplierId);
  return totalInvoices - totalPayments;
}


  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) {
  }
}