import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/screens/stock_movement_screen.dart';
import 'package:a_one_bakeries_app/screens/multi_item_allocation_screen.dart';
import 'package:a_one_bakeries_app/screens/multi_item_receiving_screen.dart';
import 'package:a_one_bakeries_app/screens/supplier_screen.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_stock_dialog.dart';

/// Stock Screen
/// 
/// Main screen for stock management.
/// Enhanced with expandable FAB and multi-item operations.

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<StockItem> _stockItems = [];
  List<StockItem> _filteredStockItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // FAB expansion state
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _loadStockItems();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Toggle FAB expansion
  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// Load all stock items
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

  /// Filter stock items
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
    _toggleFab(); // Close FAB first
    
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

  /// Navigate to multi-item allocation
  void _navigateToMultiItemAllocation() {
    _toggleFab(); // Close FAB first
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MultiItemAllocationScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadStockItems();
        _showSuccessSnackBar('Stock allocated successfully!');
      }
    });
  }

  /// Navigate to multi-item receiving
  void _navigateToMultiItemReceiving() {
    _toggleFab(); // Close FAB first
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MultiItemReceivingScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadStockItems();
        _showSuccessSnackBar('Stock received successfully!');
      }
    });
  }

  /// Navigate to stock movements
  void _navigateToStockMovements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StockMovementScreen(),
      ),
    );
  }

  /// Navigate to suppliers
  void _navigateToSuppliers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupplierScreen(),
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
            icon: const Icon(Icons.business),
            onPressed: _navigateToSuppliers,
            tooltip: 'Suppliers',
          ),
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
      floatingActionButton: _buildExpandableFab(),
    );
  }

  /// Build stock item card (without receive/allocate buttons)
  Widget _buildStockItemCard(StockItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
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

            // Item Info
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
                    '${item.quantityOnHand} ${item.unit}', // No decimals!
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

            // Edit and Delete Menu
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
      ),
    );
  }

  /// Build expandable FAB with speed dial
  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Backdrop
        if (_isFabExpanded)
          GestureDetector(
            onTap: _toggleFab,
            child: Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // Speed dial options
        ScaleTransition(
          scale: _expandAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSpeedDialOption(
                label: 'Allocate Stock',
                icon: Icons.remove_circle_outline,
                color: AppTheme.secondaryOrange,
                onTap: _navigateToMultiItemAllocation,
              ),
              const SizedBox(height: 16),
              _buildSpeedDialOption(
                label: 'Receive Stock',
                icon: Icons.add_circle_outline,
                color: AppTheme.successGreen,
                onTap: _navigateToMultiItemReceiving,
              ),
              const SizedBox(height: 16),
              _buildSpeedDialOption(
                label: 'Add Stock Item',
                icon: Icons.add,
                color: AppTheme.primaryBrown,
                onTap: _showAddStockDialog,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggleFab,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _expandAnimation,
          ),
        ),
      ],
    );
  }

  /// Build speed dial option
  Widget _buildSpeedDialOption({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          mini: true,
          child: Icon(icon),
        ),
      ],
    );
  }

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