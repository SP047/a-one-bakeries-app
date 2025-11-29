# Python script to add report buttons to Supplier and Orders screens

# Supplier Screen
with open('lib/screens/supplier_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'supplier_report_screen.dart' not in content:
    content = content.replace(
        "import 'package:a_one_bakeries_app/screens/supplier_details_screen.dart';",
        "import 'package:a_one_bakeries_app/screens/supplier_details_screen.dart';\nimport 'package:a_one_bakeries_app/screens/supplier_report_screen.dart';"
    )

# Add button to AppBar
old_appbar = """      appBar: AppBar(
        title: const Text('Suppliers'),
      ),"""

new_appbar = """      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierReportScreen()),
              );
            },
            tooltip: 'Supplier Report',
          ),
        ],
      ),"""

content = content.replace(old_appbar, new_appbar)

with open('lib/screens/supplier_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ Updated supplier_screen.dart")

# Orders Screen
with open('lib/screens/orders_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'driver_vehicle_orders_report_screen.dart' not in content:
    content = content.replace(
        "import 'package:a_one_bakeries_app/screens/create_order_screen.dart';",
        "import 'package:a_one_bakeries_app/screens/create_order_screen.dart';\nimport 'package:a_one_bakeries_app/screens/driver_vehicle_orders_report_screen.dart';"
    )

# Add button to AppBar
old_appbar = """      appBar: AppBar(
        title: const Text('Orders'),
      ),"""

new_appbar = """      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DriverVehicleOrdersReportScreen()),
              );
            },
            tooltip: 'Driver/Vehicle Orders Report',
          ),
        ],
      ),"""

content = content.replace(old_appbar, new_appbar)

with open('lib/screens/orders_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ Updated orders_screen.dart")
print("\n✅ Both files updated successfully!")
