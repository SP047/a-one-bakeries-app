# Script to update database_helper.dart to version 6 for KM tracking

with open('lib/database/database_helper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update version from 5 to 6
content = content.replace(
    'version: 5,  // ← UPDATED: Changed from 3 to 5',
    'version: 6,  // ← UPDATED: Changed from 5 to 6 for KM tracking'
)

# 2. Add KM fields to CREATE TABLE vehicles
old_create_vehicles = '''    await db.execute(\'\'\'
      CREATE TABLE vehicles(
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
      )
    \'\'\');'''

new_create_vehicles = '''    await db.execute(\'\'\'
      CREATE TABLE vehicles(
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
      )
    \'\'\');'''

content = content.replace(old_create_vehicles, new_create_vehicles)

# 3. Add version 6 upgrade logic
old_upgrade_end = '''      await db.execute('ALTER TABLE vehicles ADD COLUMN licenseDiskExpiry TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN lastRenewalDate TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN diskNumber TEXT');
      
      print('✅ Database upgraded to v5: Vehicle license disk fields added');
    }
  }'''

new_upgrade_end = '''      await db.execute('ALTER TABLE vehicles ADD COLUMN licenseDiskExpiry TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN lastRenewalDate TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN diskNumber TEXT');
      
      print('✅ Database upgraded to v5: Vehicle license disk fields added');
    }

    // Upgrade to version 6: Add KM tracking
    if (oldVersion < 6) {
      // Add KM tracking fields to vehicles table
      await db.execute('ALTER TABLE vehicles ADD COLUMN currentKm INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE vehicles ADD COLUMN lastServiceKm INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE vehicles ADD COLUMN serviceIntervalKm INTEGER DEFAULT 10000');
      await db.execute('ALTER TABLE vehicles ADD COLUMN nextServiceKm INTEGER DEFAULT 10000');
      
      // Create km_records table
      await db.execute(\'\'\'
        CREATE TABLE km_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicleId INTEGER NOT NULL,
          kmReading INTEGER NOT NULL,
          recordedDate TEXT NOT NULL,
          notes TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
        )
      \'\'\');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_km_records_vehicleId ON km_records(vehicleId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_km_records_date ON km_records(recordedDate)');
      
      // Create service_records table
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
          FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
        )
      \'\'\');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_service_records_vehicleId ON service_records(vehicleId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_service_records_date ON service_records(serviceDate)');
      
      print('✅ Database upgraded to v6: KM tracking and service records added');
    }
  }'''

content = content.replace(old_upgrade_end, new_upgrade_end)

with open('lib/database/database_helper.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Database helper updated to version 6")
print("   - Added currentKm, lastServiceKm, serviceIntervalKm, nextServiceKm to vehicles table")
print("   - Added km_records table")
print("   - Added service_records table")
