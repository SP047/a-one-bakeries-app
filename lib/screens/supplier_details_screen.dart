import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/supplier_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// Supplier Details Screen
/// 
/// Shows supplier information, invoices, payments, and balance.

class SupplierDetailsScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({
    super.key,
    required this.supplier,
  });

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  double _totalInvoices = 0.0;
  double _totalPayments = 0.0;
  double _balance = 0.0;
  List<SupplierInvoice> _invoices = [];
  List<SupplierPayment> _payments = [];
  bool _isLoading = true;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoices = await _dbHelper.getSupplierInvoices(widget.supplier.id!);
      final payments = await _dbHelper.getSupplierPayments(widget.supplier.id!);
      final balance = await _dbHelper.getSupplierBalance(widget.supplier.id!);
      final totalInv = await _dbHelper.getTotalInvoices(widget.supplier.id!);
      final totalPay = await _dbHelper.getTotalPayments(widget.supplier.id!);

      setState(() {
        _invoices = invoices;
        _payments = payments;
        _balance = balance;
        _totalInvoices = totalInv;
        _totalPayments = totalPay;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Show add invoice dialog
  Future<void> _showAddInvoiceDialog() async {
    final invoiceNumberController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    DateTime? dueDate;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Invoice'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: invoiceNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number',
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter invoice number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'R ',
                      prefixIcon: Icon(Icons.money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  ListTile(
                    title: const Text('Invoice Date'),
                    subtitle: Text(_dateFormat.format(selectedDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Due Date (Optional)'),
                    subtitle: Text(dueDate != null
                        ? _dateFormat.format(dueDate!)
                        : 'Not set'),
                    leading: const Icon(Icons.event),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          dueDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final invoice = SupplierInvoice(
                      supplierId: widget.supplier.id!,
                      supplierName: widget.supplier.name,
                      invoiceNumber: invoiceNumberController.text.trim(),
                      amount: double.parse(amountController.text.trim()),
                      invoiceDate: selectedDate,
                      dueDate: dueDate,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    await _dbHelper.insertSupplierInvoice(invoice);
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
      ),
    );

    if (result == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice added successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  /// Show add payment dialog
  Future<void> _showAddPaymentDialog() async {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedMethod = PaymentMethods.cash;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Form(
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
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: PaymentMethods.allMethods
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference (Optional)',
                      hintText: 'e.g., Cheque number, EFT reference',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Payment Date'),
                    subtitle: Text(_dateFormat.format(selectedDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final payment = SupplierPayment(
                      supplierId: widget.supplier.id!,
                      supplierName: widget.supplier.name,
                      amount: double.parse(amountController.text.trim()),
                      paymentMethod: selectedMethod,
                      reference: referenceController.text.trim().isEmpty
                          ? null
                          : referenceController.text.trim(),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      paymentDate: selectedDate,
                    );

                    await _dbHelper.insertSupplierPayment(payment);
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
      ),
    );

    if (result == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully!'),
            backgroundColor: AppTheme.successGreen,
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
        title: Text(widget.supplier.name),
      ),
      body: Column(
        children: [
          // Supplier Header
          _buildSupplierHeader(),

          // Account Summary
          _buildAccountSummary(),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBrown,
            unselectedLabelColor: AppTheme.darkBrown.withOpacity(0.5),
            indicatorColor: AppTheme.primaryBrown,
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Invoices'),
              Tab(text: 'Payments'),
            ],
          ),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(),
                      _buildInvoicesTab(),
                      _buildPaymentsTab(),
                    ],
                  ),
          ),
        ],
      ),
      // FIXED: Show FAB based on current tab
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          // Hide FAB on Details tab (index 0)
          if (_tabController.index == 0) {
            return const SizedBox.shrink();
          }
          
          // Show appropriate FAB for Invoices or Payments tab
          return FloatingActionButton.extended(
            onPressed: _tabController.index == 1
                ? _showAddInvoiceDialog
                : _showAddPaymentDialog,
            icon: const Icon(Icons.add),
            label: Text(_tabController.index == 1 ? 'Add Invoice' : 'Add Payment'),
          );
        },
      ),
    );
  }

  Widget _buildSupplierHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business,
              size: 32,
              color: AppTheme.primaryBrown,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.supplier.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.supplier.contactPerson,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.supplier.phoneNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _balance > 0
              ? [AppTheme.errorRed, AppTheme.errorRed.withOpacity(0.8)]
              : [AppTheme.successGreen, AppTheme.successGreen.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Balance Owed',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_balance),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 32, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Total Invoices',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(_totalInvoices),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Container(height: 40, width: 1, color: Colors.white24),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Total Payments',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(_totalPayments),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Contact Person', widget.supplier.contactPerson),
          _buildDetailRow('Phone', widget.supplier.phoneNumber),
          if (widget.supplier.email != null)
            _buildDetailRow('Email', widget.supplier.email!),
          if (widget.supplier.address != null)
            _buildDetailRow('Address', widget.supplier.address!),
        ],
      ),
    );
  }

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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return _invoices.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 80,
                  color: AppTheme.darkBrown.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No invoices yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.5),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Add Invoice" to get started',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _invoices.length,
            itemBuilder: (context, index) {
              return _buildInvoiceCard(_invoices[index]);
            },
          );
  }

  Widget _buildInvoiceCard(SupplierInvoice invoice) {
    final isOverdue = invoice.dueDate != null && 
        invoice.dueDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with invoice number and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Invoice #${invoice.invoiceNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  _currencyFormat.format(invoice.amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Invoice date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Date: ${_dateFormat.format(invoice.invoiceDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            // Due date (if set)
            if (invoice.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning : Icons.event,
                    size: 16,
                    color: isOverdue ? AppTheme.errorRed : null,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_dateFormat.format(invoice.dueDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOverdue ? AppTheme.errorRed : null,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Notes (if present)
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.creamBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        invoice.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return _payments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 80,
                  color: AppTheme.darkBrown.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No payments yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.5),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Add Payment" to get started',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(_payments[index]);
            },
          );
  }

  Widget _buildPaymentCard(SupplierPayment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with payment method and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getPaymentMethodIcon(payment.paymentMethod),
                      size: 20,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      payment.paymentMethod,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Text(
                  _currencyFormat.format(payment.amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  _dateFormat.format(payment.paymentDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            // Reference (if present)
            if (payment.reference != null && payment.reference!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.confirmation_number, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Ref: ${payment.reference}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],

            // Notes (if present)
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.creamBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        payment.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case PaymentMethods.cash:
        return Icons.money;
      case PaymentMethods.eft:
        return Icons.account_balance;
      case PaymentMethods.cheque:
        return Icons.check_circle;
      default:
        return Icons.payment;
    }
  }
}