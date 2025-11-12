import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// Edit Credit Transaction Dialog
/// 
/// Allows editing existing credit transactions (borrow/repay).
/// Can change amount, reason, and date.

class EditCreditTransactionDialog extends StatefulWidget {
  final CreditTransaction transaction;

  const EditCreditTransactionDialog({
    super.key,
    required this.transaction,
  });

  @override
  State<EditCreditTransactionDialog> createState() => _EditCreditTransactionDialogState();
}

class _EditCreditTransactionDialogState extends State<EditCreditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    // Initialize with existing values
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _reasonController = TextEditingController(
      text: widget.transaction.reason,
    );
    _selectedDate = widget.transaction.createdAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Save updated transaction
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedTransaction = CreditTransaction(
        id: widget.transaction.id,
        employeeId: widget.transaction.employeeId,
        employeeName: widget.transaction.employeeName,
        transactionType: widget.transaction.transactionType,
        amount: double.parse(_amountController.text.trim()),
        reason: _reasonController.text.trim(),
        createdAt: _selectedDate,
      );

      await _dbHelper.updateCreditTransaction(updatedTransaction);

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
            content: Text('Error updating transaction: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  /// Show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      // Show time picker
      if (mounted) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDate),
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

        if (pickedTime != null) {
          setState(() {
            _selectedDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBorrow = widget.transaction.transactionType == 'BORROW';
    final color = isBorrow ? AppTheme.errorRed : AppTheme.successGreen;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isBorrow ? Icons.add_circle : Icons.remove_circle,
            color: color,
          ),
          const SizedBox(width: 8),
          Text('Edit ${isBorrow ? 'Borrowed' : 'Repayment'}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing will update the credit balance',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'R ',
                  prefixIcon: Icon(Icons.money, color: color),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reason Field
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g., Emergency, Advance payment',
                  prefixIcon: Icon(Icons.note),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Field
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.edit, size: 20),
                  ),
                  child: Text(
                    _dateFormat.format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
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
          onPressed: _isSaving ? null : _saveTransaction,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}