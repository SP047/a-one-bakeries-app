import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/widgets/summary_card.dart';
import 'package:a_one_bakeries_app/widgets/add_income_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_expense_dialog.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/screens/vehicle_screen.dart';
import 'package:intl/intl.dart';

/// Dashboard Screen
/// 
/// This is the main screen users see when they open the app.
/// It displays summaries of:
/// - Stock levels
/// - Today's orders
/// - Income & Expenses
/// 
/// In later phases, we'll connect this to real database data.

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Date formatter for displaying current date
  final DateFormat _dateFormat = DateFormat('EEEE, MMMM d, yyyy');
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Dashboard data
  int _stockItemsCount = 0;
  int _employeesCount = 0;
  int _todayBreadQuantity = 0;
  double _todayIncome = 0.0;
  double _todayExpenses = 0.0;
  bool _isLoading = true;

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load dashboard data from database
  Future<void> _loadDashboardData() async {
    try {
      final stockItems = await _dbHelper.getAllStockItems();
      final employees = await _dbHelper.getAllEmployees();
      final breadQty = await _dbHelper.getTodayBreadQuantity();
      setState(() {
        _stockItemsCount = stockItems.length;
        _employeesCount = employees.length;
        _todayBreadQuantity = breadQty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      
      // App Bar with business name and date
      appBar: AppBar(
        title: const Text('A-One Bakeries'),
        actions: [
          // Notification icon (placeholder for future feature)
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications in future
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryBrown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                
                // Date Display
                _buildDateSection(),
                const SizedBox(height: 24),
                
                // Summary Cards Section
                _buildSummarySection(),
                const SizedBox(height: 24),
                
                // Quick Actions Section
                _buildQuickActionsSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Welcome Section Widget
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBrown,
            AppTheme.primaryBrown.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Row(
        children: [
          // Bakery Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bakery_dining,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          
          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s your business overview',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Date Section Widget
  Widget _buildDateSection() {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 20,
          color: AppTheme.darkBrown.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Text(
          _dateFormat.format(DateTime.now()),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkBrown.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Summary Section with Cards
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        // Stock Summary Card
        SummaryCard(
          title: 'Stock on Hand',
          value: _isLoading ? '...' : '$_stockItemsCount',
          subtitle: 'Total items in stock',
          icon: Icons.inventory_2,
          color: AppTheme.primaryBrown,
          onTap: () {
            // TODO: Navigate to stock screen (Phase 3)
          },
        ),
        
        // Employees Summary Card
        SummaryCard(
          title: 'Total Employees',
          value: _isLoading ? '...' : '$_employeesCount',
          subtitle: 'Registered staff members',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () {
            // TODO: Navigate to employees screen (Phase 4)
          },
        ),
        
        // Orders Summary Card
        SummaryCard(
          title: 'Today\'s Bread',
          value: _isLoading ? '...' : '$_todayBreadQuantity',
          subtitle: 'Total bread quantity',
          icon: Icons.shopping_cart,
          color: AppTheme.secondaryOrange,
          onTap: () {
            // Navigate to orders screen
          },
        ),
        
        // Income Summary Card
        SummaryCard(
          title: 'Today\'s Income',
          value: 'R 0.00',
          subtitle: 'Total income today',
          icon: Icons.trending_up,
          color: AppTheme.successGreen,
          onTap: () {
            // TODO: Navigate to income screen (Phase 7)
          },
        ),
        
        // Expenses Summary Card
        SummaryCard(
          title: 'Today\'s Expenses',
          value: 'R 0.00',
          subtitle: 'Total expenses today',
          icon: Icons.trending_down,
          color: AppTheme.errorRed,
          onTap: () {
            // TODO: Navigate to expenses screen (Phase 7)
          },
        ),
      ],
    );
  }

  /// Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        // Quick action buttons in a 2x3 grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _buildQuickActionButton(
              icon: Icons.add_shopping_cart,
              label: 'New Order',
              onTap: () {
                _showComingSoonMessage('New Order');
              },
            ),
            _buildQuickActionButton(
              icon: Icons.inventory,
              label: 'Add Stock',
              onTap: () {
                _showComingSoonMessage('Add Stock');
              },
            ),
            _buildQuickActionButton(
              icon: Icons.person_add,
              label: 'Add Employee',
              onTap: () {
                _showComingSoonMessage('Add Employee');
              },
            ),
            _buildQuickActionButton(
              icon: Icons.local_shipping,
              label: 'Add Vehicle',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VehicleScreen(),
                  ),
                ).then((_) => _loadDashboardData()); // Refresh on return
              },
            ),
            _buildQuickActionButton(
              icon: Icons.attach_money,
              label: 'Record Income',
              onTap: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const AddIncomeDialog(),
                );
                if (result == true) {
                  _loadDashboardData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Income recorded!'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                }
              },
            ),
            _buildQuickActionButton(
              icon: Icons.money_off,
              label: 'Record Expense',
              onTap: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const AddExpenseDialog(),
                );
                if (result == true) {
                  _loadDashboardData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense recorded!'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Quick Action Button Widget
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBrown.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryBrown,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBrown,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Refresh Data Function
  /// 
  /// This will be called when user pulls down to refresh.
  /// Fetches fresh data from the database.
  Future<void> _refreshData() async {
    await _loadDashboardData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard refreshed!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Show Coming Soon Message
  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming in next phases!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}