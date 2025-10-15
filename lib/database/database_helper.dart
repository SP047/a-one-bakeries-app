import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';

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
      version: 1,
      onCreate: _onCreate,
    );
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
  }
}