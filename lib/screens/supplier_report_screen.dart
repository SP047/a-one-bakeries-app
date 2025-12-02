import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/supplier_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/services/report_export_service.dart';
import 'package:intl/intl.dart';

/// Supplier Report Screen
/// 
/// Displays supplier transaction history including invoices and payments.
/// Shows outstanding balances and allows Excel/PDF export.

class SupplierReportScreen extends StatefulWidget {
  const SupplierReportScreen({super.key});

  @override
  State<SupplierReportScreen> createState() => _SupplierReportScreenState();
}

class _SupplierReportScreenState extends State<SupplierReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ReportExportService _exportService = ReportExportService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');

  List<Supplier> _suppliers = [];
  Map<int, double> _supplierInvoiceTotals = {};
  Map<int, double> _supplierPaymentTotals = {};
  bool _isLoading = false;

  double _totalInvoices = 0.0;
  double _totalPayments = 0.0;

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
      // Get all suppliers
      final suppliers = await _dbHelper.getAllSuppliers();
      
      // Calculate totals per supplier
      final Map<int, double> invoiceTotals = {};
      final Map<int, double> paymentTotals = {};
      double totalInv = 0.0;
      double totalPay = 0.0;

      for (final supplier in suppliers) {
        // Get invoices for this supplier
        final invoices = await _dbHelper.getSupplierInvoices(supplier.id!);
        final invoiceTotal = invoices.fold<double>(
          0.0,
          (sum, inv) => sum + inv.amount,
        );
        invoiceTotals[supplier.id!] = invoiceTotal;
        totalInv += invoiceTotal;

        // Get payments for this supplier
        final payments = await _dbHelper.getSupplierPayments(supplier.id!);
        final paymentTotal = payments.fold<double>(
          0.0,
          (sum, pay) => sum + pay.amount,
        );
        paymentTotals[supplier.id!] = paymentTotal;
        totalPay += paymentTotal;
      }

      setState(() {
        _suppliers = suppliers;
        _supplierInvoiceTotals = invoiceTotals;
        _supplierPaymentTotals = paymentTotals;
        _totalInvoices = totalInv;
        _totalPayments = totalPay;
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
      final headers = ['Supplier Name', 'Total Invoices', 'Total Payments', 'Balance'];
      final rows = _suppliers.map((supplier) {
        final invoices = _supplierInvoiceTotals[supplier.id] ?? 0;
        final payments = _supplierPaymentTotals[supplier.id] ?? 0;
        final balance = invoices - payments;
        return [
          supplier.name,
          invoices,
          payments,
          balance,
        ];
      }).toList();

      final filePath = await _exportService.exportToExcel(
        reportTitle: 'Supplier Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Suppliers', 'Total Invoices', 'Total Payments', 'Outstanding Balance'],
        summaryValues: [_suppliers.length, _totalInvoices, _totalPayments, _totalInvoices - _totalPayments],
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
      final headers = ['Supplier Name', 'Total Invoices', 'Total Payments', 'Balance'];
      final rows = _suppliers.map((supplier) {
        final invoices = _supplierInvoiceTotals[supplier.id] ?? 0;
        final payments = _supplierPaymentTotals[supplier.id] ?? 0;
        final balance = invoices - payments;
        return [
          supplier.name,
          _currencyFormat.format(invoices),
          _currencyFormat.format(payments),
          _currencyFormat.format(balance),
        ];
      }).toList();

      await _exportService.exportToPdf(
        reportTitle: 'Supplier Report',
        headers: headers,
        rows: rows,
        summaryTitle: 'Summary',
        summaryLabels: ['Total Suppliers', 'Total Invoices', 'Total Payments', 'Outstanding Balance'],
        summaryValues: [_suppliers.length.toString(), _currencyFormat.format(_totalInvoices), _currencyFormat.format(_totalPayments), _currencyFormat.format(_totalInvoices - _totalPayments)],
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
    final outstandingBalance = _totalInvoices - _totalPayments;

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Supplier Report'),
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
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Suppliers',
                    _suppliers.length.toString(),
                    Icons.business,
                    AppTheme.primaryBrown,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Invoices',
                    _currencyFormat.format(_totalInvoices),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Payments',
                    _currencyFormat.format(_totalPayments),
                    Icons.payment,
                    AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Outstanding',
                    _currencyFormat.format(outstandingBalance),
                    Icons.account_balance_wallet,
                    outstandingBalance > 0 ? AppTheme.errorRed : AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Suppliers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suppliers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadReport,
                        color: AppTheme.primaryBrown,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _suppliers.length,
                          itemBuilder: (context, index) {
                            return _buildSupplierCard(_suppliers[index]);
                          },
                        ),
                      ),
          ),
        ],
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

  Widget _buildSupplierCard(Supplier supplier) {
    final invoices = _supplierInvoiceTotals[supplier.id] ?? 0;
    final payments = _supplierPaymentTotals[supplier.id] ?? 0;
    final balance = invoices - payments;
    final balanceColor = balance > 0 ? AppTheme.errorRed : 
                         balance < 0 ? AppTheme.successGreen : 
                         AppTheme.darkBrown;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier Name
            Text(
              supplier.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Contact Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  supplier.contactPerson,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  supplier.phoneNumber,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Financial Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoices',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    Text(
                      _currencyFormat.format(invoices),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payments',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    Text(
                      _currencyFormat.format(payments),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balance > 0 ? 'Outstanding' : balance < 0 ? 'Overpaid' : 'Settled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    Text(
                      _currencyFormat.format(balance.abs()),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: balanceColor,
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
            Icons.business_outlined,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
