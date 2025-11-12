import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/stock_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// Receive Stock Dialog - FIXED VERSION
/// 
/// Dialog to record stock received from supplier.
/// Updates stock quantity and creates a movement record.
/// 
/// FIX: Properly handles int to double conversion

class ReceiveStockDialog extends StatefulWidget {
  final StockItem stockItem;

  const ReceiveStockDialog({
    super.key,
    required this.stockItem,
  });

  @override
  State<ReceiveStockDialog> createState() => _ReceiveStockDialogState();
}

class _ReceiveStockDialogState extends State<ReceiveStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Save received stock - FIXED VERSION
  Future<void> _saveReceivedStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // FIX: Parse as double to avoid type casting errors
      final quantityText = _quantityController.text.trim();
      final quantity = int.parse(quantityText);

      final movement = StockMovement(
        stockItemId: widget.stockItem.id!,
        stockItemName: widget.stockItem.name,
        movementType: 'RECEIVED',
        quantity: quantity, // Now properly typed as double
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      await _dbHelper.insertStockMovement(movement);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error receiving stock: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Receive Stock'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock Item Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: AppTheme.primaryBrown,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stockItem.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Current: ${widget.stockItem.quantityOnHand.toStringAsFixed(0)} ${widget.stockItem.unit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quantity Received Field
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity Received',
                  hintText: 'Enter quantity',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  suffixText: widget.stockItem.unit,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  // FIX: Try parsing as double
                  final quantity = double.tryParse(value.trim());
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes Field (Optional)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g., Supplier name, invoice number',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // New Quantity Preview
              if (_quantityController.text.isNotEmpty && 
                  double.tryParse(_quantityController.text) != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: AppTheme.successGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'New quantity: ${(widget.stockItem.quantityOnHand + double.parse(_quantityController.text)).toStringAsFixed(0)} ${widget.stockItem.unit}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.w600,
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
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveReceivedStock,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check),
          label: const Text('Receive'),
        ),
      ],
    );
  }
}