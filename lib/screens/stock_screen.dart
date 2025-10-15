import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/screens/stock_movement_screen.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_stock_dialog.dart';
import 'package:a_one_bakeries_app/widgets/receive_stock_dialog.dart';
import 'package:a_one_bakeries_app/widgets/allocate_stock_dialog.dart';

/// Stock Screen
/// 
/// Main screen for stock management.
/// Displays all stock items with their quantities.
/// Allows adding, editing, deleting stock items.
/// Allows receiving stock and allocating stock.

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<StockItem> _stockItems = [];
  List<StockItem> _filteredStockItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all stock items from database
  Future<void> _loadStockItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _dbHelper.getAllStockItems();
      setState(() {
        _stockItems = items;
        _filteredStockItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading stock items: $e');
      }
    }
  }

  /// Search/filter stock items
  void _filterStockItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStockItems = _stockItems;
      } else {
        _filteredStockItems = _stockItems
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// Show add stock dialog
  Future<void> _showAddStockDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditStockDialog(),
    );

    if (result == true) {
      _loadStockItems();
      if (mounted) {
        _showSuccessSnackBar('Stock item added successfully!');
      }
    }
  }

  /// Show edit stock dialog
  Future<void> _showEditStockDialog(StockItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditStockDialog(stockItem: item),
    );

    if (result == true) {
      _loadStockItems();
      if (mounted) {
        _showSuccessSnackBar('Stock item updated successfully!');
      }
    }
  }

  /// Delete stock item
  Future<void> _deleteStockItem(StockItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
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
        await _dbHelper.deleteStockItem(item.id!);
        _loadStockItems();
        if (mounted) {
          _showSuccessSnackBar('Stock item deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting stock item: $e');
        }
      }
    }
  }

  /// Show receive stock dialog
  Future<void> _showReceiveStockDialog(StockItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReceiveStockDialog(stockItem: item),
    );

    if (result == true) {
      _loadStockItems();
      if (mounted) {
        _showSuccessSnackBar('Stock received successfully!');
      }
    }
  }

  /// Show allocate stock dialog
  Future<void> _showAllocateStockDialog(StockItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AllocateStockDialog(stockItem: item),
    );

    if (result == true) {
      _loadStockItems();
      if (mounted) {
        _showSuccessSnackBar('Stock allocated successfully!');
      }
    }
  }

  /// Navigate to stock movement screen
  void _navigateToStockMovements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StockMovementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToStockMovements,
            tooltip: 'Stock Movements',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStockItems,
              decoration: InputDecoration(
                hintText: 'Search stock items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterStockItems('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Stock Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStockItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadStockItems,
                        color: AppTheme.primaryBrown,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredStockItems.length,
                          itemBuilder: (context, index) {
                            return _buildStockItemCard(
                                _filteredStockItems[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build stock item card
  Widget _buildStockItemCard(StockItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Item Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                const SizedBox(width: 12),

                // Item Name and Quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantityOnHand.toStringAsFixed(2)} ${item.unit}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.primaryBrown,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),

                // Edit and Delete Buttons
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditStockDialog(item);
                    } else if (value == 'delete') {
                      _deleteStockItem(item);
                    }
                  },
                  itemBuilder: (context) => [
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

            const Divider(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceiveStockDialog(item),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Receive'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAllocateStockDialog(item),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    label: const Text('Allocate'),
                  ),
                ),
              ],
            ),
          ],
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
            Icons.inventory_2_outlined,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No stock items yet'
                : 'No items found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Tap + to add your first item'
                : 'Try a different search',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
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