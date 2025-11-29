import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/finance_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/widgets/add_income_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_expense_dialog.dart';
import 'package:a_one_bakeries_app/screens/income_report_screen.dart';
import 'package:a_one_bakeries_app/screens/expense_report_screen.dart';
import 'package:a_one_bakeries_app/screens/financial_summary_screen.dart';
import 'package:a_one_bakeries_app/screens/cash_breakdown_screen.dart';
import 'package:intl/intl.dart';

/// Finance Screen
/// 
/// Main screen for income and expense management.
/// Displays a summary and tabs for Income and Expenses.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  // -------------------- STATE VARIABLES --------------------
  bool _isLoading = true;

  // Finance summary
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _moneyOnHand = 0.0;

  // Lists of records
  List<Income> _incomeList = [];
  List<Expense> _expensesList = [];

  // Formatters
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -------------------- DATA OPERATIONS --------------------

  /// Load all finance data and update summary
  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);

    try {
      final income = await _dbHelper.getAllIncome();
      final expenses = await _dbHelper.getAllExpenses();
      final totalIncome = await _dbHelper.getTotalIncome();
      final totalExpenses = await _dbHelper.getTotalExpenses();
      final moneyOnHand = await _dbHelper.getMoneyOnHand();

      setState(() {
        _incomeList = income;
        _expensesList = expenses;
        _totalIncome = totalIncome;
        _totalExpenses = totalExpenses;
        _moneyOnHand = moneyOnHand;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showErrorSnackBar('Error loading finance data: $e');
    }
  }

  /// Delete an income record after confirmation
  Future<void> _deleteIncome(Income income) async {
    final confirm = await _showConfirmationDialog(
      title: 'Delete Income',
      content: 'Delete income record of ${_currencyFormat.format(income.total)}?',
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteIncome(income.id!);
        _loadFinanceData();
        if (mounted) _showSuccessSnackBar('Income deleted!');
      } catch (e) {
        if (mounted) _showErrorSnackBar('Error deleting income: $e');
      }
    }
  }

  /// Delete an expense record after confirmation
  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await _showConfirmationDialog(
      title: 'Delete Expense',
      content: 'Delete expense: ${expense.description}?',
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteExpense(expense.id!);
        _loadFinanceData();
        if (mounted) _showSuccessSnackBar('Expense deleted!');
      } catch (e) {
        if (mounted) _showErrorSnackBar('Error deleting expense: $e');
      }
    }
  }

  /// Show a confirmation dialog (generic for delete)
  Future<bool?> _showConfirmationDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add new income
  Future<void> _showAddIncomeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddIncomeDialog(),
    );

    if (result == true) {
      _loadFinanceData();
      if (mounted) _showSuccessSnackBar('Income recorded successfully!');
    }
  }

  /// Show dialog to add new expense
  Future<void> _showAddExpenseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );

    if (result == true) {
      _loadFinanceData();
      if (mounted) _showSuccessSnackBar('Expense recorded successfully!');
    }
  }

  // -------------------- UI BUILDERS --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Income & Expenses'),
        actions: [
          // Cash Breakdown Button
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Cash Breakdown',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CashBreakdownScreen(),
                ),
              );
            },
          ),
          // Reports Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.assessment),
            tooltip: 'Reports',
            onSelected: (value) {
              if (value == 'income') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncomeReportScreen()),
                );
              } else if (value == 'expense') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseReportScreen()),
                );
              } else if (value == 'summary') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FinancialSummaryScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'income',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppTheme.successGreen),
                    SizedBox(width: 12),
                    Text('Income Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'expense',
                child: Row(
                  children: [
                    Icon(Icons.trending_down, color: AppTheme.errorRed),
                    SizedBox(width: 12),
                    Text('Expense Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'summary',
                child: Row(
                  children: [
                    Icon(Icons.assessment, color: AppTheme.primaryBrown),
                    SizedBox(width: 12),
                    Text('Financial Summary'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummarySection(),
                _buildTabBar(),
                _buildTabBarView(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddIncomeDialog();
          } else {
            _showAddExpenseDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build summary section showing Money on Hand, Total Income and Expenses
  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBrown, AppTheme.primaryBrown.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Money on Hand',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 8),
          Text(_currencyFormat.format(_moneyOnHand),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const Divider(height: 32, color: Colors.white24),
          Row(
            children: [
              _buildSummaryColumn('Total Income', _totalIncome, AppTheme.successGreen),
              Container(height: 40, width: 1, color: Colors.white24),
              _buildSummaryColumn('Total Expenses', _totalExpenses, AppTheme.errorRed),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper for summary column (Income/Expenses)
  Widget _buildSummaryColumn(String title, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(_currencyFormat.format(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Tab bar for Income and Expenses
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryBrown,
      unselectedLabelColor: AppTheme.darkBrown.withOpacity(0.5),
      indicatorColor: AppTheme.primaryBrown,
      tabs: const [
        Tab(text: 'Income'),
        Tab(text: 'Expenses'),
      ],
    );
  }

  /// Tab views
  Widget _buildTabBarView() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _incomeList.isEmpty
              ? _buildEmptyState('No income recorded yet', Icons.attach_money)
              : _buildIncomeList(),
          _expensesList.isEmpty
              ? _buildEmptyState('No expenses recorded yet', Icons.money_off)
              : _buildExpensesList(),
        ],
      ),
    );
  }

  /// Income list with RefreshIndicator
  Widget _buildIncomeList() {
    return RefreshIndicator(
      onRefresh: _loadFinanceData,
      color: AppTheme.primaryBrown,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incomeList.length,
        itemBuilder: (context, index) => _buildIncomeCard(_incomeList[index]),
      ),
    );
  }

  /// Expenses list with RefreshIndicator
  Widget _buildExpensesList() {
    return RefreshIndicator(
      onRefresh: _loadFinanceData,
      color: AppTheme.primaryBrown,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expensesList.length,
        itemBuilder: (context, index) => _buildExpenseCard(_expensesList[index]),
      ),
    );
  }

  /// Income card
  Widget _buildIncomeCard(Income income) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.attach_money, color: AppTheme.successGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(income.description ?? 'Income', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_dateFormat.format(income.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkBrown.withOpacity(0.6))),
                ]),
              ),
              IconButton(icon: const Icon(Icons.delete, color: AppTheme.errorRed), onPressed: () => _deleteIncome(income), iconSize: 20),
            ],
          ),
          const Divider(height: 16),
          _buildIncomeExpenseRow('Notes', income.notes),
          const SizedBox(height: 8),
          _buildIncomeExpenseRow('Coins', income.coins),
          const Divider(height: 16),
          _buildTotalRow('TOTAL', income.total, AppTheme.successGreen),
        ]),
      ),
    );
  }

  /// Expense card
  Widget _buildExpenseCard(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.money_off, color: AppTheme.errorRed, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.description, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_dateFormat.format(expense.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkBrown.withOpacity(0.6))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_currencyFormat.format(expense.amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete, color: AppTheme.errorRed), onPressed: () => _deleteExpense(expense), iconSize: 20),
            ]),
          ],
        ),
      ),
    );
  }

  /// Helper for notes/coins rows in income card
  Widget _buildIncomeExpenseRow(String label, double amount) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
      Text(_currencyFormat.format(amount), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  /// Helper for total row in income card
  Widget _buildTotalRow(String label, double amount, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('$label:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      Text(_currencyFormat.format(amount), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
    ]);
  }

  /// Empty state widget
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 80, color: AppTheme.darkBrown.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.darkBrown.withOpacity(0.5))),
        const SizedBox(height: 8),
        Text('Tap + to add', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.darkBrown.withOpacity(0.5))),
      ]),
    );
  }

  // -------------------- SNACKBARS --------------------

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.successGreen, duration: const Duration(seconds: 2)));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed, duration: const Duration(seconds: 3)));
  }
}
