import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'dart:io';

/// Upload Document Dialog
/// 
/// Allows uploading PDF documents for employees.
/// Categories: Contract, Payslip, Disciplinary

class UploadDocumentDialog extends StatefulWidget {
  final int employeeId;

  const UploadDocumentDialog({
    super.key,
    required this.employeeId,
  });

  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  String _selectedDocType = 'CONTRACT';
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isUploading = false;

  final List<String> _documentTypes = [
    'CONTRACT',
    'PAYSLIP',
    'DISCIPLINARY',
    'ID',
    'OTHER',
  ];

  /// Pick a PDF file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  /// Upload document to database
  Future<void> _uploadDocument() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Create document record
      final document = EmployeeDocument(
        employeeId: widget.employeeId,
        documentType: _selectedDocType,
        fileName: _selectedFileName!,
        filePath: _selectedFilePath!,
      );

      // Save to database
      await _dbHelper.insertEmployeeDocument(document);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Document'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Type Dropdown
            Text(
              'Document Type',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedDocType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.description),
                isDense: true,
              ),
              items: _documentTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_formatDocumentType(type)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDocType = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // File Selection
            Text(
              'Select File',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Choose PDF File'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            // Selected File Display
            if (_selectedFileName != null) ...[
              const SizedBox(height: 12),
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
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Info message
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
                      'Only PDF files are supported',
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
      actions: [
        // Cancel Button
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        // Upload Button
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _uploadDocument,
          icon: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.upload_file),
          label: Text(_isUploading ? 'Uploading...' : 'Upload'),
        ),
      ],
    );
  }

  /// Format document type for display
  String _formatDocumentType(String type) {
    switch (type) {
      case 'CONTRACT':
        return 'Contract';
      case 'PAYSLIP':
        return 'Payslip';
      case 'DISCIPLINARY':
        return 'Disciplinary Record';
      case 'ID':
        return 'ID Document';
      case 'OTHER':
        return 'Other';    
      default:
        return type;
    }
  }
}