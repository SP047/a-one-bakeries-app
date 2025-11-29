# Add KM tracking methods to database_helper.dart

with open('lib/database/database_helper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports at the top if not present
if 'km_record_model.dart' not in content:
    content = content.replace(
        "import 'package:a_one_bakeries_app/models/supplier_model.dart';",
        "import 'package:a_one_bakeries_app/models/supplier_model.dart';\nimport 'package:a_one_bakeries_app/models/km_record_model.dart';\nimport 'package:a_one_bakeries_app/models/service_record_model.dart';"
    )

# Add KM tracking methods before the final closing brace
km_methods = '''
  // ============================================================================
  // KM TRACKING OPERATIONS
  // ============================================================================

  /// Add a new KM record and update vehicle's current KM
  Future<int> addKmRecord(KmRecord record) async {
    final db = await database;
    
    int recordId = 0;
    await db.transaction((txn) async {
      // Insert the KM record
      recordId = await txn.insert('km_records', record.toMap());
      
      // Update vehicle's current KM
      await txn.update(
        'vehicles',
        {
          'currentKm': record.kmReading,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [record.vehicleId],
      );
    });
    
    return recordId;
  }

  /// Get all KM records for a vehicle
  Future<List<KmRecord>> getVehicleKmRecords(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'km_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'recordedDate DESC',
    );
    return List.generate(maps.length, (i) => KmRecord.fromMap(maps[i]));
  }

  /// Get latest KM record for a vehicle
  Future<KmRecord?> getLatestKmRecord(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'km_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'recordedDate DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return KmRecord.fromMap(maps.first);
  }

  /// Update vehicle's current KM
  Future<int> updateVehicleKm(int vehicleId, int newKm) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {
        'currentKm': newKm,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  // ============================================================================
  // SERVICE RECORD OPERATIONS
  // ============================================================================

  /// Add a service record and update vehicle's service KM
  Future<int> addServiceRecord(ServiceRecord record) async {
    final db = await database;
    
    int recordId = 0;
    await db.transaction((txn) async {
      // Insert the service record
      recordId = await txn.insert('service_records', record.toMap());
      
      // Get vehicle's service interval
      final vehicleMaps = await txn.query(
        'vehicles',
        where: 'id = ?',
        whereArgs: [record.vehicleId],
      );
      
      if (vehicleMaps.isNotEmpty) {
        final serviceInterval = vehicleMaps.first['serviceIntervalKm'] as int? ?? 10000;
        final nextServiceKm = record.serviceKm + serviceInterval;
        
        // Update vehicle's service KM
        await txn.update(
          'vehicles',
          {
            'lastServiceKm': record.serviceKm,
            'nextServiceKm': nextServiceKm,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [record.vehicleId],
        );
      }
    });
    
    return recordId;
  }

  /// Get all service records for a vehicle
  Future<List<ServiceRecord>> getVehicleServiceRecords(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'service_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'serviceDate DESC',
    );
    return List.generate(maps.length, (i) => ServiceRecord.fromMap(maps[i]));
  }

  /// Update vehicle's service interval
  Future<int> updateVehicleServiceInterval(int vehicleId, int intervalKm) async {
    final db = await database;
    
    // Get current lastServiceKm
    final maps = await db.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
    
    if (maps.isEmpty) return 0;
    
    final lastServiceKm = maps.first['lastServiceKm'] as int? ?? 0;
    final nextServiceKm = lastServiceKm + intervalKm;
    
    return await db.update(
      'vehicles',
      {
        'serviceIntervalKm': intervalKm,
        'nextServiceKm': nextServiceKm,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  /// Get vehicles due for service
  Future<List<Vehicle>> getVehiclesDueForService() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM vehicles WHERE currentKm >= nextServiceKm ORDER BY currentKm DESC'
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Get vehicles approaching service (within threshold KM)
  Future<List<Vehicle>> getVehiclesApproachingService(int thresholdKm) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM vehicles WHERE (nextServiceKm - currentKm) <= ? AND (nextServiceKm - currentKm) > 0 ORDER BY (nextServiceKm - currentKm) ASC',
      [thresholdKm]
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  /// Get KM records within date range
  Future<List<KmRecord>> getKmRecordsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final maps = await db.query(
      'km_records',
      where: 'recordedDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'recordedDate DESC',
    );
    return List.generate(maps.length, (i) => KmRecord.fromMap(maps[i]));
  }

  /// Get service records within date range
  Future<List<ServiceRecord>> getServiceRecordsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final maps = await db.query(
      'service_records',
      where: 'serviceDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'serviceDate DESC',
    );
    return List.generate(maps.length, (i) => ServiceRecord.fromMap(maps[i]));
  }
'''

# Insert before the final closing brace
content = content.rstrip()
if content.endswith('}'):
    content = content[:-1] + km_methods + '\n}'
else:
    content = content + km_methods

with open('lib/database/database_helper.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Added KM tracking methods to database_helper.dart")
print("   - addKmRecord() - Add KM record and update vehicle")
print("   - getVehicleKmRecords() - Get all KM records for vehicle")
print("   - addServiceRecord() - Add service and update next service KM")
print("   - getVehicleServiceRecords() - Get service history")
print("   - getVehiclesDueForService() - Get vehicles needing service")
print("   - getVehiclesApproachingService() - Get vehicles approaching service")
print("   - And more...")
