# Comprehensive database_helper.dart fix - replace entire CREATE TABLE vehicles section

with open('lib/database/database_helper.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find and replace the CREATE TABLE vehicles section
output_lines = []
in_vehicles_table = False
skip_until_semicolon = False

for i, line in enumerate(lines):
    if 'CREATE TABLE vehicles(' in line:
        in_vehicles_table = True
        skip_until_semicolon = True
        # Write the complete new table definition
        output_lines.append("    await db.execute('''\n")
        output_lines.append("      CREATE TABLE vehicles(\n")
        output_lines.append("        id INTEGER PRIMARY KEY AUTOINCREMENT,\n")
        output_lines.append("        make TEXT NOT NULL,\n")
        output_lines.append("        model TEXT NOT NULL,\n")
        output_lines.append("        year INTEGER NOT NULL,\n")
        output_lines.append("        registrationNumber TEXT NOT NULL UNIQUE,\n")
        output_lines.append("        assignedDriverId INTEGER,\n")
        output_lines.append("        assignedDriverName TEXT,\n")
        output_lines.append("        licenseDiskExpiry TEXT,\n")
        output_lines.append("        lastRenewalDate TEXT,\n")
        output_lines.append("        diskNumber TEXT,\n")
        output_lines.append("        currentKm INTEGER DEFAULT 0,\n")
        output_lines.append("        lastServiceKm INTEGER DEFAULT 0,\n")
        output_lines.append("        serviceIntervalKm INTEGER DEFAULT 10000,\n")
        output_lines.append("        nextServiceKm INTEGER DEFAULT 10000,\n")
        output_lines.append("        createdAt TEXT NOT NULL,\n")
        output_lines.append("        updatedAt TEXT NOT NULL,\n")
        output_lines.append("        FOREIGN KEY (assignedDriverId) REFERENCES employees(id) ON DELETE SET NULL\n")
        output_lines.append("      )\n")
        output_lines.append("    ''');\n")
        continue
    
    if skip_until_semicolon:
        if "''')" in line:
            skip_until_semicolon = False
            in_vehicles_table = False
        continue
    
    output_lines.append(line)

with open('lib/database/database_helper.dart', 'w', encoding='utf-8') as f:
    f.writelines(output_lines)

print("✅ CREATE TABLE vehicles updated with ALL fields!")
print("   - License disk fields: licenseDiskExpiry, lastRenewalDate, diskNumber")
print("   - KM tracking fields: currentKm, lastServiceKm, serviceIntervalKm, nextServiceKm")
