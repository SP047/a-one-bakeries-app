import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/models/km_record_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Dialog for adding a new KM record
class AddKmRecordDialog extends StatefulWidget {
  final Vehicle vehicle;

  const AddKmRecordDialog({
    super.key,
    required this.vehicle,
  });

  @override
  State<AddKmRecordDialog> createState() => _AddKmRecordDialogState();
}

class _AddKmRecordDialogState extends State<AddKmRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _notesController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  
  DateTime _recordedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current KM + 1
    _kmController.text = (widget.vehicle.currentKm + 1).toString();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _recordedDate = picked;
      });
    }
  }

  Future<void> _saveKmRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final kmReading = int.parse(_kmController.text);
      
      final record = KmRecord(
        vehicleId: widget.vehicle.id!,
        kmReading: kmReading,
        recordedDate: _recordedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await _dbHelper.addKmRecord(record);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving KM record: $e'),
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
    final kmTraveled = int.tryParse(_kmController.text) != null
        ? int.parse(_kmController.text) - widget.vehicle.currentKm
        : 0;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.speed, color: AppTheme.primaryBrown),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Record KM - ${widget.vehicle.fullName}',
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
              // Current KM Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current KM:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${widget.vehicle.currentKm} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // New KM Reading
              TextFormField(
                controller: _kmController,
                decoration: const InputDecoration(
                  labelText: 'New KM Reading *',
                  hintText: 'Enter odometer reading',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter KM reading';
                  }
                  final km = int.tryParse(value);
                  if (km == null) {
                    return 'Please enter a valid number';
                  }
                  if (km <= widget.vehicle.currentKm) {
                    return 'New KM must be greater than current (${widget.vehicle.currentKm})';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Rebuild to update KM traveled
                },
              ),
              const SizedBox(height: 8),

              // KM Traveled Display
              if (kmTraveled > 0)
                Text(
                  'KM Traveled: $kmTraveled km',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Recorded Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_dateFormat.format(_recordedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any notes',
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
          onPressed: _isLoading ? null : _saveKmRecord,
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
