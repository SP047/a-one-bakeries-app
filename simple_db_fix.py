# FINAL SIMPLE FIX - Just add the missing columns to CREATE TABLE vehicles

import re

with open('lib/database/database_helper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Change version to 6
content = re.sub(r'version: \d+,', 'version: 6,', content)

# 2. Add fields to CREATE TABLE vehicles - find the line with "assignedDriverName TEXT," and add fields after it
content = re.sub(
    r'(assignedDriverName TEXT,)\s*\n(\s*createdAt TEXT NOT NULL,)',
    r'\1\n        licenseDiskExpiry TEXT,\n        lastRenewalDate TEXT,\n        diskNumber TEXT,\n        currentKm INTEGER DEFAULT 0,\n        lastServiceKm INTEGER DEFAULT 0,\n        serviceIntervalKm INTEGER DEFAULT 10000,\n        nextServiceKm INTEGER DEFAULT 10000,\n\2',
    content
)

# 3. Add km_records table before the INDEXES section
km_records_table = '''
    // ==========================================================================
    // TABLE 15: KM RECORDS
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

# Insert before INDEXES
content = content.replace(
    '    // ==========================================================================\n    // INDEXES',
    km_records_table + '    // ==========================================================================\n    // INDEXES'
)

with open('lib/database/database_helper.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Database schema fixed!")
print("   Version: 6")
print("   CREATE TABLE vehicles: Added all missing fields")
print("   Added km_records and service_records tables")
