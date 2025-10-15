import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// Add/Edit Stock Dialog
/// 
/// A dialog form to add a new stock item or edit an existing one.
/// Validates input and saves to database.

class AddEditStockDialog extends StatefulWidget {
  final StockItem? stockItem; // null = add new, not null = edit existing

  const AddEditStockDialog({
    super.key,
    this.stockItem,
  });

  @override
  State<AddEditStockDialog> createState() => _AddEditStockDialogState();
}

class _AddEditStockDialogState extends State<AddEditStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _quantityController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values if editing
    _nameController = TextEditingController(text: widget.stockItem?.name ?? '');
    _unitController = TextEditingController(text: widget.stockItem?.unit ?? '');
    _quantityController = TextEditingController(
      text: widget.stockItem?.quantityOnHand.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Save stock item to database
  Future<void> _saveStockItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final stockItem = StockItem(
        id: widget.stockItem?.id,
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        quantityOnHand: double.parse(_quantityController.text.trim()),
        createdAt: widget.stockItem?.createdAt,
      );

      if (widget.stockItem == null) {
        // Add new item
        await _dbHelper.insertStockItem(stockItem);
      } else {
        // Update existing item
        await _dbHelper.updateStockItem(stockItem);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving stock item: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.stockItem != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Stock Item' : 'Add Stock Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Flour, Sugar, Yeast',
                  prefixIcon: Icon(Icons.label),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unit Field
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit of Measurement',
                  hintText: 'e.g., kg, L, bags, packets',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Initial Quantity Field (only for new items)
              if (!isEditing)
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Quantity',
                    hintText: '0',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter quantity';
                    }
                    final quantity = double.tryParse(value.trim());
                    if (quantity == null || quantity < 0) {
                      return 'Please enter valid quantity';
                    }
                    return null;
                  },
                ),

              // Info message for editing
              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.secondaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.secondaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use "Receive" or "Allocate" to update quantity',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        // Save Button
        ElevatedButton(
          onPressed: _isSaving ? null : _saveStockItem,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}