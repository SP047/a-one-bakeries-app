import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/vehicle_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// Add/Edit Vehicle Dialog
/// 
/// A dialog form to register a new vehicle or edit an existing one.
/// Collects: make, model, year, and registration number.

class AddEditVehicleDialog extends StatefulWidget {
  final Vehicle? vehicle; // null = add new, not null = edit existing

  const AddEditVehicleDialog({
    super.key,
    this.vehicle,
  });

  @override
  State<AddEditVehicleDialog> createState() => _AddEditVehicleDialogState();
}

class _AddEditVehicleDialogState extends State<AddEditVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _registrationController;
  late TextEditingController _diskNumberController;

  DateTime? _licenseDiskExpiry;
  DateTime? _lastRenewalDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values if editing
    _makeController = TextEditingController(text: widget.vehicle?.make ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController =
        TextEditingController(text: widget.vehicle?.year.toString() ?? '');
    _registrationController =
        TextEditingController(text: widget.vehicle?.registrationNumber ?? '');
    _diskNumberController =
        TextEditingController(text: widget.vehicle?.diskNumber ?? '');
    
    // Initialize date fields
    _licenseDiskExpiry = widget.vehicle?.licenseDiskExpiry;
    _lastRenewalDate = widget.vehicle?.lastRenewalDate;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _registrationController.dispose();
    _diskNumberController.dispose();
    super.dispose();
  }

  /// Save vehicle to database
  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final vehicle = Vehicle(
        id: widget.vehicle?.id,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        registrationNumber: _registrationController.text.trim().toUpperCase(),
        assignedDriverId: widget.vehicle?.assignedDriverId,
        assignedDriverName: widget.vehicle?.assignedDriverName,
        licenseDiskExpiry: _licenseDiskExpiry,
        lastRenewalDate: _lastRenewalDate,
        diskNumber: _diskNumberController.text.trim().isEmpty 
            ? null 
            : _diskNumberController.text.trim(),
        createdAt: widget.vehicle?.createdAt,
      );

      if (widget.vehicle == null) {
        // Add new vehicle
        await _dbHelper.insertVehicle(vehicle);
      } else {
        // Update existing vehicle
        await _dbHelper.updateVehicle(vehicle);
      }

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
            content: Text('Error saving vehicle: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Vehicle' : 'Register Vehicle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Make Field
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  hintText: 'e.g., Toyota, Ford, Isuzu',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle make';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Model Field
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g., Hilux, Ranger, NPR',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Year Field
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: 'e.g., 2020',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter year';
                  }
                  final year = int.tryParse(value.trim());
                  if (year == null) {
                    return 'Please enter valid year';
                  }
                  final currentYear = DateTime.now().year;
                  if (year < 1900 || year > currentYear + 1) {
                    return 'Please enter valid year (1900-${currentYear + 1})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Registration Number Field
              TextFormField(
                controller: _registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'e.g., ABC 123 GP',
                  prefixIcon: Icon(Icons.pin),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter registration number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // License Disk Section Header
              Row(
                children: [
                  const Icon(Icons.credit_card, size: 20, color: AppTheme.secondaryOrange),
                  const SizedBox(width: 8),
                  Text(
                    'License Disk Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // License Disk Expiry Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _licenseDiskExpiry ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      _licenseDiskExpiry = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'License Disk Expiry Date',
                    prefixIcon: Icon(Icons.event),
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    _licenseDiskExpiry != null
                        ? '${_licenseDiskExpiry!.day}/${_licenseDiskExpiry!.month}/${_licenseDiskExpiry!.year}'
                        : 'Tap to select date (optional)',
                    style: TextStyle(
                      color: _licenseDiskExpiry != null 
                          ? AppTheme.darkBrown 
                          : AppTheme.darkBrown.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Last Renewal Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _lastRenewalDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _lastRenewalDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Last Renewal Date (Optional)',
                    prefixIcon: const Icon(Icons.history),
                    suffixIcon: _lastRenewalDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _lastRenewalDate = null;
                              });
                            },
                          )
                        : const Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    _lastRenewalDate != null
                        ? '${_lastRenewalDate!.day}/${_lastRenewalDate!.month}/${_lastRenewalDate!.year}'
                        : 'Tap to select date',
                    style: TextStyle(
                      color: _lastRenewalDate != null 
                          ? AppTheme.darkBrown 
                          : AppTheme.darkBrown.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Disk Number Field
              TextFormField(
                controller: _diskNumberController,
                decoration: const InputDecoration(
                  labelText: 'Disk Number (Optional)',
                  hintText: 'e.g., D123456',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Info about driver assignment
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.primaryBrown,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can assign a driver after registering',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
          onPressed: _isSaving ? null : _saveVehicle,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEditing ? 'Update' : 'Register'),
        ),
      ],
    );
  }
}