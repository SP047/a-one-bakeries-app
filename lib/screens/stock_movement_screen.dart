import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// Stock Movement Screen
/// 
/// Displays history of all stock movements (received and allocated).
/// Supports filtering by date range and sorting.

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key});

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<StockMovement> _movements = [];
  List<StockMovement> _filteredMovements = [];
  bool _isLoading = true;
  bool _sortNewestFirst = true;
  String _filterType = 'ALL'; // ALL, RECEIVED, ALLOCATED

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  /// Load all stock movements
  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final movements = await _dbHelper.getAllStockMovements();
      setState(() {
        _movements = movements;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading movements: $e');
      }
    }
  }

  /// Apply filters and sorting
  void _applyFilters() {
    List<StockMovement> filtered = _movements;

    // Filter by type
    if (_filterType != 'ALL') {
      filtered = filtered.where((m) => m.movementType == _filterType).toList();
    }

    // Sort
    if (_sortNewestFirst) {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    setState(() {
      _filteredMovements = filtered;
    });
  }

  /// Toggle sort order
  void _toggleSortOrder() {
    setState(() {
      _sortNewestFirst = !_sortNewestFirst;
      _applyFilters();
    });
  }

  /// Change filter type
  void _changeFilterType(String type) {
    setState(() {
      _filterType = type;
      _applyFilters();
    });
  }

  /// Show date range picker (for custom filter - Phase 3 advanced)
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBrown,
              onPrimary: Colors.white,
              surface: AppTheme.lightCream,
              onSurface: AppTheme.darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      try {
        final movements = await _dbHelper.getStockMovementsByDateRange(
          picked.start,
          picked.end.add(const Duration(days: 1)), // Include end date
        );
        setState(() {
          _movements = movements;
          _applyFilters();
        });
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error filtering by date: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Stock Movements'),
        actions: [
          // Sort Button
          IconButton(
            icon: Icon(_sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: _toggleSortOrder,
            tooltip: _sortNewestFirst ? 'Newest First' : 'Oldest First',
          ),
          // Date Filter Button
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Movements List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMovements.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMovements,
                        color: AppTheme.primaryBrown,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMovements.length,
                          itemBuilder: (context, index) {
                            return _buildMovementCard(_filteredMovements[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Filter: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RECEIVED', 'Received'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ALLOCATED', 'Allocated'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build single filter chip
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _changeFilterType(value);
      },
      selectedColor: AppTheme.primaryBrown,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.darkBrown,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  /// Build movement card
  Widget _buildMovementCard(StockMovement movement) {
    final isReceived = movement.movementType == 'RECEIVED';
    final color = isReceived ? AppTheme.successGreen : AppTheme.secondaryOrange;
    final icon = isReceived ? Icons.add_circle : Icons.remove_circle;

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
                // Movement Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Stock Item Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.stockItemName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        movement.movementType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),

                // Quantity Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${isReceived ? '+' : '-'}${movement.quantity.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.darkBrown.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _dateFormat.format(movement.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.6),
                      ),
                ),
              ],
            ),

            // Employee Name (for allocations)
            if (movement.employeeName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.darkBrown.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    movement.employeeName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkBrown.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],

            // Notes
            if (movement.notes != null && movement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.creamBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppTheme.darkBrown.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        movement.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
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

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No movements yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stock movements will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
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