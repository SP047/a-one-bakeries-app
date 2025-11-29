import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/finance_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// Add Income Dialog
/// 
/// Dialog to record daily income with coin denomination breakdown

class AddIncomeDialog extends StatefulWidget {
  const AddIncomeDialog({super.key});

  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Coin denomination controllers
  final TextEditingController _r5Controller = TextEditingController(text: '0');
  final TextEditingController _r2Controller = TextEditingController(text: '0');
  final TextEditingController _r1Controller = TextEditingController(text: '0');
  final TextEditingController _50cController = TextEditingController(text: '0');

  bool _isSaving = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _r5Controller.dispose();
    _r2Controller.dispose();
    _r1Controller.dispose();
    _50cController.dispose();
    super.dispose();
  }

  /// Calculate total coins
  double _calculateCoins() {
    final r5 = double.tryParse(_r5Controller.text.trim()) ?? 0.0;
    final r2 = double.tryParse(_r2Controller.text.trim()) ?? 0.0;
    final r1 = double.tryParse(_r1Controller.text.trim()) ?? 0.0;
    final c50 = double.tryParse(_50cController.text.trim()) ?? 0.0;
    return r5 + r2 + r1 + c50;
  }

  /// Calculate total
  double _calculateTotal() {
    final notes = double.tryParse(_notesController.text.trim()) ?? 0.0;
    return notes + _calculateCoins();
  }

  /// Calculate percentage
  String _getPercentageBreakdown() {
    final total = _calculateTotal();
    if (total == 0) return '';
    
    final notes = double.tryParse(_notesController.text.trim()) ?? 0.0;
    final coins = _calculateCoins();
    
    final notesPercent = ((notes / total) * 100).toStringAsFixed(0);
    final coinsPercent = ((coins / total) * 100).toStringAsFixed(0);
    
    return '$notesPercent% Notes | $coinsPercent% Coins';
  }

  /// Save income
  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final income = Income(
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        notes: double.parse(_notesController.text.trim()),
        amountR5: double.tryParse(_r5Controller.text.trim()) ?? 0.0,
        amountR2: double.tryParse(_r2Controller.text.trim()) ?? 0.0,
        amountR1: double.tryParse(_r1Controller.text.trim()) ?? 0.0,
        amount50c: double.tryParse(_50cController.text.trim()) ?? 0.0,
      );

      await _dbHelper.insertIncome(income);

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
            content: Text('Error recording income: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildCoinField({
    required String label,
    required TextEditingController controller,
    required String denomination,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: '0.00',
              prefixText: 'R ',
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final amount = double.tryParse(value.trim());
              if (amount == null || amount < 0) {
                return 'Invalid';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            denomination,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCoins = _calculateCoins();
    final total = _calculateTotal();
    
    return AlertDialog(
      title: const Text('Record Income'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Daily sales',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Paper Money)',
                  hintText: '0.00',
                  prefixText: 'R ',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter notes amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Coins Section Header
              const Text(
                'Coins Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              // Coin denomination fields
              _buildCoinField(
                label: 'R5 coins',
                controller: _r5Controller,
                denomination: 'R5',
              ),
              const SizedBox(height: 8),
              _buildCoinField(
                label: 'R2 coins',
                controller: _r2Controller,
                denomination: 'R2',
              ),
              const SizedBox(height: 8),
              _buildCoinField(
                label: 'R1 coins',
                controller: _r1Controller,
                denomination: 'R1',
              ),
              const SizedBox(height: 8),
              _buildCoinField(
                label: '50c coins',
                controller: _50cController,
                denomination: 'R0.50',
              ),
              const SizedBox(height: 16),

              // Total Coins Display
              if (totalCoins > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Coins:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _currencyFormat.format(totalCoins),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Total Preview
              if (_notesController.text.isNotEmpty &&
                  double.tryParse(_notesController.text) != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            _currencyFormat.format(total),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      if (totalCoins > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getPercentageBreakdown(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.successGreen.withOpacity(0.8),
                          ),
                        ),
                      ],
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
          onPressed: _isSaving ? null : _saveIncome,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Record'),
        ),
      ],
    );
  }
}
