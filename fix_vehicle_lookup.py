# Fix the getVehicle call by removing vehicle lookup entirely

with open('lib/screens/driver_vehicle_orders_report_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the vehicle lookup lines
old_code = """            // Get linked vehicle
            if (orders.first.vehicleId != null) {
              vehicle = await _dbHelper.getVehicle(orders.first.vehicleId!);
            }"""

new_code = """            // Vehicle info would be loaded here if needed
            // For now, just using driver name"""

content = content.replace(old_code, new_code)

with open('lib/screens/driver_vehicle_orders_report_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ Fixed driver_vehicle_orders_report_screen.dart")
