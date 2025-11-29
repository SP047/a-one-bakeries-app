import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/services/backup_service.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';

/// ============================================================================
/// Export Data Dialog
/// ============================================================================
/// Allows user to export data to CSV or JSON format
/// ============================================================================

class ExportDataDialog extends StatefulWidget {
  const ExportDataDialog({super.key});

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  final BackupService _backupService = BackupService();
  
  String _selectedFormat = 'CSV';
  String? _selectedTable;
  bool _isExporting = false;

  final List<Map<String, String>> _tables = [
    {'value': 'ALL', 'label': 'All Data (JSON only)'},
    {'value': 'vehicles', 'label': 'Vehicles'},
    {'value': 'employees', 'label': 'Employees'},
    {'value': 'orders', 'label': 'Orders'},
    {'value': 'order_items', 'label': 'Order Items'},
    {'value': 'stock_items', 'label': 'Stock Items'},
    {'value': 'stock_movements', 'label': 'Stock Movements'},
    {'value': 'income', 'label': 'Income'},
    {'value': 'expenses', 'label': 'Expenses'},
    {'value': 'suppliers', 'label': 'Suppliers'},
    {'value': 'supplier_invoices', 'label': 'Supplier Invoices'},
    {'value': 'supplier_payments', 'label': 'Supplier Payments'},
    {'value': 'credit_transactions', 'label': 'Credit Transactions'},
    {'value': 'km_records', 'label': 'KM Records'},
    {'value': 'service_records', 'label': 'Service Records'},
  ];

  Future<void> _export() async {
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a table to export'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      String filePath;

      if (_selectedTable == 'ALL') {
        // Export all data to JSON
        filePath = await _backupService.exportAllDataToJSON();
      } else if (_selectedFormat == 'CSV') {
        // Export single table to CSV
        filePath = await _backupService.exportTableToCSV(_selectedTable!);
      } else {
        // For now, JSON export of single table not implemented
        throw Exception('JSON export for single tables not yet implemented');
      }

      if (!mounted) return;
      setState(() => _isExporting = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Data exported successfully!\n$filePath'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export failed: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download, color: AppTheme.darkBrown),
          SizedBox(width: 12),
          Text('Export Data'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            const Text(
              'Export Format',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('CSV'),
                    value: 'CSV',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                        // Reset table selection if ALL was selected
                        if (_selectedTable == 'ALL') {
                          _selectedTable = null;
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('JSON'),
                    value: 'JSON',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() => _selectedFormat = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table selection
            const Text(
              'Select Data',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTable,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose table to export',
              ),
              items: _tables
                  .where((table) =>
                      _selectedFormat == 'JSON' || table['value'] != 'ALL')
                  .map((table) => DropdownMenuItem(
                        value: table['value'],
                        child: Text(table['label']!),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedTable = value);
              },
            ),
            const SizedBox(height: 16),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.darkBrown,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFormat == 'CSV'
                          ? 'CSV files can be opened in Excel or Google Sheets'
                          : 'JSON files contain all data in a structured format',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkBrown.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _export,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkBrown,
            foregroundColor: Colors.white,
          ),
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Export'),
        ),
      ],
    );
  }
}
