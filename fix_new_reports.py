# Fix the new report screens

import re

# Fix Supplier Report
with open('lib/screens/supplier_report_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix title parameter
content = content.replace('title: \'Supplier Report\',', 'reportTitle: \'Supplier Report\',')

# Fix summaryData to use summaryTitle, summaryLabels, summaryValues
content = re.sub(
    r'summaryData: \{([^}]+)\}',
    lambda m: 'summaryTitle: \'Summary\',\n        summaryLabels: [' + 
              ', '.join([f"'{k.strip()}'" for k in re.findall(r"'([^']+)':", m.group(1))]) +
              '],\n        summaryValues: [' +
              ', '.join([v.strip().rstrip(',') for v in re.findall(r':\s*([^,\n]+)', m.group(1))]) +
              ']',
    content
)

with open('lib/screens/supplier_report_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ Fixed supplier_report_screen.dart")

# Fix Driver/Vehicle Orders Report
with open('lib/screens/driver_vehicle_orders_report_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix title parameter
content = content.replace('title: \'Driver/Vehicle Orders Report\',', 'reportTitle: \'Driver/Vehicle Orders Report\',')

# Fix getVehicleById to getVehicle
content = content.replace('_dbHelper.getVehicleById', '_dbHelper.getVehicle')

# Fix summaryData to use summaryTitle, summaryLabels, summaryValues
content = re.sub(
    r'summaryData: \{([^}]+)\}',
    lambda m: 'summaryTitle: \'Summary\',\n        summaryLabels: [' + 
              ', '.join([f"'{k.strip()}'" for k in re.findall(r"'([^']+)':", m.group(1))]) +
              '],\n        summaryValues: [' +
              ', '.join([v.strip().rstrip(',') for v in re.findall(r':\s*([^,\n]+)', m.group(1))]) +
              ']',
    content
)

with open('lib/screens/driver_vehicle_orders_report_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ Fixed driver_vehicle_orders_report_screen.dart")
print("\n✅ All fixes applied!")
