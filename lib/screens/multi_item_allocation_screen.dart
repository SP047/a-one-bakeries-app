import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// Multi-Item Allocation Screen
///
/// Allows allocating multiple stock items at once.
/// User selects items, enters quantities, and specifies the employee name.
class MultiItemAllocationScreen extends StatefulWidget {
  const MultiItemAllocationScreen({super.key});

  @override
  State<MultiItemAllocationScreen> createState() =>
      _MultiItemAllocationScreenState();
}

class _MultiItemAllocationScreenState extends State<MultiItemAllocationScreen> {
  // -------------------- CONTROLLERS & KEYS --------------------
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // -------------------- DATA --------------------
  List<StockItem> _allStockItems = [];          // All stock items
  List<AllocationItem> _allocationItems = [];   // Items selected for allocation

  // -------------------- STATE FLAGS --------------------
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // -------------------- DATA LOAD --------------------
  /// Fetch all stock items from database
  Future<void> _loadStockItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _dbHelper.getAllStockItems();
      setState(() {
        _allStockItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showErrorSnackBar('Error loading stock items: $e');
    }
  }

  // -------------------- ALLOCATION LIST MANAGEMENT --------------------
  /// Add an item to allocation list
  void _addItem(StockItem stockItem) {
    if (_allocationItems.any((item) => item.stockItem.id == stockItem.id)) {
      _showErrorSnackBar('${stockItem.name} is already in the list');
      return;
    }
    setState(() => _allocationItems.add(AllocationItem(stockItem: stockItem)));
  }

  /// Remove item from allocation list
  void _removeItem(int index) {
    setState(() => _allocationItems.removeAt(index));
  }

  /// Total items in allocation list
  int get _totalItems => _allocationItems.length;

  /// Total quantity of all allocated items
  int get _totalQuantity =>
      _allocationItems.fold(0, (sum, item) => sum + item.quantity);

  // -------------------- SAVE ALLOCATIONS --------------------
  /// Validate and save allocation to database
  Future<void> _saveAllocations() async {
    if (!_formKey.currentState!.validate()) return;

    if (_allocationItems.isEmpty) {
      _showErrorSnackBar('Please add at least one item');
      return;
    }

    // Validate quantities
    for (var item in _allocationItems) {
      if (item.quantity <= 0) {
        _showErrorSnackBar('Please enter quantity for all items');
        return;
      }
      if (item.quantity > item.stockItem.quantityOnHand.toInt()) {
        _showErrorSnackBar(
            '${item.stockItem.name}: Insufficient stock (Available: ${item.stockItem.quantityOnHand.toInt()})');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      for (var item in _allocationItems) {
        final movement = StockMovement(
          stockItemId: item.stockItem.id!,
          stockItemName: item.stockItem.name,
          movementType: 'ALLOCATED',
          quantity: item.quantity,
          employeeName: _employeeController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await _dbHelper.insertStockMovement(movement);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) _showErrorSnackBar('Error saving allocations: $e');
    }
  }

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(title: const Text('Allocate Stock')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeaderSection(),
                  Expanded(
                    child: _allocationItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _allocationItems.length,
                            itemBuilder: (context, index) =>
                                _buildAllocationItemCard(index),
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

  // -------------------- UI COMPONENTS --------------------
  /// Header with employee name, notes, and summary
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Name
          TextFormField(
            controller: _employeeController,
            decoration: const InputDecoration(
              labelText: 'Employee Name',
              hintText: 'Who is receiving this stock?',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Please enter employee name'
                    : null,
          ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'e.g., Order details',
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
              color: AppTheme.primaryBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items: $_totalItems',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Total Qty: $_totalQuantity',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBrown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card for each allocation item with quantity controls
  Widget _buildAllocationItemCard(int index) {
    final item = _allocationItems[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.stockItem.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Available: ${item.stockItem.quantityOnHand.toInt()} ${item.stockItem.unit}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: AppTheme.darkBrown.withOpacity(0.6)),
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

            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (item.quantity > 0) {
                      setState(() => item.quantity--);
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
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBrown),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (item.quantity < item.stockItem.quantityOnHand.toInt()) {
                      setState(() => item.quantity++);
                    } else {
                      _showErrorSnackBar('Maximum quantity reached');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: AppTheme.darkBrown.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No items added',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppTheme.darkBrown.withOpacity(0.5))),
          const SizedBox(height: 8),
          Text('Tap + to add stock items',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.darkBrown.withOpacity(0.5))),
        ],
      ),
    );
  }

  /// Bottom bar with Save button
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
            onPressed: _isSaving ? null : _saveAllocations,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(
                    'Allocate ${_allocationItems.length} Items',
                    style: const TextStyle(fontSize: 18),
                  ),
          ),
        ),
      ),
    );
  }

  /// Dialog to add stock item
  Future<void> _showAddItemDialog() async {
    StockItem? selectedItem;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stock Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setState) => DropdownButtonFormField<StockItem>(
              value: selectedItem,
              decoration: const InputDecoration(
                labelText: 'Select Item',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              items: _allStockItems
                  .where((item) =>
                      !_allocationItems.any((ai) => ai.stockItem.id == item.id))
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                            '${item.name} (${item.quantityOnHand.toInt()} ${item.unit})'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedItem = value),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed, duration: const Duration(seconds: 3)),
    );
  }
}

/// Helper class representing an allocation item
class AllocationItem {
  final StockItem stockItem;
  int quantity;

  AllocationItem({required this.stockItem, this.quantity = 0});
}
