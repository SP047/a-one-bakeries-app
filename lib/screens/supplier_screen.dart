import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/supplier_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/screens/supplier_details_screen.dart';
import 'package:a_one_bakeries_app/screens/supplier_report_screen.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_supplier_dialog.dart';

/// Supplier Screen
/// 
/// Main screen for supplier management.
/// Displays all suppliers with their account balances.

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Supplier> _suppliers = [];
  Map<int, double> _balances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  /// Load all suppliers and their balances
  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suppliers = await _dbHelper.getAllSuppliers();
      
      // Load balance for each supplier
      Map<int, double> balances = {};
      for (var supplier in suppliers) {
        final balance = await _dbHelper.getSupplierBalance(supplier.id!);
        balances[supplier.id!] = balance;
      }

      setState(() {
        _suppliers = suppliers;
        _balances = balances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading suppliers: $e');
      }
    }
  }

  /// Show add supplier dialog
  Future<void> _showAddSupplierDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditSupplierDialog(),
    );

    if (result == true) {
      _loadSuppliers();
      if (mounted) {
        _showSuccessSnackBar('Supplier added successfully!');
      }
    }
  }

  /// Show edit supplier dialog
  Future<void> _showEditSupplierDialog(Supplier supplier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditSupplierDialog(supplier: supplier),
    );

    if (result == true) {
      _loadSuppliers();
      if (mounted) {
        _showSuccessSnackBar('Supplier updated successfully!');
      }
    }
  }

  /// Delete supplier
  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text(
            'Are you sure you want to delete ${supplier.name}? This will also delete all related invoices and payments.'),
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
        await _dbHelper.deleteSupplier(supplier.id!);
        _loadSuppliers();
        if (mounted) {
          _showSuccessSnackBar('Supplier deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting supplier: $e');
        }
      }
    }
  }

  /// Navigate to supplier details
  void _navigateToSupplierDetails(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierDetailsScreen(supplier: supplier),
      ),
    ).then((_) => _loadSuppliers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierReportScreen()),
              );
            },
            tooltip: 'Supplier Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSuppliers,
                  color: AppTheme.primaryBrown,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _suppliers.length,
                    itemBuilder: (context, index) {
                      return _buildSupplierCard(_suppliers[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSupplierDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build supplier card
  Widget _buildSupplierCard(Supplier supplier) {
    final balance = _balances[supplier.id] ?? 0.0;
    final hasBalance = balance > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToSupplierDetails(supplier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Supplier Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: AppTheme.primaryBrown,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Supplier Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supplier.contactPerson,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkBrown.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supplier.phoneNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkBrown.withOpacity(0.6),
                          ),
                    ),
                    if (hasBalance) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Balance Owed: R ${balance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditSupplierDialog(supplier);
                  } else if (value == 'delete') {
                    _deleteSupplier(supplier);
                  } else if (value == 'details') {
                    _navigateToSupplierDetails(supplier);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 20),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
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
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                      ],
                    ),
                  ),
                ],
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
            Icons.business_outlined,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first supplier',
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