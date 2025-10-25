import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/finance_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/widgets/add_income_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_expense_dialog.dart';
import 'package:intl/intl.dart';

/// Finance Screen
/// 
/// Main screen for income and expense management.
/// Shows summary, income tab, and expenses tab.

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  // Summary data
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _moneyOnHand = 0.0;

  // Income and Expenses lists
  List<Income> _incomeList = [];
  List<Expense> _expensesList = [];

  bool _isLoading = true;

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

  /// Load all finance data
  Future<void> _loadFinanceData() async {
    setState(() {
      _isLoading = true;
    });

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
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading finance data: $e');
      }
    }
  }

  /// Show add income dialog
  Future<void> _showAddIncomeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddIncomeDialog(),
    );

    if (result == true) {
      _loadFinanceData();
      if (mounted) {
        _showSuccessSnackBar('Income recorded successfully!');
      }
    }
  }

  /// Show add expense dialog
  Future<void> _showAddExpenseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );

    if (result == true) {
      _loadFinanceData();
      if (mounted) {
        _showSuccessSnackBar('Expense recorded successfully!');
      }
    }
  }

  /// Delete income
  Future<void> _deleteIncome(Income income) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: Text('Delete income record of ${_currencyFormat.format(income.total)}?'),
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
        await _dbHelper.deleteIncome(income.id!);
        _loadFinanceData();
        if (mounted) {
          _showSuccessSnackBar('Income deleted!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting income: $e');
        }
      }
    }
  }

  /// Delete expense
  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete expense: ${expense.description}?'),
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
        await _dbHelper.deleteExpense(expense.id!);
        _loadFinanceData();
        if (mounted) {
          _showSuccessSnackBar('Expense deleted!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting expense: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Income & Expenses'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Section
                _buildSummarySection(),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryBrown,
                  unselectedLabelColor: AppTheme.darkBrown.withOpacity(0.5),
                  indicatorColor: AppTheme.primaryBrown,
                  tabs: const [
                    Tab(text: 'Income'),
                    Tab(text: 'Expenses'),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIncomeTab(),
                      _buildExpensesTab(),
                    ],
                  ),
                ),
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

  /// Build summary section
  Widget _buildSummarySection() {
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
          // Money on Hand
          Text(
            'Money on Hand',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_moneyOnHand),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 32, color: Colors.white24),

          // Income and Expenses Row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Total Income',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(_totalIncome),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Total Expenses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(_totalExpenses),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.errorRed,
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

  /// Build income tab
  Widget _buildIncomeTab() {
    return _incomeList.isEmpty
        ? _buildEmptyState('No income recorded yet', Icons.attach_money)
        : RefreshIndicator(
            onRefresh: _loadFinanceData,
            color: AppTheme.primaryBrown,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _incomeList.length,
              itemBuilder: (context, index) {
                return _buildIncomeCard(_incomeList[index]);
              },
            ),
          );
  }

  /// Build expenses tab
  Widget _buildExpensesTab() {
    return _expensesList.isEmpty
        ? _buildEmptyState('No expenses recorded yet', Icons.money_off)
        : RefreshIndicator(
            onRefresh: _loadFinanceData,
            color: AppTheme.primaryBrown,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _expensesList.length,
              itemBuilder: (context, index) {
                return _buildExpenseCard(_expensesList[index]);
              },
            ),
          );
  }

  /// Build income card
  Widget _buildIncomeCard(Income income) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: AppTheme.successGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        income.description ?? 'Income',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormat.format(income.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkBrown.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                  onPressed: () => _deleteIncome(income),
                  iconSize: 20,
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notes:', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  _currencyFormat.format(income.notes),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coins:', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  _currencyFormat.format(income.coins),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _currencyFormat.format(income.total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build expense card
  Widget _buildExpenseCard(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.money_off,
                color: AppTheme.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateFormat.format(expense.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkBrown.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(expense.amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                  onPressed: () => _deleteExpense(expense),
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}