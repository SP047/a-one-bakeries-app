import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/services/photo_picker_service.dart';
import 'package:a_one_bakeries_app/widgets/employee_photo_widget.dart';
import 'package:a_one_bakeries_app/widgets/upload_document_dialog.dart';
import 'package:a_one_bakeries_app/screens/pdf_viewer_screen.dart';
import 'package:a_one_bakeries_app/widgets/edit_credit_transaction_dialog.dart';
import 'dart:io';
import 'package:intl/intl.dart';

/// Employee Details Screen
/// 
/// Shows comprehensive employee information including:
/// - Personal details
/// - Credit account with transaction history
/// - Uploaded documents (contracts, payslips, disciplinary)

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  // Current employee (can be updated)
  late Employee _currentEmployee;

  // Credit account data
  double _creditBalance = 0.0;
  List<CreditTransaction> _transactions = [];
  bool _isLoadingCredit = true;

  // Documents data
  List<EmployeeDocument> _documents = [];
  bool _isLoadingDocuments = true;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');

  @override
  void initState() {
    super.initState();
    _currentEmployee = widget.employee;
    _tabController = TabController(length: 3, vsync: this);
    _loadCreditData();
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load credit account data
  Future<void> _loadCreditData() async {
    setState(() {
      _isLoadingCredit = true;
    });

    try {
      final balance =
          await _dbHelper.getEmployeeCreditBalance(_currentEmployee.id!);
      final transactions = await _dbHelper
          .getCreditTransactionsByEmployeeId(_currentEmployee.id!);

      setState(() {
        _creditBalance = balance;
        _transactions = transactions;
        _isLoadingCredit = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCredit = false;
      });
    }
  }

  /// Load employee documents
  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
    });

    try {
      final documents =
          await _dbHelper.getEmployeeDocuments(_currentEmployee.id!);

      setState(() {
        _documents = documents;
        _isLoadingDocuments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDocuments = false;
      });
    }
  }

  /// Show add credit transaction dialog
  Future<void> _showAddTransactionDialog(String type) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'BORROW' ? 'Record Borrowed Money' : 'Record Repayment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'R ',
                  prefixIcon: Icon(Icons.money),
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
              TextFormField(
                controller: reasonController,
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final transaction = CreditTransaction(
                    employeeId: _currentEmployee.id!,
                    employeeName: _currentEmployee.fullName,
                    transactionType: type,
                    amount: double.parse(amountController.text.trim()),
                    reason: reasonController.text.trim(),
                  );

                  await _dbHelper.insertCreditTransaction(transaction);
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadCreditData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'BORROW'
                ? 'Borrowed amount recorded'
                : 'Repayment recorded'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  /// Show upload document dialog
  Future<void> _showUploadDocumentDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UploadDocumentDialog(
        employeeId: _currentEmployee.id!,
      ),
    );

    if (result == true) {
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Handle photo tap - show options to add/change/remove
  Future<void> _handlePhotoTap() async {
    final photoService = PhotoPickerService();
    final newPhotoPath = await photoService.showPhotoOptions(
      context,
      _currentEmployee.photoPath,
    );

    // If null, user cancelled
    if (newPhotoPath == null) return;

    // Update employee in database
    final updatedEmployee = _currentEmployee.copyWith(
      photoPath: newPhotoPath.isEmpty ? null : newPhotoPath,
    );

    try {
      await _dbHelper.updateEmployee(updatedEmployee);
      
      // Update local state
      setState(() {
        _currentEmployee = updatedEmployee;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newPhotoPath.isEmpty 
                ? 'Photo removed' 
                : 'Photo updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(_currentEmployee.fullName),
      ),
      body: Column(
        children: [
          // Employee Header Card
          _buildEmployeeHeader(),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBrown,
            unselectedLabelColor: AppTheme.darkBrown.withOpacity(0.5),
            indicatorColor: AppTheme.primaryBrown,
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Credit'),
              Tab(text: 'Documents'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildCreditTab(),
                _buildDocumentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build employee header
  Widget _buildEmployeeHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBrown,
            AppTheme.primaryBrown.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Employee Photo with edit option
          GestureDetector(
            onTap: _handlePhotoTap,
            child: Stack(
              children: [
                EmployeePhotoWidget(
                  photoPath: _currentEmployee.photoPath,
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBrown,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _currentEmployee.photoPath == null || _currentEmployee.photoPath!.isEmpty
                          ? Icons.add_a_photo
                          : Icons.edit,
                      size: 16,
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Employee Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentEmployee.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentEmployee.role,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentEmployee.age} years old',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build details tab
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('ID Type', _currentEmployee.idType),
          _buildDetailRow('ID Number', _currentEmployee.idNumber),
          _buildDetailRow(
              'Birth Date', DateFormat('dd MMM yyyy').format(_currentEmployee.birthDate)),
          _buildDetailRow('Age', '${_currentEmployee.age} years'),
          _buildDetailRow('Role', _currentEmployee.role),
          _buildDetailRow('Registered',
              DateFormat('dd MMM yyyy').format(_currentEmployee.createdAt)),
        ],
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.7),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build credit tab
  Widget _buildCreditTab() {
    return Column(
      children: [
        // Credit Balance Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _creditBalance > 0 ? AppTheme.errorRed : AppTheme.successGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Current Balance',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(_creditBalance),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddTransactionDialog('BORROW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.errorRed,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Borrow'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddTransactionDialog('REPAY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.successGreen,
                      ),
                      icon: const Icon(Icons.remove),
                      label: const Text('Repay'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: _isLoadingCredit
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.darkBrown.withOpacity(0.5),
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(_transactions[index]);
                      },
                    ),
        ),
      ],
    );
  }

  /// Build transaction card - UPDATED with edit/delete
Widget _buildTransactionCard(CreditTransaction transaction) {
  final isBorrow = transaction.transactionType == 'BORROW';
  final color = isBorrow ? AppTheme.errorRed : AppTheme.successGreen;

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isBorrow ? Icons.add_circle : Icons.remove_circle,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBorrow ? 'Borrowed' : 'Repaid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${isBorrow ? '+' : '-'}${_currencyFormat.format(transaction.amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // Edit/Delete Menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTransaction(transaction);
                      } else if (value == 'delete') {
                        _deleteTransaction(transaction);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transaction.reason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _dateFormat.format(transaction.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.6),
                ),
          ),
        ],
      ),
    ),
  );
}

/// Edit transaction - NEW METHOD
Future<void> _editTransaction(CreditTransaction transaction) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => EditCreditTransactionDialog(
      transaction: transaction,
    ),
  );

  if (result == true) {
    _loadCreditData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully!'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Delete transaction - NEW METHOD
Future<void> _deleteTransaction(CreditTransaction transaction) async {
  final isBorrow = transaction.transactionType == 'BORROW';
  
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete this ${isBorrow ? 'borrowed' : 'repayment'} transaction?',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ${_currencyFormat.format(transaction.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Reason: ${transaction.reason}'),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_dateFormat.format(transaction.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.secondaryOrange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will update the credit balance',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorRed,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      await _dbHelper.deleteCreditTransaction(transaction.id!);
      _loadCreditData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully!'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}

  /// Build documents tab
  Widget _buildDocumentsTab() {
    return Column(
      children: [
        // Upload Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showUploadDocumentDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Document'),
          ),
        ),

        // Documents List
        Expanded(
          child: _isLoadingDocuments
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 80,
                            color: AppTheme.darkBrown.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: AppTheme.darkBrown.withOpacity(0.5),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        return _buildDocumentCard(_documents[index]);
                      },
                    ),
        ),
      ],
    );
  }

/// Build document card
Widget _buildDocumentCard(EmployeeDocument document) {
  IconData icon;
  Color color;

  switch (document.documentType) {
    case 'CONTRACT':
      icon = Icons.description;
      color = Colors.blue;
      break;
    case 'PAYSLIP':
      icon = Icons.receipt;
      color = Colors.green;
      break;
    case 'DISCIPLINARY':
      icon = Icons.warning;
      color = Colors.orange;
      break;
    case 'ID':
      icon = Icons.badge;
      color = Colors.purple;
      break;
    case 'OTHER':
      icon = Icons.insert_drive_file;
      color = Colors.grey;
      break;
    default:
      icon = Icons.insert_drive_file;
      color = AppTheme.primaryBrown;
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(document.fileName),
      subtitle: Text(
        '${_formatDocumentType(document.documentType)} • ${_dateFormat.format(document.uploadedAt)}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'view') {
            _viewDocument(document);
          } else if (value == 'delete') {
            _deleteDocument(document);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 8),
                Text('View'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
              ],
            ),
          ),
        ],
      ),
    ),
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
      return 'Disciplinary';
    case 'ID':
      return 'ID Document';  
    case 'OTHER':
      return 'Other';
    default:
      return type;
  }
}

void _viewDocument(EmployeeDocument document) async {
  // Check if file exists
  final file = File(document.filePath);
  if (!await file.exists()) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Not Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The document file could not be found. It may have been moved or deleted.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File: ${document.fileName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Path: ${document.filePath}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDocument(document);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
              ),
              child: const Text('Delete Record'),
            ),
          ],
        ),
      );
    }
    return;
  }

  // File exists - open PDF viewer
  try {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          filePath: document.filePath,
          fileName: document.fileName,
        ),
      ),
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}

/// Delete document
Future<void> _deleteDocument(EmployeeDocument document) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Document'),
      content: Text('Are you sure you want to delete "${document.fileName}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorRed,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      // Delete from database
      await _dbHelper.deleteEmployeeDocument(document.id!);
      
      // Optionally delete the actual file
      try {
        final file = File(document.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // File deletion failed, but database record is deleted
        debugPrint('Failed to delete file: $e');
      }

      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully!'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting document: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
}