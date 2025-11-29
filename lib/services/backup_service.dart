import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// ============================================================================
/// Backup Service - A-One Bakeries App
/// ============================================================================
/// Handles database backup, restore, and export operations.
/// ============================================================================

class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime createdDate;
  final int fileSize;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdDate,
    required this.fileSize,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdDate);
  }
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get the backup directory path
  Future<String> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(documentsDir.path, 'A-One Bakeries', 'Backups'));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir.path;
  }

  /// Get the export directory path
  Future<String> _getExportDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(join(documentsDir.path, 'A-One Bakeries', 'Exports'));
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return exportDir.path;
  }

  /// Create a full database backup
  /// Returns the path to the backup file
  Future<String> createBackup() async {
    try {
      // Get current database path
      final db = await _dbHelper.database;
      final dbPath = db.path;
      
      // Create backup filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'a_one_bakeries_backup_$timestamp.db';
      
      // Get backup directory
      final backupDir = await _getBackupDirectory();
      final backupPath = join(backupDir, backupFileName);
      
      // Copy database file
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);
      
      // Clean up old backups (keep last 10)
      await _cleanupOldBackups();
      
      return backupPath;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  /// Restore database from backup file
  Future<bool> restoreBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      
      // Validate backup file exists
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }
      
      // Validate it's a valid SQLite database
      if (!await _validateBackup(backupPath)) {
        throw Exception('Invalid backup file');
      }
      
      // Get current database path
      final db = await _dbHelper.database;
      final dbPath = db.path;
      
      // Close database connection
      await db.close();
      
      // Replace current database with backup
      await backupFile.copy(dbPath);
      
      // Reopen database
      await _dbHelper.database;
      
      return true;
    } catch (e) {
      // Try to reopen database even if restore failed
      await _dbHelper.database;
      throw Exception('Failed to restore backup: $e');
    }
  }

  /// Validate backup file
  Future<bool> _validateBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      
      // Check file exists and has content
      if (!await file.exists() || await file.length() == 0) {
        return false;
      }
      
      // Check SQLite file signature (first 16 bytes should be "SQLite format 3\0")
      final bytes = await file.openRead(0, 16).first;
      final signature = String.fromCharCodes(bytes.take(15));
      
      return signature == 'SQLite format 3';
    } catch (e) {
      return false;
    }
  }

  /// Get list of available backups
  Future<List<BackupInfo>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      final directory = Directory(backupDir);
      
      final backups = <BackupInfo>[];
      
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.db')) {
          final stat = await entity.stat();
          final fileName = basename(entity.path);
          
          backups.add(BackupInfo(
            fileName: fileName,
            filePath: entity.path,
            createdDate: stat.modified,
            fileSize: stat.size,
          ));
        }
      }
      
      // Sort by date (newest first)
      backups.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      
      return backups;
    } catch (e) {
      throw Exception('Failed to list backups: $e');
    }
  }

  /// Delete a backup file
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  /// Clean up old backups (keep last 10)
  Future<void> _cleanupOldBackups() async {
    try {
      final backups = await listBackups();
      
      // Keep only the 10 most recent backups
      if (backups.length > 10) {
        for (int i = 10; i < backups.length; i++) {
          await deleteBackup(backups[i].filePath);
        }
      }
    } catch (e) {
      // Don't throw error if cleanup fails
      print('Warning: Failed to cleanup old backups: $e');
    }
  }

  /// Export table data to CSV
  Future<String> exportTableToCSV(String tableName) async {
    try {
      final db = await _dbHelper.database;
      final data = await db.query(tableName);
      
      if (data.isEmpty) {
        throw Exception('No data to export from $tableName');
      }
      
      // Create CSV content
      final buffer = StringBuffer();
      
      // Header row
      final headers = data.first.keys.toList();
      buffer.writeln(headers.join(','));
      
      // Data rows
      for (final row in data) {
        final values = headers.map((header) {
          final value = row[header]?.toString() ?? '';
          // Escape commas and quotes
          if (value.contains(',') || value.contains('"')) {
            return '"${value.replaceAll('"', '""')}"';
          }
          return value;
        }).toList();
        buffer.writeln(values.join(','));
      }
      
      // Save to file
      final exportDir = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${tableName}_export_$timestamp.csv';
      final filePath = join(exportDir, fileName);
      
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export $tableName to CSV: $e');
    }
  }

  /// Export all data to JSON
  Future<String> exportAllDataToJSON() async {
    try {
      final db = await _dbHelper.database;
      
      // List of tables to export
      final tables = [
        'stock_items',
        'stock_movements',
        'employees',
        'credit_transactions',
        'employee_documents',
        'vehicles',
        'orders',
        'order_items',
        'income',
        'expenses',
        'suppliers',
        'supplier_invoices',
        'supplier_payments',
        'driver_licenses',
        'km_records',
        'service_records',
      ];
      
      final exportData = <String, List<Map<String, dynamic>>>{};
      
      for (final table in tables) {
        try {
          final data = await db.query(table);
          exportData[table] = data;
        } catch (e) {
          // Skip tables that don't exist
          print('Warning: Could not export table $table: $e');
        }
      }
      
      // Convert to JSON string
      final jsonString = '''
{
  "exportDate": "${DateTime.now().toIso8601String()}",
  "appName": "A-One Bakeries",
  "databaseVersion": 6,
  "data": ${exportData.toString()}
}
''';
      
      // Save to file
      final exportDir = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'a_one_bakeries_full_export_$timestamp.json';
      final filePath = join(exportDir, fileName);
      
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export data to JSON: $e');
    }
  }

  /// Get backup file size
  Future<int> getBackupSize(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
