import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_vehicle_dialog.dart';

/// Vehicle License Disk Dashboard Screen
/// 
/// Displays all vehicles organized by their license disk status:
/// - Expired (red)
/// - Critical - expiring within 30 days (orange)
/// - Warning - expiring within 60 days (yellow)
/// - Caution - expiring within 90 days (blue)
/// - Valid - more than 90 days (green)
/// - No Data - no expiry date set (grey)

class VehicleDiskDashboardScreen extends StatefulWidget {
  const VehicleDiskDashboardScreen({super.key});

  @override
  State<VehicleDiskDashboardScreen> createState() => _VehicleDiskDashboardScreenState();
}

class _VehicleDiskDashboardScreenState extends State<VehicleDiskDashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Vehicle> _expiredVehicles = [];
  List<Vehicle> _criticalVehicles = [];
  List<Vehicle> _warningVehicles = [];
  List<Vehicle> _cautionVehicles = [];
  List<Vehicle> _validVehicles = [];
  List<Vehicle> _noDataVehicles = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  /// Load and categorize all vehicles by disk status
  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allVehicles = await _dbHelper.getAllVehicles();
      
      // Categorize vehicles by disk status
      final expired = <Vehicle>[];
      final critical = <Vehicle>[];
      final warning = <Vehicle>[];
      final caution = <Vehicle>[];
      final valid = <Vehicle>[];
      final noData = <Vehicle>[];

      for (var vehicle in allVehicles) {
        switch (vehicle.diskStatus) {
          case DiskStatus.expired:
            expired.add(vehicle);
            break;
          case DiskStatus.critical:
            critical.add(vehicle);
            break;
          case DiskStatus.warning:
            warning.add(vehicle);
            break;
          case DiskStatus.critical:
            caution.add(vehicle);
            break;
          case DiskStatus.valid:
            valid.add(vehicle);
            break;
          case DiskStatus.noData:
            noData.add(vehicle);
            break;
        }
      }

      setState(() {
        _expiredVehicles = expired;
        _criticalVehicles = critical;
        _warningVehicles = warning;
        _cautionVehicles = caution;
        _validVehicles = valid;
        _noDataVehicles = noData;
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

  @override
  Widget build(BuildContext context) {
    final totalVehicles = _expiredVehicles.length +
        _criticalVehicles.length +
        _warningVehicles.length +
        _cautionVehicles.length +
        _validVehicles.length +
        _noDataVehicles.length;

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('License Disk Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalVehicles == 0
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  color: AppTheme.primaryBrown,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary Cards
                      _buildSummaryCards(),
                      const SizedBox(height: 24),

                      // Expired Vehicles
                      if (_expiredVehicles.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Expired',
                          _expiredVehicles.length,
                          DiskStatus.expired,
                        ),
                        ..._expiredVehicles.map((v) => _buildVehicleCard(v)),
                        const SizedBox(height: 16),
                      ],

                      // Critical Vehicles (1-30 days)
                      if (_criticalVehicles.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Critical (1-30 days)',
                          _criticalVehicles.length,
                          DiskStatus.critical,
                        ),
                        ..._criticalVehicles.map((v) => _buildVehicleCard(v)),
                        const SizedBox(height: 16),
                      ],

                      // Warning Vehicles (31-60 days)
                      if (_warningVehicles.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Warning (31-60 days)',
                          _warningVehicles.length,
                          DiskStatus.warning,
                        ),
                        ..._warningVehicles.map((v) => _buildVehicleCard(v)),
                        const SizedBox(height: 16),
                      ],

                      // Caution Vehicles (61-90 days)
                      if (_cautionVehicles.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Caution (61-90 days)',
                          _cautionVehicles.length,
                          DiskStatus.critical,
                        ),
                        ..._cautionVehicles.map((v) => _buildVehicleCard(v)),
                        const SizedBox(height: 16),
                      ],

                      // Valid Vehicles (>90 days)
                      if (_validVehicles.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Valid (>90 days)',
                          _validVehicles.length,
                          DiskStatus.valid,
                        ),
                        ..._validVehicles.map((v) => _buildVehicleCard(v)),
                        const SizedBox(height: 16),
                      ],

                      // No Data Vehicles
                      if (_noDataVehicles.isNotEmpty) ...[
                        _buildSectionHeader(
                          'No Expiry Data',
                          _noDataVehicles.length,
                          DiskStatus.noData,
                        ),
                        ..._noDataVehicles.map((v) => _buildVehicleCard(v)),
                      ],
                    ],
                  ),
                ),
    );
  }

  /// Build summary cards showing counts
  Widget _buildSummaryCards() {
    return Row(
      children: [
        if (_expiredVehicles.isNotEmpty)
          Expanded(
            child: _buildSummaryCard(
              'Expired',
              _expiredVehicles.length,
              DiskStatus.expired.color,
              Icons.error,
            ),
          ),
        if (_expiredVehicles.isNotEmpty && _criticalVehicles.isNotEmpty)
          const SizedBox(width: 8),
        if (_criticalVehicles.isNotEmpty)
          Expanded(
            child: _buildSummaryCard(
              'Critical',
              _criticalVehicles.length,
              DiskStatus.critical.color,
              Icons.warning,
            ),
          ),
      ],
    );
  }

  /// Build a single summary card
  Widget _buildSummaryCard(String label, int count, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, int count, DiskStatus status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build vehicle card
  Widget _buildVehicleCard(Vehicle vehicle) {
    final daysUntil = vehicle.daysUntilDiskExpiry;
    final status = vehicle.diskStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showEditVehicleDialog(vehicle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vehicle Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: status.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Vehicle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.registrationNumber,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (vehicle.licenseDiskExpiry != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Expires: ${vehicle.licenseDiskExpiry!.day}/${vehicle.licenseDiskExpiry!.month}/${vehicle.licenseDiskExpiry!.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkBrown.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Days Until Expiry Badge
              if (vehicle.licenseDiskExpiry != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysUntil < 0
                        ? '${daysUntil.abs()}d ago'
                        : daysUntil == 0
                            ? 'Today'
                            : '${daysUntil}d',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
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
            Icons.credit_card_off,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No vehicles registered',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add vehicles to track their license disks',
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
