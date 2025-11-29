# Final fix for database_helper.dart - add all missing fields

with open('lib/database/database_helper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update version to 6
content = content.replace(
    "version: 3,  // ← UPDATED: Changed from 2 to 3",
    "version: 6,  // ← UPDATED: Version 6 for KM tracking"
)

# 2. Fix CREATE TABLE vehicles - add KM fields after diskNumber
old_vehicles_table = '''      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        registrationNumber TEXT NOT NULL UNIQUE,
        assignedDriverId INTEGER,
        assignedDriverName TEXT,
        licenseDiskExpiry TEXT,
        lastRenewalDate TEXT,
        diskNumber TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (assignedDriverId) REFERENCES employees(id) ON DELETE SET NULL
      )'''

new_vehicles_table = '''      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        registrationNumber TEXT NOT NULL UNIQUE,
        assignedDriverId INTEGER,
        assignedDriverName TEXT,
        licenseDiskExpiry TEXT,
        lastRenewalDate TEXT,
        diskNumber TEXT,
        currentKm INTEGER DEFAULT 0,
        lastServiceKm INTEGER DEFAULT 0,
        serviceIntervalKm INTEGER DEFAULT 10000,
        nextServiceKm INTEGER DEFAULT 10000,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (assignedDriverId) REFERENCES employees(id) ON DELETE SET NULL
      )'''

content = content.replace(old_vehicles_table, new_vehicles_table)

# 3. Add km_records and service_records tables after driver_licenses table
# Find the driver_licenses table and add after it
km_tables = '''

    // ==========================================================================
    // TABLE 15: KM RECORDS
    // Stores historical KM readings for vehicles
    // ==========================================================================
    await db.execute(\'\'\'
      CREATE TABLE km_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        kmReading INTEGER NOT NULL,
        recordedDate TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    \'\'\');

    // ==========================================================================
    // TABLE 16: SERVICE RECORDS
    // Stores vehicle service history
    // ==========================================================================
    await db.execute(\'\'\'
      CREATE TABLE service_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        serviceKm INTEGER NOT NULL,
        serviceDate TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        cost REAL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    \'\'\');
'''

# Insert before the INDEXES section
content = content.replace(
    '    // ==========================================================================\n    // INDEXES - Speed up database queries',
    km_tables + '    // ==========================================================================\n    // INDEXES - Speed up database queries'
)

with open('lib/database/database_helper.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ database_helper.dart updated successfully!")
print("   - Version: 6")
print("   - CREATE TABLE vehicles: Added KM fields")
print("   - Added km_records table")
print("   - Added service_records table")
