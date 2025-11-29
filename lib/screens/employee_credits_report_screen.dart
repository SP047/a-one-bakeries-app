import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/services/report_export_service.dart';
import 'package:intl/intl.dart';

/// Employee Credits Report Screen
/// 
/// Track employee credit balances

class EmployeeCreditsReportScreen extends StatefulWidget {
  const EmployeeCreditsReportScreen({super.key});

  @override
  State<EmployeeCreditsReportScreen> createState() => _EmployeeCreditsReportScreenState();
}

class _EmployeeCreditsReportScreenState extends State<EmployeeCreditsReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReportExportService _exportService = ReportExportService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');

  List<Employee> _employees = [];
  Map<int, double> _employeeCredits = {};
  bool _isLoading = false;
  double _totalCredits = 0.0;

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
      // Get all employees and their credit balances
      final allEmployees = await _dbHelper.getAllEmployees();
      final Map<int, double> employeeCredits = {};
      
      // Calculate credit balance for each employee from transactions
      for (final emp in allEmployees) {
        final balance = await _dbHelper.getEmployeeCreditBalance(emp.id!);
        if (balance > 0) {
          employeeCredits[emp.id!] = balance;
        }
      }
      
      // Filter employees with credits
      final employeesWithCredits = allEmployees
          .where((emp) => employeeCredits.containsKey(emp.id))
          .toList();

      // Sort by credits descending
      employeesWithCredits.sort((a, b) {
        final aCredits = employeeCredits[a.id!] ?? 0;
        final bCredits = employeeCredits[b.id!] ?? 0;
        return bCredits.compareTo(aCredits);
      });

      // Calculate total
      final total = employeeCredits.values.fold<double>(0.0, (sum, credits) => sum + credits);

      setState(() {
        _employees = employeesWithCredits;
        _employeeCredits = employeeCredits;
        _totalCredits = total;
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
      final headers = ['Employee Name', 'ID Number', 'Credits'];
      final rows = _employees.map((emp) => [
        emp.fullName,
        emp.idNumber,
        _employeeCredits[emp.id!] ?? 0,
      ]).toList();

      final filePath = await _exportService.exportToExcel(
        reportTitle: 'Employee Credits Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Credits', 'Number of Employees'],
        summaryValues: [
          _currencyFormat.format(_totalCredits),
          _employees.length,
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
      final headers = ['Employee Name', 'ID Number', 'Credits'];
      final rows = _employees.map((emp) => [
        emp.fullName,
        emp.idNumber,
        _currencyFormat.format(_employeeCredits[emp.id!] ?? 0),
      ]).toList();

      await _exportService.exportToPdf(
        reportTitle: 'Employee Credits Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Credits', 'Number of Employees'],
        summaryValues: [
          _currencyFormat.format(_totalCredits),
          _employees.length.toString(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Employee Credits Report'),
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
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Employee Credits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(_totalCredits),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_employees.length} employees with credits',
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

          // Employee List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employee = _employees[index];
                          return _buildEmployeeCard(employee);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person, color: Colors.purple),
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${employee.idNumber}'),
        trailing: Text(
          _currencyFormat.format(_employeeCredits[employee.id!] ?? 0),
          style: const TextStyle(
            color: Colors.purple,
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
            Icons.account_balance_wallet,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No employee credits found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All employees have zero credits',
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
