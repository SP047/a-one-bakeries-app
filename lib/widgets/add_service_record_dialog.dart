import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/models/service_record_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Dialog for adding a service record
class AddServiceRecordDialog extends StatefulWidget {
  final Vehicle vehicle;

  const AddServiceRecordDialog({
    super.key,
    required this.vehicle,
  });

  @override
  State<AddServiceRecordDialog> createState() => _AddServiceRecordDialogState();
}

class _AddServiceRecordDialogState extends State<AddServiceRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceKmController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');
  
  DateTime _serviceDate = DateTime.now();
  String _serviceType = ServiceTypes.regular;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current KM
    _serviceKmController.text = widget.vehicle.currentKm.toString();
  }

  @override
  void dispose() {
    _serviceKmController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _serviceDate = picked;
      });
    }
  }

  Future<void> _saveServiceRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final serviceKm = int.parse(_serviceKmController.text);
      final cost = _costController.text.trim().isEmpty 
          ? null 
          : double.parse(_costController.text);
      
      final record = ServiceRecord(
        vehicleId: widget.vehicle.id!,
        serviceKm: serviceKm,
        serviceDate: _serviceDate,
        serviceType: _serviceType,
        cost: cost,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await _dbHelper.addServiceRecord(record);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving service record: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.build, color: AppTheme.primaryBrown),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Record Service - ${widget.vehicle.fullName}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current KM:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${widget.vehicle.currentKm} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last Service:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${widget.vehicle.lastServiceKm} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service Interval:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${widget.vehicle.serviceIntervalKm} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Service Type
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: const InputDecoration(
                  labelText: 'Service Type *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: ServiceTypes.all.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _serviceType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Service KM
              TextFormField(
                controller: _serviceKmController,
                decoration: const InputDecoration(
                  labelText: 'Service KM *',
                  hintText: 'KM at service',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service KM';
                  }
                  final km = int.tryParse(value);
                  if (km == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Service Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_dateFormat.format(_serviceDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost (Optional)',
                  hintText: 'Service cost',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Service details',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveServiceRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBrown,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
