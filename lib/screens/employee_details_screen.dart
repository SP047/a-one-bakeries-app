import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
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
          await _dbHelper.getEmployeeCreditBalance(widget.employee.id!);
      final transactions = await _dbHelper
          .getCreditTransactionsByEmployeeId(widget.employee.id!);

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
          await _dbHelper.getEmployeeDocuments(widget.employee.id!);

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
                    employeeId: widget.employee.id!,
                    employeeName: widget.employee.fullName,
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

  /// Show upload document dialog (placeholder for now)
  Future<void> _showUploadDocumentDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text(
            'Document upload feature will be fully implemented with file picker.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(widget.employee.fullName),
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
          // Employee Photo
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: widget.employee.photoPath != null
                ? ClipOval(
                    child: Image.network(
                      widget.employee.photoPath!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 40);
                      },
                    ),
                  )
                : const Icon(Icons.person, size: 40),
          ),
          const SizedBox(width: 16),

          // Employee Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.employee.role,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.employee.age} years old',
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
          _buildDetailRow('ID Type', widget.employee.idType),
          _buildDetailRow('ID Number', widget.employee.idNumber),
          _buildDetailRow(
              'Birth Date', DateFormat('dd MMM yyyy').format(widget.employee.birthDate)),
          _buildDetailRow('Age', '${widget.employee.age} years'),
          _buildDetailRow('Role', widget.employee.role),
          _buildDetailRow('Registered',
              DateFormat('dd MMM yyyy').format(widget.employee.createdAt)),
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

  /// Build transaction card
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
                Text(
                  isBorrow ? 'Borrowed' : 'Repaid',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${isBorrow ? '+' : '-'}${_currencyFormat.format(transaction.amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
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
          '${document.documentType} • ${_dateFormat.format(document.uploadedAt)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show document options (view, delete)
          },
        ),
      ),
    );
  }
}
