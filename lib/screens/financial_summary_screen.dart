import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/models/finance_model.dart';
import 'package:a_one_bakeries_app/services/report_export_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Financial Summary Report Screen
/// 
/// Combined income and expense analysis with profit/loss calculation

enum DateRangeType { daily, weekly, monthly, yearly, custom }

class FinancialSummaryScreen extends StatefulWidget {
  const FinancialSummaryScreen({super.key});

  @override
  State<FinancialSummaryScreen> createState() => _FinancialSummaryScreenState();
}

class _FinancialSummaryScreenState extends State<FinancialSummaryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReportExportService _exportService = ReportExportService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  DateRangeType _selectedRange = DateRangeType.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _netProfit = 0.0;
  int _incomeCount = 0;
  int _expenseCount = 0;
  
  List<Map<String, dynamic>> _allRecords = [];
  bool _isLoading = false;

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
      final allExpenses = await _dbHelper.getAllExpenses();
      
      // Combine and convert to common format
      List<Map<String, dynamic>> combined = [];
      
      // Add income records
      for (var income in allIncome) {
        if (income.createdAt.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            income.createdAt.isBefore(dateRange.end.add(const Duration(days: 1)))) {
          combined.add({
            'date': income.createdAt,
            'type': 'income',
            'description': income.description ?? 'Income',
            'amount': income.total,
          });
        }
      }
      
      // Add expense records
      for (var expense in allExpenses) {
        if (expense.createdAt.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            expense.createdAt.isBefore(dateRange.end.add(const Duration(days: 1)))) {
          combined.add({
            'date': expense.createdAt,
            'type': 'expense',
            'description': expense.description,
            'amount': expense.amount,
          });
        }
      }

      // Sort by date descending
      combined.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Calculate totals
      double income = 0.0;
      double expenses = 0.0;
      int incCount = 0;
      int expCount = 0;

      for (var record in combined) {
        if (record['type'] == 'income') {
          income += record['amount'] as double;
          incCount++;
        } else {
          expenses += record['amount'] as double;
          expCount++;
        }
      }

      setState(() {
        _allRecords = combined;
        _totalIncome = income;
        _totalExpenses = expenses;
        _netProfit = income - expenses;
        _incomeCount = incCount;
        _expenseCount = expCount;
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
      final headers = ['Date', 'Type', 'Description', 'Amount'];
      final rows = _allRecords.map((record) => [
        record['date'],
        record['type'] == 'income' ? 'Income' : 'Expense',
        record['description'],
        record['amount'],
      ]).toList();

      final filePath = await _exportService.exportToExcel(
        reportTitle: 'Financial Summary',
        headers: headers,
        rows: rows,
        summaryTitle: 'Financial Summary',
        summaryLabels: [
          'Total Income',
          'Total Expenses',
          'Net Profit/Loss',
          'Income Entries',
          'Expense Entries',
          'Date Range',
        ],
        summaryValues: [
          _currencyFormat.format(_totalIncome),
          _currencyFormat.format(_totalExpenses),
          _currencyFormat.format(_netProfit),
          _incomeCount,
          _expenseCount,
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
      final headers = ['Date', 'Type', 'Description', 'Amount'];
      final rows = _allRecords.map((record) => [
        record['date'],
        record['type'] == 'income' ? 'Income' : 'Expense',
        record['description'],
        _currencyFormat.format(record['amount']),
      ]).toList();

      await _exportService.exportToPdf(
        reportTitle: 'Financial Summary',
        headers: headers,
        rows: rows,
        summaryTitle: 'Financial Summary',
        summaryLabels: [
          'Total Income',
          'Total Expenses',
          'Net Profit/Loss',
          'Income Entries',
          'Expense Entries',
          'Date Range',
        ],
        summaryValues: [
          _currencyFormat.format(_totalIncome),
          _currencyFormat.format(_totalExpenses),
          _currencyFormat.format(_netProfit),
          _incomeCount.toString(),
          _expenseCount.toString(),
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
    final isProfitable = _netProfit >= 0;
    
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Financial Summary'),
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

          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Income Card
                _buildSummaryCard(
                  'Total Income',
                  _currencyFormat.format(_totalIncome),
                  '$_incomeCount entries',
                  AppTheme.successGreen,
                  Icons.trending_up,
                ),
                const SizedBox(height: 12),
                
                // Expense Card
                _buildSummaryCard(
                  'Total Expenses',
                  _currencyFormat.format(_totalExpenses),
                  '$_expenseCount entries',
                  AppTheme.errorRed,
                  Icons.trending_down,
                ),
                const SizedBox(height: 12),
                
                // Net Profit/Loss Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProfitable
                          ? [AppTheme.successGreen, AppTheme.successGreen.withOpacity(0.8)]
                          : [AppTheme.errorRed, AppTheme.errorRed.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isProfitable ? 'Net Profit' : 'Net Loss',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(_netProfit.abs()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isProfitable ? 'Profitable period' : 'Loss period',
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
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _allRecords.length,
                        itemBuilder: (context, index) {
                          final record = _allRecords[index];
                          return _buildTransactionCard(record);
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

  Widget _buildSummaryCard(String title, String amount, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> record) {
    final isIncome = record['type'] == 'income';
    final color = isIncome ? AppTheme.successGreen : AppTheme.errorRed;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isIncome ? Icons.add : Icons.remove,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          record['description'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_dateFormat.format(record['date'] as DateTime)),
        trailing: Text(
          '${isIncome ? '+' : '-'}${_currencyFormat.format(record['amount'])}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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
            Icons.assessment,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No financial records found',
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
