import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// Add/Edit License Dialog
/// 
/// Dialog to add or update a driver's license.

class AddEditLicenseDialog extends StatefulWidget {
  final int employeeId;
  final DriverLicense? license; // null = add, not null = edit

  const AddEditLicenseDialog({
    Key? key,
    required this.employeeId,
    this.license,
  }) : super(key: key);

  @override
  State<AddEditLicenseDialog> createState() => _AddEditLicenseDialogState();
}

class _AddEditLicenseDialogState extends State<AddEditLicenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _licenseNumberController;
  late TextEditingController _restrictionsController;

  String _selectedLicenseType = 'Code 8';
  List<String> _selectedLicenseTypes = [];
  DateTime? _issueDate;
  DateTime? _expiryDate;

  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  final List<String> _availableLicenseTypes = [
    'Code 8',
    'Code 10',
    'Code 14',
  ];

  final List<String> _availableSubTypes = [
    'A',
    'A1',
    'B',
    'C',
    'C1',
    'EB',
    'EC',
    'EC1',
  ];

  @override
  void initState() {
    super.initState();
    _licenseNumberController = TextEditingController(
      text: widget.license?.licenseNumber ?? '',
    );
    _restrictionsController = TextEditingController(
      text: widget.license?.restrictions ?? '',
    );

    if (widget.license != null) {
      _selectedLicenseType = widget.license!.licenseType;
      _issueDate = widget.license!.issueDate;
      _expiryDate = widget.license!.expiryDate;
      
      if (widget.license!.licenseTypes != null) {
        _selectedLicenseTypes = widget.license!.licenseTypes!
            .split(',')
            .map((e) => e.trim())
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  Future<void> _saveLicense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_issueDate == null) {
      _showError('Please select issue date');
      return;
    }

    if (_expiryDate == null) {
      _showError('Please select expiry date');
      return;
    }

    if (_expiryDate!.isBefore(_issueDate!)) {
      _showError('Expiry date must be after issue date');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final license = DriverLicense(
        id: widget.license?.id,
        employeeId: widget.employeeId,
        licenseNumber: _licenseNumberController.text.trim(),
        licenseType: _selectedLicenseType,
        licenseTypes: _selectedLicenseTypes.isEmpty
            ? null
            : _selectedLicenseTypes.join(', '),
        issueDate: _issueDate!,
        expiryDate: _expiryDate!,
        restrictions: _restrictionsController.text.trim().isEmpty
            ? null
            : _restrictionsController.text.trim(),
        createdAt: widget.license?.createdAt,
      );

      if (widget.license == null) {
        await _dbHelper.insertDriverLicense(license);
      } else {
        await _dbHelper.updateDriverLicense(license);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        _showError('Error saving license: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  Future<void> _selectDate(bool isIssueDate) async {
    final initialDate = isIssueDate
        ? (_issueDate ?? DateTime.now())
        : (_expiryDate ?? DateTime.now().add(const Duration(days: 365 * 5)));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isIssueDate ? DateTime(1970) : DateTime.now(),
      lastDate: DateTime(2100),
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

    if (date != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = date;
        } else {
          _expiryDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.license != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit License' : 'Add License'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // License Number
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  hintText: 'e.g., 123456789',
                  prefixIcon: Icon(Icons.badge),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter license number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Primary License Type
              DropdownButtonFormField<String>(
                value: _selectedLicenseType,
                decoration: const InputDecoration(
                  labelText: 'License Type',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                items: _availableLicenseTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLicenseType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Additional License Types
              Text(
                'Additional Types (Optional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSubTypes.map((type) {
                  final isSelected = _selectedLicenseTypes.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLicenseTypes.add(type);
                        } else {
                          _selectedLicenseTypes.remove(type);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryBrown,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.darkBrown,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Issue Date
              InkWell(
                onTap: () => _selectDate(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Issue Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _issueDate == null
                        ? 'Select issue date'
                        : _dateFormat.format(_issueDate!),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Expiry Date
              InkWell(
                onTap: () => _selectDate(false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    suffixStyle: TextStyle(
                      color: _expiryDate != null &&
                              _expiryDate!.isBefore(
                                DateTime.now().add(const Duration(days: 90)),
                              )
                          ? AppTheme.errorRed
                          : null,
                    ),
                  ),
                  child: Text(
                    _expiryDate == null
                        ? 'Select expiry date'
                        : _dateFormat.format(_expiryDate!),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _expiryDate != null &&
                                  _expiryDate!.isBefore(
                                    DateTime.now().add(const Duration(days: 90)),
                                  )
                              ? AppTheme.errorRed
                              : null,
                        ),
                  ),
                ),
              ),

              // Expiry warning
              if (_expiryDate != null &&
                  _expiryDate!.isBefore(
                    DateTime.now().add(const Duration(days: 90)),
                  )) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'License expiring soon!',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Restrictions
              TextFormField(
                controller: _restrictionsController,
                decoration: const InputDecoration(
                  labelText: 'Restrictions (Optional)',
                  hintText: 'e.g., Glasses required',
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveLicense,
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