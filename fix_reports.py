import re

# Fix stock_screen.dart
with open('lib/screens/stock_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'stock_movement_report_screen.dart' not in content:
    content = content.replace(
        "import 'package:a_one_bakeries_app/screens/supplier_screen.dart';",
        "import 'package:a_one_bakeries_app/screens/supplier_screen.dart';\nimport 'package:a_one_bakeries_app/screens/stock_movement_report_screen.dart';"
    )

# Add button to actions
old_actions = """        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: _navigateToSuppliers,
            tooltip: 'Suppliers',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToStockMovements,
            tooltip: 'Stock Movements',
          ),
        ],"""

new_actions = """        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StockMovementReportScreen()),
              );
            },
            tooltip: 'Stock Movement Report',
          ),
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: _navigateToSuppliers,
            tooltip: 'Suppliers',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToStockMovements,
            tooltip: 'Stock Movements',
          ),
        ],"""

content = content.replace(old_actions, new_actions)

with open('lib/screens/stock_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ Updated stock_screen.dart")

# Fix employee_screen.dart
with open('lib/screens/employee_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'employee_credits_report_screen.dart' not in content:
    content = content.replace(
        "import 'package:a_one_bakeries_app/widgets/employee_photo_widget.dart';",
        "import 'package:a_one_bakeries_app/widgets/employee_photo_widget.dart';\nimport 'package:a_one_bakeries_app/screens/employee_credits_report_screen.dart';"
    )

# Add actions to AppBar
old_appbar = """      appBar: AppBar(
        title: const Text('Employees'),
      ),"""

new_appbar = """      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmployeeCreditsReportScreen()),
              );
            },
            tooltip: 'Employee Credits Report',
          ),
        ],
      ),"""

content = content.replace(old_appbar, new_appbar)

with open('lib/screens/employee_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ Updated employee_screen.dart")
print("\n✅ Both files updated successfully!")
