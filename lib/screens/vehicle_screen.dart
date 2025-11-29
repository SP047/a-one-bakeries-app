import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_vehicle_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_km_record_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_service_record_dialog.dart';
import 'package:a_one_bakeries_app/screens/vehicle_disk_dashboard_screen.dart';

/// Vehicle Screen
/// 
/// Main screen for vehicle management.
/// Displays all vehicles with their assignment status.
/// Allows adding, editing, deleting, and assigning vehicles to drivers.

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = true;
  String _filterStatus = 'ALL'; // ALL, ASSIGNED, UNASSIGNED, EXPIRED, CRITICAL, WARNING, NO_DATA
  
  // Disk status counts
  int _expiredCount = 0;
  int _criticalCount = 0;
  int _warningCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  /// Load all vehicles from database
  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await _dbHelper.getAllVehicles();
      
      // Calculate disk status counts
      int expired = 0;
      int critical = 0;
      int warning = 0;
      
      for (var vehicle in vehicles) {
        switch (vehicle.diskStatus) {
          case DiskStatus.expired:
            expired++;
            break;
          case DiskStatus.critical:
            critical++;
            break;
          case DiskStatus.warning:
            warning++;
            break;
          default:
            break;
        }
      }
      
      setState(() {
        _vehicles = vehicles;
        _expiredCount = expired;
        _criticalCount = critical;
        _warningCount = warning;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading vehicles: $e');
      }
    }
  }

  /// Apply filters
  void _applyFilters() {
    List<Vehicle> filtered = _vehicles;

    // Apply assignment filters
    if (_filterStatus == 'ASSIGNED') {
      filtered = filtered.where((v) => v.isAssigned).toList();
    } else if (_filterStatus == 'UNASSIGNED') {
      filtered = filtered.where((v) => !v.isAssigned).toList();
    }
    // Apply disk status filters
    else if (_filterStatus == 'EXPIRED') {
      filtered = filtered.where((v) => v.diskStatus == DiskStatus.expired).toList();
    } else if (_filterStatus == 'CRITICAL') {
      filtered = filtered.where((v) => v.diskStatus == DiskStatus.critical).toList();
    } else if (_filterStatus == 'WARNING') {
      filtered = filtered.where((v) => v.diskStatus == DiskStatus.warning).toList();
    } else if (_filterStatus == 'NO_DATA') {
      filtered = filtered.where((v) => v.diskStatus == DiskStatus.noData).toList();
    }

    setState(() {
      _filteredVehicles = filtered;
    });
  }

  /// Show add vehicle dialog
  Future<void> _showAddVehicleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditVehicleDialog(),
    );

    if (result == true) {
      _loadVehicles();
      if (mounted) {
        _showSuccessSnackBar('Vehicle registered successfully!');
      }
    }
  }

  /// Show edit vehicle dialog
  Future<void> _showEditVehicleDialog(Vehicle vehicle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditVehicleDialog(vehicle: vehicle),
    );

    if (result == true) {
      _loadVehicles();
      if (mounted) {
        _showSuccessSnackBar('Vehicle updated successfully!');
      }
    }
  }

  /// Delete vehicle
  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
            'Are you sure you want to delete ${vehicle.fullName} (${vehicle.registrationNumber})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteVehicle(vehicle.id!);
        _loadVehicles();
        if (mounted) {
          _showSuccessSnackBar('Vehicle deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting vehicle: $e');
        }
      }
    }
  }

  /// Show assign driver dialog
  Future<void> _showAssignDriverDialog(Vehicle vehicle) async {
    // Get all drivers (employees with role = Driver)
    final drivers = await _dbHelper.getEmployeesByRole(EmployeeRoles.driver);

    if (drivers.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Drivers Available'),
            content: const Text(
                'Please register employees with the "Driver" role first.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    Employee? selectedDriver;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Driver'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select driver for ${vehicle.fullName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Employee>(
                  initialValue: selectedDriver,
                  decoration: const InputDecoration(
                    labelText: 'Driver',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: drivers
                      .map((driver) => DropdownMenuItem(
                            value: driver,
                            child: Text(driver.fullName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDriver = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (result == true && selectedDriver != null) {
      try {
        await _dbHelper.assignVehicleToDriver(
          vehicle.id!,
          selectedDriver!.id!,
          selectedDriver!.fullName,
        );
        _loadVehicles();
        if (mounted) {
          _showSuccessSnackBar(
              'Vehicle assigned to ${selectedDriver!.fullName}');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error assigning vehicle: $e');
        }
      }
    }
  }

  /// Unassign vehicle
  Future<void> _unassignVehicle(Vehicle vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Vehicle'),
        content: Text(
            'Remove ${vehicle.assignedDriverName} from ${vehicle.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.unassignVehicle(vehicle.id!);
        _loadVehicles();
        if (mounted) {
          _showSuccessSnackBar('Vehicle unassigned successfully!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error unassigning vehicle: $e');
        }
      }
    }
  }


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          // License Disk Dashboard Button
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: 'License Disk Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleDiskDashboardScreen(),
                ),
              ).then((_) => _loadVehicles());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Alert Banner for Expired/Critical Vehicles
          if (_expiredCount > 0 || _criticalCount > 0)
            _buildAlertBanner(),
          
          // Filter Chips
          _buildFilterChips(),

          // Vehicle Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredVehicles.length} ${_filteredVehicles.length == 1 ? 'Vehicle' : 'Vehicles'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Vehicles List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadVehicles,
                        color: AppTheme.primaryBrown,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredVehicles.length,
                          itemBuilder: (context, index) {
                            return _buildVehicleCard(_filteredVehicles[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build alert banner for expired/critical vehicles
  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _expiredCount > 0 ? AppTheme.errorRed : AppTheme.secondaryOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _expiredCount > 0 ? Icons.error : Icons.warning,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _expiredCount > 0 
                      ? 'License Disk Alert!'
                      : 'Renewal Reminder',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _expiredCount > 0
                      ? '$_expiredCount vehicle${_expiredCount > 1 ? 's have' : ' has'} expired disk${_expiredCount > 1 ? 's' : ''}'
                      : '$_criticalCount vehicle${_criticalCount > 1 ? 's' : ''} expiring within 30 days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () {
              setState(() {
                _filterStatus = _expiredCount > 0 ? 'EXPIRED' : 'CRITICAL';
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Filter: ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            _buildFilterChip('ALL', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('ASSIGNED', 'Assigned'),
            const SizedBox(width: 8),
            _buildFilterChip('UNASSIGNED', 'Unassigned'),
            const SizedBox(width: 8),
            _buildFilterChip('EXPIRED', 'Expired', color: AppTheme.errorRed, count: _expiredCount),
            const SizedBox(width: 8),
            _buildFilterChip('CRITICAL', 'Critical', color: AppTheme.secondaryOrange, count: _criticalCount),
            const SizedBox(width: 8),
            _buildFilterChip('WARNING', 'Warning', color: Colors.amber, count: _warningCount),
            const SizedBox(width: 8),
            _buildFilterChip('NO_DATA', 'No Data', color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// Build single filter chip
  Widget _buildFilterChip(String value, String label, {Color? color, int? count}) {
    final isSelected = _filterStatus == value;
    final chipColor = color ?? AppTheme.primaryBrown;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : chipColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? chipColor : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFilters();
        });
      },
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.darkBrown,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  /// Build vehicle card
  Widget _buildVehicleCard(Vehicle vehicle) {
    final diskStatus = vehicle.diskStatus;
    final daysUntil = vehicle.daysUntilDiskExpiry;
    final hasDiskData = vehicle.licenseDiskExpiry != null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Vehicle Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: AppTheme.secondaryOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Vehicle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          // Disk Status Badge
                          if (hasDiskData)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: diskStatus.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    diskStatus.icon,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    daysUntil < 0
                                        ? '${daysUntil.abs()}d ago'
                                        : daysUntil == 0
                                            ? 'Today'
                                            : '${daysUntil}d',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.registrationNumber,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.secondaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      // Disk Expiry Date
                      if (hasDiskData) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 14,
                              color: diskStatus.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expires: ${vehicle.licenseDiskExpiry!.day}/${vehicle.licenseDiskExpiry!.month}/${vehicle.licenseDiskExpiry!.year}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: diskStatus.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      // KM and Service Status
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 14,
                            color: AppTheme.darkBrown.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'KM: ${vehicle.currentKm}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            vehicle.serviceStatus.icon,
                            size: 14,
                            color: vehicle.serviceStatus.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.isServiceDue 
                                ? 'Service Due!'
                                : '${vehicle.kmUntilService} km to service',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: vehicle.serviceStatus.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditVehicleDialog(vehicle);
                    } else if (value == 'record_km') {
                      _showKmRecordDialog(vehicle);
                    } else if (value == 'record_service') {
                      _showServiceRecordDialog(vehicle);
                    } else if (value == 'delete') {
                      _deleteVehicle(vehicle);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: 20, color: AppTheme.errorRed),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppTheme.errorRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Assigned Driver Info
            if (vehicle.isAssigned) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppTheme.successGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Driver: ${vehicle.assignedDriverName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // Action Buttons
            Row(
              children: [
                if (!vehicle.isAssigned)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignDriverDialog(vehicle),
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text('Assign Driver'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _unassignVehicle(vehicle),
                      icon: const Icon(Icons.person_remove, size: 20),
                      label: const Text('Unassign'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'ALL'
                ? 'No vehicles yet'
                : 'No ${_filterStatus.toLowerCase()} vehicles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'ALL'
                ? 'Tap + to register your first vehicle'
                : 'Try a different filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
