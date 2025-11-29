import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/models/finance_model.dart';
import 'package:a_one_bakeries_app/services/report_export_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Income Report Screen
/// 
/// Generate and export income reports with date range filters

enum DateRangeType { daily, weekly, monthly, yearly, custom }

class IncomeReportScreen extends StatefulWidget {
  const IncomeReportScreen({super.key});

  @override
  State<IncomeReportScreen> createState() => _IncomeReportScreenState();
}

class _IncomeReportScreenState extends State<IncomeReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReportExportService _exportService = ReportExportService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  DateRangeType _selectedRange = DateRangeType.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  List<Income> _incomeRecords = [];
  bool _isLoading = false;
  double _totalIncome = 0.0;

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
      final allIncome = await _dbHelper.getAllIncome();
      
      // Filter income records within date range
      final incomeRecords = allIncome
          .where((r) => 
              r.createdAt.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
              r.createdAt.isBefore(dateRange.end.add(const Duration(days: 1))))
          .toList();

      // Sort by date descending
      incomeRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Calculate total
      final total = incomeRecords.fold<double>(
        0.0,
        (sum, record) => sum + record.total,
      );

      setState(() {
        _incomeRecords = incomeRecords;
        _totalIncome = total;
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
        // Fallback to monthly
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
      final headers = ['Date', 'Description', 'Notes', 'Coins', 'Total'];
      final rows = _incomeRecords.map((record) => [
        record.createdAt,
        record.description ?? 'Income',
        record.notes,
        record.coins,
        record.total,
      ]).toList();

      final filePath = await _exportService.exportToExcel(
        reportTitle: 'Income Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Income', 'Number of Entries', 'Date Range'],
        summaryValues: [
          _currencyFormat.format(_totalIncome),
          _incomeRecords.length,
          _getRangeLabel(),
        ],
      );

      if (mounted) {
        _showSuccessSnackBar('Excel file saved to: $filePath');
        // Show dialog with file location
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
      final headers = ['Date', 'Description', 'Notes', 'Coins', 'Total'];
      final rows = _incomeRecords.map((record) => [
        record.createdAt,
        record.description ?? 'Income',
        _currencyFormat.format(record.notes),
        _currencyFormat.format(record.coins),
        _currencyFormat.format(record.total),
      ]).toList();

      await _exportService.exportToPdf(
        reportTitle: 'Income Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Income', 'Number of Entries', 'Date Range'],
        summaryValues: [
          _currencyFormat.format(_totalIncome),
          _incomeRecords.length.toString(),
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
        title: const Text('Income Report'),
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
                colors: [AppTheme.successGreen, AppTheme.successGreen.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Income',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(_totalIncome),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_incomeRecords.length} entries',
                        style: const TextStyle(
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

          // Income List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _incomeRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _incomeRecords.length,
                        itemBuilder: (context, index) {
                          final record = _incomeRecords[index];
                          return _buildIncomeCard(record);
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
      selectedColor: AppTheme.successGreen,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.darkBrown,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildIncomeCard(Income record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.attach_money, color: AppTheme.successGreen),
        ),
        title: Text(
          record.description ?? 'Income',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateFormat.format(record.createdAt)),
            Text(
              'Notes: ${_currencyFormat.format(record.notes)} | Coins: ${_currencyFormat.format(record.coins)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: Text(
          _currencyFormat.format(record.total),
          style: const TextStyle(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
            Icons.receipt_long,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No income records found',
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
