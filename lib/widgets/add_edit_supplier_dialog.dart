import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/supplier_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';

/// Add/Edit Supplier Dialog
/// 
/// Dialog to add a new supplier or edit an existing one.

class AddEditSupplierDialog extends StatefulWidget {
  final Supplier? supplier;

  const AddEditSupplierDialog({
    super.key,
    this.supplier,
  });

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _contactPersonController =
        TextEditingController(text: widget.supplier?.contactPerson ?? '');
    _phoneController =
        TextEditingController(text: widget.supplier?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
    _addressController =
        TextEditingController(text: widget.supplier?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final supplier = Supplier(
        id: widget.supplier?.id,
        name: _nameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        createdAt: widget.supplier?.createdAt,
      );

      if (widget.supplier == null) {
        await _dbHelper.insertSupplier(supplier);
      } else {
        await _dbHelper.updateSupplier(supplier);
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
            content: Text('Error saving supplier: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Supplier' : 'Add Supplier'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Supplier Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name',
                  hintText: 'e.g., ABC Suppliers',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter supplier name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Person
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  hintText: 'e.g., John Doe',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter contact person';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g., 0123456789',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (Optional)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'e.g., supplier@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Address (Optional)
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'e.g., 123 Main Street',
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
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
          onPressed: _isSaving ? null : _saveSupplier,
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