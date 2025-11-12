import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/models/supplier_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// Multi-Item Receiving Screen
/// 
/// Allows receiving multiple stock items at once from a supplier.

class MultiItemReceivingScreen extends StatefulWidget {
  const MultiItemReceivingScreen({super.key});

  @override
  State<MultiItemReceivingScreen> createState() => _MultiItemReceivingScreenState();
}

class _MultiItemReceivingScreenState extends State<MultiItemReceivingScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  List<StockItem> _allStockItems = [];
  List<Supplier> _suppliers = [];
  List<ReceivingItem> _receivingItems = [];
  Supplier? _selectedSupplier;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Load stock items and suppliers
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _dbHelper.getAllStockItems();
      final suppliers = await _dbHelper.getAllSuppliers();
      setState(() {
        _allStockItems = items;
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading data: $e');
      }
    }
  }

  /// Add item to receiving list
  void _addItem(StockItem stockItem) {
    if (_receivingItems.any((item) => item.stockItem.id == stockItem.id)) {
      _showErrorSnackBar('${stockItem.name} is already in the list');
      return;
    }

    setState(() {
      _receivingItems.add(ReceivingItem(stockItem: stockItem));
    });
  }

  /// Remove item from receiving list
  void _removeItem(int index) {
    setState(() {
      _receivingItems.removeAt(index);
    });
  }

  /// Calculate totals
  int get _totalItems => _receivingItems.length;
  int get _totalQuantity {
    int total = 0;
    for (var item in _receivingItems) {
      total += item.quantity;
    }
    return total;
  }

  /// Save all receiving
  Future<void> _saveReceiving() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplier == null) {
      _showErrorSnackBar('Please select a supplier');
      return;
    }

    if (_receivingItems.isEmpty) {
      _showErrorSnackBar('Please add at least one item');
      return;
    }

    // Validate all items have quantity
    for (var item in _receivingItems) {
      if (item.quantity <= 0) {
        _showErrorSnackBar('Please enter quantity for all items');
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create movements for each item
      for (var item in _receivingItems) {
        final movement = StockMovement(
          stockItemId: item.stockItem.id!,
          stockItemName: item.stockItem.name,
          movementType: 'RECEIVED',
          quantity: item.quantity, // FIX: Convert int to double
          supplierName: _selectedSupplier!.name,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await _dbHelper.insertStockMovement(movement);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error saving: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Receive Stock'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeaderSection(),
                  Expanded(
                    child: _receivingItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _receivingItems.length,
                            itemBuilder: (context, index) {
                              return _buildReceivingItemCard(index);
                            },
                          ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build header section
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier Selection
          DropdownButtonFormField<Supplier>(
            value: _selectedSupplier,
            decoration: const InputDecoration(
              labelText: 'Select Supplier',
              prefixIcon: Icon(Icons.business),
            ),
            items: _suppliers
                .map((supplier) => DropdownMenuItem(
                      value: supplier,
                      child: Text(supplier.name),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSupplier = value;
              });
            },
            validator: (value) {
              if (value == null) return 'Please select a supplier';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'e.g., Invoice number, delivery details',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items: $_totalItems',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Total Qty: $_totalQuantity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build receiving item card
  Widget _buildReceivingItemCard(int index) {
    final item = _receivingItems[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.stockItem.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current: ${item.stockItem.quantityOnHand.toStringAsFixed(0)} ${item.stockItem.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkBrown.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quantity Input
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (item.quantity > 0) {
                      setState(() {
                        item.quantity--;
                      });
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightCream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity} ${item.stockItem.unit}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      item.quantity++;
                    });
                  },
                ),
              ],
            ),

            // New quantity preview
            if (item.quantity > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Stock:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${item.stockItem.quantityOnHand.toInt() + item.quantity} ${item.stockItem.unit}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
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
            Icons.inbox,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No items added',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add stock items',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveReceiving,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.successGreen,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Receive ${_receivingItems.length} Items',
                    style: const TextStyle(fontSize: 18),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    StockItem? selectedItem;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stock Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<StockItem>(
                    value: selectedItem,
                    decoration: const InputDecoration(
                      labelText: 'Select Item',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    items: _allStockItems
                        .where((item) => !_receivingItems
                            .any((ri) => ri.stockItem.id == item.id))
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text('${item.name} (${item.unit})'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedItem = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedItem != null) {
                _addItem(selectedItem!);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
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

class ReceivingItem {
  final StockItem stockItem;
  int quantity;

  ReceivingItem({
    required this.stockItem,
    this.quantity = 0,
  });
}