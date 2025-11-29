import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/order_model.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/services/report_export_service.dart';
import 'package:intl/intl.dart';

/// Driver/Vehicle Orders Report Screen
/// 
/// Displays daily orders grouped by driver with vehicle information.
/// Shows order counts and bread quantities (brown/white) per driver.

class DriverVehicleOrdersReportScreen extends StatefulWidget {
  const DriverVehicleOrdersReportScreen({super.key});

  @override
  State<DriverVehicleOrdersReportScreen> createState() => _DriverVehicleOrdersReportScreenState();
}

class _DriverVehicleOrdersReportScreenState extends State<DriverVehicleOrdersReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReportExportService _exportService = ReportExportService();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  List<_DriverOrderSummary> _driverSummaries = [];
  bool _isLoading = false;
  
  String _selectedFilter = 'Daily';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  int _totalOrders = 0;
  int _totalBrownBread = 0;
  int _totalWhiteBread = 0;

  @override
  void initState() {
    super.initState();
    _setDateRange('Daily');
    _loadReport();
  }

  void _setDateRange(String filter) {
    final now = DateTime.now();
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Daily':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Weekly':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Monthly':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Yearly':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
      }
    });
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all orders
      final allOrders = await _dbHelper.getAllOrders();
      
      // Filter by date range
      final filteredOrders = allOrders.where((order) {
        return order.createdAt.isAfter(_startDate) && 
               order.createdAt.isBefore(_endDate);
      }).toList();

      // Group by driver
      final Map<int?, List<Order>> ordersByDriver = {};
      for (final order in filteredOrders) {
        if (!ordersByDriver.containsKey(order.driverId)) {
          ordersByDriver[order.driverId] = [];
        }
        ordersByDriver[order.driverId]!.add(order);
      }

      // Create summaries
      final List<_DriverOrderSummary> summaries = [];
      int totalOrders = 0;
      int totalBrown = 0;
      int totalWhite = 0;

      for (final entry in ordersByDriver.entries) {
        final driverId = entry.key;
        final orders = entry.value;

        String driverName = 'Unassigned';
        String? vehicleInfo;

        if (driverId != null) {
          // Get driver info
          final driver = await _dbHelper.getEmployeeById(driverId);
          if (driver != null) {
            driverName = driver.fullName;
          }
        }

        // Get vehicle info from first order (they should all have same vehicle)
        if (orders.isNotEmpty && orders.first.vehicleInfo != null) {
          vehicleInfo = orders.first.vehicleInfo;
        }

        final orderCount = orders.length;
        
        // Calculate bread quantities from order items
        int brownBread = 0;
        int whiteBread = 0;
        
        for (final order in orders) {
          final items = await _dbHelper.getOrderItems(order.id!);
          for (final item in items) {
            if (item.itemType == 'Brown Bread') {
              brownBread += item.quantity;
            } else if (item.itemType == 'White Bread') {
              whiteBread += item.quantity;
            }
          }
        }

        summaries.add(_DriverOrderSummary(
          driverName: driverName,
          vehicleInfo: vehicleInfo,
          orderCount: orderCount,
          brownBreadQty: brownBread,
          whiteBreadQty: whiteBread,
        ));

        totalOrders += orderCount;
        totalBrown += brownBread;
        totalWhite += whiteBread;
      }

      // Sort by total bread quantity descending
      summaries.sort((a, b) => (b.brownBreadQty + b.whiteBreadQty).compareTo(a.brownBreadQty + a.whiteBreadQty));

      setState(() {
        _driverSummaries = summaries;
        _totalOrders = totalOrders;
        _totalBrownBread = totalBrown;
        _totalWhiteBread = totalWhite;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading report: $e');
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final headers = ['Driver Name', 'Vehicle', 'Orders', 'Brown Bread', 'White Bread', 'Total'];
      final rows = _driverSummaries.map((summary) => [
        summary.driverName,
        summary.vehicleInfo ?? 'No Vehicle',
        summary.orderCount,
        summary.brownBreadQty,
        summary.whiteBreadQty,
        summary.brownBreadQty + summary.whiteBreadQty,
      ]).toList();

      final filePath = await _exportService.exportToExcel(
        reportTitle: 'Driver Vehicle Orders Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Drivers', 'Total Orders', 'Total Brown Bread', 'Total White Bread', 'Date Range'],
        summaryValues: [
          _driverSummaries.length,
          _totalOrders,
          _totalBrownBread,
          _totalWhiteBread,
          '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
        ],
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excel File Created'),
            content: Text(
              'File saved to:\n$filePath\n\nYou can find it in your Documents folder.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error exporting to Excel: $e');
      }
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final headers = ['Driver Name', 'Vehicle', 'Orders', 'Brown Bread', 'White Bread', 'Total'];
      final rows = _driverSummaries.map((summary) => [
        summary.driverName,
        summary.vehicleInfo ?? 'No Vehicle',
        summary.orderCount.toString(),
        summary.brownBreadQty.toString(),
        summary.whiteBreadQty.toString(),
        (summary.brownBreadQty + summary.whiteBreadQty).toString(),
      ]).toList();

      await _exportService.exportToPdf(
        reportTitle: 'Driver/Vehicle Orders Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Drivers', 'Total Orders', 'Total Brown Bread', 'Total White Bread', 'Date Range'],
        summaryValues: [
          _driverSummaries.length.toString(),
          _totalOrders.toString(),
          _totalBrownBread.toString(),
          _totalWhiteBread.toString(),
          '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
        ],
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error exporting to PDF: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Driver/Vehicle Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter Chips
          _buildFilterChips(),
          
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Drivers',
                        _driverSummaries.length.toString(),
                        Icons.person,
                        AppTheme.primaryBrown,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Orders',
                        _totalOrders.toString(),
                        Icons.receipt_long,
                        AppTheme.secondaryOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Brown Bread',
                        _totalBrownBread.toString(),
                        Icons.bakery_dining,
                        Colors.brown,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'White Bread',
                        _totalWhiteBread.toString(),
                        Icons.bakery_dining,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Driver/Vehicle List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _driverSummaries.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadReport,
                        color: AppTheme.primaryBrown,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _driverSummaries.length,
                          itemBuilder: (context, index) {
                            return _buildDriverCard(_driverSummaries[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Daily'),
          _buildFilterChip('Weekly'),
          _buildFilterChip('Monthly'),
          _buildFilterChip('Yearly'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _setDateRange(label);
          }
        },
        selectedColor: AppTheme.primaryBrown,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.darkBrown,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(_DriverOrderSummary summary) {
    final totalBread = summary.brownBreadQty + summary.whiteBreadQty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Name
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primaryBrown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.driverName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vehicle Info
            if (summary.vehicleInfo != null) ...[
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 20, color: AppTheme.secondaryOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.vehicleInfo!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'No vehicle assigned',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Order Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Orders',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.orderCount.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.secondaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),
                Column(
                  children: [
                    Text(
                      'Brown Bread',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.brownBreadQty.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.brown,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),
                Column(
                  children: [
                    Text(
                      'White Bread',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.whiteBreadQty.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            'No orders found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'for selected date range',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

// Helper class to store driver order summary
class _DriverOrderSummary {
  final String driverName;
  final String? vehicleInfo;
  final int orderCount;
  final int brownBreadQty;
  final int whiteBreadQty;

  _DriverOrderSummary({
    required this.driverName,
    this.vehicleInfo,
    required this.orderCount,
    required this.brownBreadQty,
    required this.whiteBreadQty,
  });
}
