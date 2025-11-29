# PowerShell script to add report buttons to Stock and Employee screens

# Stock Screen - Add import
$stockFile = "lib\screens\stock_screen.dart"
$content = Get-Content $stockFile -Raw
$content = $content -replace "import 'package:a_one_bakeries_app/screens/supplier_screen.dart';", "import 'package:a_one_bakeries_app/screens/supplier_screen.dart';`nimport 'package:a_one_bakeries_app/screens/stock_movement_report_screen.dart';"

# Stock Screen - Add button
$oldActions = @"
        actions: [
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
        ],
"@

$newActions = @"
        actions: [
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
        ],
"@

$content = $content -replace [regex]::Escape($oldActions), $newActions
Set-Content $stockFile -Value $content

Write-Host "✓ Updated stock_screen.dart"

# Employee Screen - Add import
$empFile = "lib\screens\employee_screen.dart"
$content = Get-Content $empFile -Raw
$content = $content -replace "import 'package:a_one_bakeries_app/widgets/employee_photo_widget.dart';", "import 'package:a_one_bakeries_app/widgets/employee_photo_widget.dart';`nimport 'package:a_one_bakeries_app/screens/employee_credits_report_screen.dart';"

# Employee Screen - Add button (find AppBar and add actions)
$content = $content -replace "appBar: AppBar\(`r?`n        title: const Text\('Employees'\),`r?`n      \),", @"
appBar: AppBar(
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
      ),
"@

Set-Content $empFile -Value $content

Write-Host "✓ Updated employee_screen.dart"
Write-Host "`n✅ Both files updated successfully!"
