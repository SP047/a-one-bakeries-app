import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/services/report_export_service.dart';
import 'package:intl/intl.dart';

/// Stock Movement Report Screen
/// 
/// Track all stock additions and usage with date range filters

enum DateRangeType { daily, weekly, monthly, yearly, custom }

class StockMovementReportScreen extends StatefulWidget {
  const StockMovementReportScreen({super.key});

  @override
  State<StockMovementReportScreen> createState() => _StockMovementReportScreenState();
}

class _StockMovementReportScreenState extends State<StockMovementReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReportExportService _exportService = ReportExportService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  DateRangeType _selectedRange = DateRangeType.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  List<StockItem> _stockItems = [];
  bool _isLoading = false;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dateRange = _getDateRange();
      final allStock = await _dbHelper.getAllStockItems();
      
      // Filter stock items within date range
      final filteredStock = allStock
          .where((item) => 
              item.createdAt.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
              item.createdAt.isBefore(dateRange.end.add(const Duration(days: 1))))
          .toList();

      // Sort by date descending
      filteredStock.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _stockItems = filteredStock;
        _totalItems = filteredStock.length;
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

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    
    switch (_selectedRange) {
      case DateRangeType.daily:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      
      case DateRangeType.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      
      case DateRangeType.monthly:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      
      case DateRangeType.yearly:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      
      case DateRangeType.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return DateTimeRange(
            start: _customStartDate!,
            end: _customEndDate!,
          );
        }
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
    }
  }

  String _getRangeLabel() {
    final range = _getDateRange();
    return '${_dateFormat.format(range.start)} - ${_dateFormat.format(range.end)}';
  }

  Future<void> _exportToExcel() async {
    try {
      final headers = ['Date', 'Item Name', 'Quantity', 'Unit'];
      final rows = _stockItems.map((item) => [
        item.createdAt,
        item.name,
        item.quantityOnHand,
        item.unit,
      ]).toList();

      final filePath = await _exportService.exportToExcel(
        reportTitle: 'Stock Movement Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Items', 'Date Range'],
        summaryValues: [
          _totalItems,
          _getRangeLabel(),
        ],
      );

      if (mounted) {
        _showSuccessSnackBar('Excel file saved to: $filePath');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excel File Created'),
            content: Text('File saved to:\n$filePath\n\nYou can find it in your Documents folder.'),
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
      final headers = ['Date', 'Item Name', 'Quantity', 'Unit'];
      final rows = _stockItems.map((item) => [
        item.createdAt,
        item.name,
        item.quantityOnHand.toString(),
        item.unit,
      ]).toList();

      await _exportService.exportToPdf(
        reportTitle: 'Stock Movement Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Items', 'Date Range'],
        summaryValues: [
          _totalItems.toString(),
          _getRangeLabel(),
        ],
      );

      if (mounted) {
        _showSuccessSnackBar('PDF generated successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error exporting to PDF: $e');
      }
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedRange = DateRangeType.custom;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Stock Movement Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
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
          // Date Range Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRangeChip('Today', DateRangeType.daily),
                    _buildRangeChip('This Week', DateRangeType.weekly),
                    _buildRangeChip('This Month', DateRangeType.monthly),
                    _buildRangeChip('This Year', DateRangeType.yearly),
                    _buildRangeChip('Custom', DateRangeType.custom, onTap: _selectCustomDateRange),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getRangeLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBrown, AppTheme.primaryBrown.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.white, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Stock Items',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_totalItems items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Added/Updated in period',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stock List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _stockItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stockItems.length,
                        itemBuilder: (context, index) {
                          final item = _stockItems[index];
                          return _buildStockCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, DateRangeType type, {VoidCallback? onTap}) {
    final isSelected = _selectedRange == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (onTap != null) {
          onTap();
        } else {
          setState(() {
            _selectedRange = type;
          });
          _loadReport();
        }
      },
      selectedColor: AppTheme.primaryBrown,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.darkBrown,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildStockCard(StockItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory, color: AppTheme.primaryBrown),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateFormat.format(item.createdAt)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.quantityOnHand}',
              style: const TextStyle(
                color: AppTheme.primaryBrown,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              item.unit,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkBrown.withOpacity(0.6),
              ),
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
            Icons.inventory_2,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No stock movements found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date range',
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
        duration: const Duration(seconds: 3),
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
