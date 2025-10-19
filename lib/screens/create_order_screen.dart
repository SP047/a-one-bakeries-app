import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/order_model.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// Create Order Screen
/// 
/// Screen to create a new order for a driver or vehicle.
/// Tracks quantities only (no pricing).

class CreateOrderScreen extends StatefulWidget {
  final Order? existingOrder;
  final List<OrderItem>? existingItems;

  const CreateOrderScreen({
    super.key,
    this.existingOrder,
    this.existingItems,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  
  // Order assignment
  String _orderType = 'DRIVER';
  Employee? _selectedDriver;
  Vehicle? _selectedVehicle;
  
  List<Employee> _drivers = [];
  List<Vehicle> _vehicles = [];
  
  // Order items (table rows)
  List<OrderItemRow> _orderItems = [OrderItemRow()];
  
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDriversAndVehicles();
    
    // If editing, load existing data
    if (widget.existingOrder != null && widget.existingItems != null) {
      _loadExistingOrder();
    }
  }

  /// Load existing order for editing
  void _loadExistingOrder() {
    final order = widget.existingOrder!;
    
    setState(() {
      _orderType = order.isDriverOrder ? 'DRIVER' : 'VEHICLE';
      
      // Load items
      _orderItems = widget.existingItems!.map((item) {
        return OrderItemRow(
          itemType: item.itemType,
          trolliesOrQty: item.trolliesOrQty,
        );
      }).toList();
    });
  }

  /// Load drivers and vehicles
  Future<void> _loadDriversAndVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drivers = await _dbHelper.getEmployeesByRole(EmployeeRoles.driver);
      final vehicles = await _dbHelper.getAllVehicles();

      setState(() {
        _drivers = drivers;
        _vehicles = vehicles;
        
        // If editing, set selected driver/vehicle
        if (widget.existingOrder != null) {
          if (widget.existingOrder!.driverId != null) {
            _selectedDriver = drivers.firstWhere(
              (d) => d.id == widget.existingOrder!.driverId,
              orElse: () => drivers.first,
            );
          }
          if (widget.existingOrder!.vehicleId != null) {
            _selectedVehicle = vehicles.firstWhere(
              (v) => v.id == widget.existingOrder!.vehicleId,
              orElse: () => vehicles.first,
            );
          }
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Add new row to order items
  void _addRow() {
    setState(() {
      _orderItems.add(OrderItemRow());
    });
  }

  /// Remove row from order items
  void _removeRow(int index) {
    if (_orderItems.length > 1) {
      setState(() {
        _orderItems.removeAt(index);
      });
    }
  }

  /// Calculate total quantity
  int _calculateTotalQuantity() {
    int total = 0;
    for (var item in _orderItems) {
      if (item.isValid) {
        total += item.quantity;
      }
    }
    return total;
  }

  /// Validate and save order
  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate order assignment
    if (_orderType == 'DRIVER' && _selectedDriver == null) {
      _showErrorSnackBar('Please select a driver');
      return;
    }
    if (_orderType == 'VEHICLE' && _selectedVehicle == null) {
      _showErrorSnackBar('Please select a vehicle');
      return;
    }

    // Validate order items
    if (_orderItems.where((item) => item.isValid).isEmpty) {
      _showErrorSnackBar('Please add at least one valid item');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create order
      final order = Order(
        id: widget.existingOrder?.id,
        driverId: _orderType == 'DRIVER' ? _selectedDriver!.id : null,
        driverName: _orderType == 'DRIVER' ? _selectedDriver!.fullName : null,
        vehicleId: _orderType == 'VEHICLE' ? _selectedVehicle!.id : null,
        vehicleInfo: _orderType == 'VEHICLE' ? _selectedVehicle!.fullName : null,
        totalQuantity: _calculateTotalQuantity(),
        createdAt: widget.existingOrder?.createdAt,
      );

      // Create order items
      final items = _orderItems
          .where((item) => item.isValid)
          .map((item) => OrderItem(
                orderId: widget.existingOrder?.id ?? 0,
                itemType: item.itemType!,
                trolliesOrQty: item.trolliesOrQty!,
                quantity: item.quantity,
              ))
          .toList();

      // Save to database
      if (widget.existingOrder == null) {
        await _dbHelper.insertOrder(order, items);
      } else {
        await _dbHelper.updateOrder(order, items);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingOrder == null 
                ? 'Order created successfully!' 
                : 'Order updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error saving order: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingOrder != null;
    
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Order' : 'Create Order'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Type Selection
                          _buildOrderTypeSelection(),
                          const SizedBox(height: 24),

                          // Driver/Vehicle Selection
                          _buildAssignmentSelection(),
                          const SizedBox(height: 24),

                          // Order Items Section
                          _buildOrderItemsSection(),
                          const SizedBox(height: 24),

                          // Total Quantity
                          _buildTotalSection(),
                        ],
                      ),
                    ),
                  ),

                  // Save Button
                  _buildBottomBar(),
                ],
              ),
            ),
    );
  }

  /// Build order type selection
  Widget _buildOrderTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order For',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Driver'),
                value: 'DRIVER',
                groupValue: _orderType,
                onChanged: (value) {
                  setState(() {
                    _orderType = value!;
                    _selectedDriver = null;
                    _selectedVehicle = null;
                  });
                },
                activeColor: AppTheme.primaryBrown,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Vehicle'),
                value: 'VEHICLE',
                groupValue: _orderType,
                onChanged: (value) {
                  setState(() {
                    _orderType = value!;
                    _selectedDriver = null;
                    _selectedVehicle = null;
                  });
                },
                activeColor: AppTheme.primaryBrown,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build assignment selection
  Widget _buildAssignmentSelection() {
    if (_orderType == 'DRIVER') {
      return DropdownButtonFormField<Employee>(
        value: _selectedDriver,
        decoration: const InputDecoration(
          labelText: 'Select Driver',
          prefixIcon: Icon(Icons.person),
        ),
        items: _drivers
            .map((driver) => DropdownMenuItem(
                  value: driver,
                  child: Text(driver.fullName),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedDriver = value;
          });
        },
        validator: (value) {
          if (value == null) return 'Please select a driver';
          return null;
        },
      );
    } else {
      return DropdownButtonFormField<Vehicle>(
        value: _selectedVehicle,
        decoration: const InputDecoration(
          labelText: 'Select Vehicle',
          prefixIcon: Icon(Icons.local_shipping),
        ),
        items: _vehicles
            .map((vehicle) => DropdownMenuItem(
                  value: vehicle,
                  child: Text('${vehicle.fullName} - ${vehicle.registrationNumber}'),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedVehicle = value;
          });
        },
        validator: (value) {
          if (value == null) return 'Please select a vehicle';
          return null;
        },
      );
    }
  }

  /// Build order items section (the table)
  Widget _buildOrderItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            OutlinedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Order items list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderItems.length,
          itemBuilder: (context, index) {
            return _buildOrderItemRow(index);
          },
        ),
      ],
    );
  }

  /// Build single order item row
  Widget _buildOrderItemRow(int index) {
    final item = _orderItems[index];
    final isBiscuits = item.itemType == OrderItemTypes.bucketBiscuits;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Row header with delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_orderItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                    onPressed: () => _removeRow(index),
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Type Dropdown
            DropdownButtonFormField<String>(
              value: item.itemType,
              decoration: const InputDecoration(
                labelText: 'Item',
                isDense: true,
              ),
              items: OrderItemTypes.allTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  item.itemType = value;
                  item.trolliesOrQty = null; // Reset when type changes
                });
              },
            ),
            const SizedBox(height: 12),

            // Trollies (for Bread) or Quantity (for Biscuits) Dropdown
            DropdownButtonFormField<int>(
              value: item.trolliesOrQty,
              decoration: InputDecoration(
                labelText: isBiscuits ? 'Quantity' : 'Trollies',
                isDense: true,
              ),
              items: List.generate(isBiscuits ? 20 : 10, (i) => i + 1)
                  .map((num) => DropdownMenuItem(
                        value: num,
                        child: Text(num.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  item.trolliesOrQty = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Quantity Display
            if (item.isValid) ...[
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
                      'QUANTITY:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      item.quantity.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryBrown,
                            fontWeight: FontWeight.bold,
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

  /// Build total section
  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBrown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Quantity:',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            _calculateTotalQuantity().toString(),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// Build bottom bar with save button
  Widget _buildBottomBar() {
    final isEditing = widget.existingOrder != null;
    
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
            onPressed: _isSaving ? null : _saveOrder,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    isEditing ? 'Update Order' : 'Create Order',
                    style: const TextStyle(fontSize: 18),
                  ),
          ),
        ),
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

/// Order Item Row Helper Class
class OrderItemRow {
  String? itemType;
  int? trolliesOrQty;

  OrderItemRow({
    this.itemType,
    this.trolliesOrQty,
  });

  bool get isValid => itemType != null && trolliesOrQty != null;

  int get quantity {
    if (!isValid) return 0;
    return OrderItem.calculateQuantity(itemType!, trolliesOrQty!);
  }
}