import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// Add/Edit Employee Dialog
/// 
/// A dialog form to register a new employee or edit an existing one.
/// Collects: name, ID number, birth date, and role.

class AddEditEmployeeDialog extends StatefulWidget {
  final Employee? employee; // null = add new, not null = edit existing

  const AddEditEmployeeDialog({
    super.key,
    this.employee,
  });

  @override
  State<AddEditEmployeeDialog> createState() => _AddEditEmployeeDialogState();
}

class _AddEditEmployeeDialogState extends State<AddEditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _idNumberController;

  String _selectedIdType = 'ID';
  String _selectedRole = EmployeeRoles.baker;
  DateTime? _selectedBirthDate;

  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values if editing
    _firstNameController =
        TextEditingController(text: widget.employee?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.employee?.lastName ?? '');
    _idNumberController =
        TextEditingController(text: widget.employee?.idNumber ?? '');

    if (widget.employee != null) {
      _selectedIdType = widget.employee!.idType;
      _selectedRole = widget.employee!.role;
      _selectedBirthDate = widget.employee!.birthDate;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  /// Save employee to database
  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select birth date'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final employee = Employee(
        id: widget.employee?.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        idType: _selectedIdType,
        birthDate: _selectedBirthDate!,
        role: _selectedRole,
        photoPath: widget.employee?.photoPath,
        createdAt: widget.employee?.createdAt,
      );

      if (widget.employee == null) {
        // Add new employee
        await _dbHelper.insertEmployee(employee);
      } else {
        // Update existing employee
        await _dbHelper.updateEmployee(employee);
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
            content: Text('Error saving employee: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  /// Show date picker
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
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
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Employee' : 'Register Employee'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First Name Field
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Enter first name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name Field
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Enter last name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ID Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedIdType,
                decoration: const InputDecoration(
                  labelText: 'ID Type',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: 'ID', child: Text('SA ID Number')),
                  DropdownMenuItem(
                      value: 'PASSPORT', child: Text('Passport Number')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedIdType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // ID Number Field
              TextFormField(
                controller: _idNumberController,
                decoration: InputDecoration(
                  labelText: _selectedIdType == 'ID'
                      ? 'SA ID Number'
                      : 'Passport Number',
                  hintText: _selectedIdType == 'ID'
                      ? '0000000000000'
                      : 'A00000000',
                  prefixIcon: const Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter ID/Passport number';
                  }
                  if (_selectedIdType == 'ID' && value.trim().length != 13) {
                    return 'SA ID must be 13 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Birth Date Field
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birth Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedBirthDate == null
                        ? 'Select birth date'
                        : _dateFormat.format(_selectedBirthDate!),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.work),
                ),
                items: EmployeeRoles.allRoles
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Age Preview (if birth date selected)
              if (_selectedBirthDate != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cake,
                        color: AppTheme.primaryBrown,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Age: ${_calculateAge(_selectedBirthDate!)} years old',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryBrown,
                              fontWeight: FontWeight.w600,
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
          onPressed: _isSaving ? null : _saveEmployee,
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

  /// Calculate age from birth date
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}