# Script to add KM tracking to vehicle screen

with open('lib/screens/vehicle_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports after add_edit_vehicle_dialog
imports_to_add = """import 'package:a_one_bakeries_app/widgets/add_km_record_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_service_record_dialog.dart';"""

content = content.replace(
    "import 'package:a_one_bakeries_app/widgets/add_edit_vehicle_dialog.dart';",
    "import 'package:a_one_bakeries_app/widgets/add_edit_vehicle_dialog.dart';\n" + imports_to_add
)

# 2. Add PopupMenuButton to AppBar actions (after the License Disk Dashboard button)
# Find the AppBar actions section and add a menu
old_appbar_actions = """        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleDiskDashboardScreen(),
                ),
              );
            },
            tooltip: 'License Disk Dashboard',
          ),
        ],"""

new_appbar_actions = """        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleDiskDashboardScreen(),
                ),
              );
            },
            tooltip: 'License Disk Dashboard',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'KM Tracking',
            onSelected: (value) {
              if (value == 'record_km' && _filteredVehicles.isNotEmpty) {
                _showKmRecordDialog(_filteredVehicles.first);
              } else if (value == 'record_service' && _filteredVehicles.isNotEmpty) {
                _showServiceRecordDialog(_filteredVehicles.first);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'record_km',
                child: Row(
                  children: [
                    Icon(Icons.speed, size: 20),
                    SizedBox(width: 8),
                    Text('Record KM'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'record_service',
                child: Row(
                  children: [
                    Icon(Icons.build, size: 20),
                    SizedBox(width: 8),
                    Text('Record Service'),
                  ],
                ),
              ),
            ],
          ),
        ],"""

content = content.replace(old_appbar_actions, new_appbar_actions)

# 3. Add dialog methods before the build method (find the _deleteVehicle method and add after it)
dialog_methods = '''
  /// Show KM record dialog
  Future<void> _showKmRecordDialog(Vehicle vehicle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddKmRecordDialog(vehicle: vehicle),
    );
    
    if (result == true) {
      _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KM record saved successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  /// Show service record dialog
  Future<void> _showServiceRecordDialog(Vehicle vehicle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddServiceRecordDialog(vehicle: vehicle),
    );
    
    if (result == true) {
      _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service record saved successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }
'''

# Find where to insert (after _deleteVehicle method, before @override Widget build)
content = content.replace(
    '  @override\n  Widget build(BuildContext context) {',
    dialog_methods + '\n  @override\n  Widget build(BuildContext context) {'
)

with open('lib/screens/vehicle_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Vehicle screen updated!")
print("   - Added KM/Service dialog imports")
print("   - Added PopupMenu to AppBar for KM tracking")
print("   - Added dialog methods")
print("\nNext: Update vehicle cards to show KM/service status")
