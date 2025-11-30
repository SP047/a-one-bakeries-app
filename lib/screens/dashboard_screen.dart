import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/widgets/summary_card.dart';
import 'package:a_one_bakeries_app/widgets/add_income_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_expense_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_stock_dialog.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_employee_dialog.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/screens/vehicle_screen.dart';
import 'package:a_one_bakeries_app/screens/stock_screen.dart';
import 'package:a_one_bakeries_app/screens/cash_breakdown_screen.dart';
import 'package:a_one_bakeries_app/screens/employee_screen.dart';
import 'package:a_one_bakeries_app/screens/orders_screen.dart';
import 'package:a_one_bakeries_app/screens/finance_screen.dart';
import 'package:a_one_bakeries_app/screens/create_order_screen.dart';
import 'package:a_one_bakeries_app/screens/notifications_screen.dart';
import 'package:a_one_bakeries_app/services/notification_service.dart';
import 'package:a_one_bakeries_app/widgets/license_expiry_alert.dart';
import 'package:intl/intl.dart';

/// Dashboard Screen
/// 
/// Main screen with overview, quick actions, and navigation.
/// Enhanced with clickable cards and working action buttons.

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DateFormat _dateFormat = DateFormat('EEEE, MMMM d, yyyy');
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');
  
  // Dashboard data
  int _stockItemsCount = 0;
  int _employeesCount = 0;
  int _todayBreadQuantity = 0;
  double _todayIncome = 0.0;
  double _todayExpenses = 0.0;
  int _notificationCount = 0; // Mock notification count
  bool _isLoading = true;
  // License expiry stats
  LicenseExpiryStats? _licenseStats;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load dashboard data from database
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stockItems = await _dbHelper.getAllStockItems();
      final employees = await _dbHelper.getAllEmployees();
      final breadQty = await _dbHelper.getTodayBreadQuantity();
      final todayIncome = await _dbHelper.getTodayIncome();
      final todayExpenses = await _dbHelper.getTodayExpenses();
      // Load license expiry stats
      final licenseStats = await _notificationService.getLicenseExpiryStats();
      final notificationCount = await _notificationService.getCriticalNotificationCount();

      setState(() {
        _stockItemsCount = stockItems.length;
        _employeesCount = employees.length;
        _todayBreadQuantity = breadQty;
        _todayIncome = todayIncome;
        _todayExpenses = todayExpenses;
        _licenseStats = licenseStats;
        _notificationCount = notificationCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Navigate to Stock Screen
  void _navigateToStock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StockScreen()),
    ).then((_) => _loadDashboardData());
  }

  /// Navigate to Employee Screen
  void _navigateToEmployees() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeScreen()),
    ).then((_) => _loadDashboardData());
  }

  /// Navigate to Orders Screen
  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrdersScreen()),
    ).then((_) => _loadDashboardData());
  }

  /// Navigate to Finance Screen
  void _navigateToFinance() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinanceScreen()),
    ).then((_) => _loadDashboardData());
  }

  /// Navigate to Notifications Screen
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    ).then((_) {
      // Reset notification count after viewing
      setState(() {
        _notificationCount = 0;
      });
    });
  }

  /// Show New Order Screen
  void _showNewOrderScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
    ).then((result) {
      if (result == true) {
        _loadDashboardData();
        _showSuccessSnackBar('Order created successfully!');
      }
    });
  }

  /// Show Add Stock Dialog
  Future<void> _showAddStockDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditStockDialog(),
    );

    if (result == true) {
      _loadDashboardData();
      _showSuccessSnackBar('Stock item added successfully!');
    }
  }

  /// Show Add Employee Dialog
  Future<void> _showAddEmployeeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditEmployeeDialog(),
    );

    if (result == true) {
      _loadDashboardData();
      _showSuccessSnackBar('Employee registered successfully!');
    }
  }

  /// Show Add Vehicle Screen
  void _showAddVehicleScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VehicleScreen()),
    ).then((_) => _loadDashboardData());
  }

  /// Show Record Income Dialog
  Future<void> _showRecordIncomeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddIncomeDialog(),
    );

    if (result == true) {
      _loadDashboardData();
      _showSuccessSnackBar('Income recorded successfully!');
    }
  }

  /// Show Record Expense Dialog
  Future<void> _showRecordExpenseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );

    if (result == true) {
      _loadDashboardData();
      _showSuccessSnackBar('Expense recorded successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      
      // App Bar with notifications
      appBar: AppBar(
        title: const Text('A-One Bakeries PTY Ltd'),
        actions: [
          // Notification icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _navigateToNotifications,
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _notificationCount > 9 ? '9+' : '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
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
                const SizedBox(height: 16),

                // License Expiry Alert (NEW!)
                if (_licenseStats != null && _licenseStats!.hasAlerts)
                  LicenseExpiryAlert(
                    stats: _licenseStats!,
                    onTap: _navigateToNotifications,
                  ),
                
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
                  'Welcome Back Shahid!',
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

  /// Summary Section with Clickable Cards
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        // Stock Summary Card (CLICKABLE)
        SummaryCard(
          title: 'Stock on Hand',
          value: _isLoading ? '...' : '$_stockItemsCount',
          subtitle: 'Total items in stock',
          icon: Icons.inventory_2,
          color: AppTheme.primaryBrown,
          onTap: _navigateToStock,
        ),
        
        // Employees Summary Card (CLICKABLE)
        SummaryCard(
          title: 'Total Employees',
          value: _isLoading ? '...' : '$_employeesCount',
          subtitle: 'Registered staff members',
          icon: Icons.people,
          color: Colors.blue,
          onTap: _navigateToEmployees,
        ),
        
        // Orders Summary Card (CLICKABLE)
        SummaryCard(
          title: 'Today\'s Bread',
          value: _isLoading ? '...' : '$_todayBreadQuantity',
          subtitle: 'Total bread quantity',
          icon: Icons.shopping_cart,
          color: AppTheme.secondaryOrange,
          onTap: _navigateToOrders,
        ),
        
        // Income Summary Card (CLICKABLE)
        SummaryCard(
          title: 'Today\'s Income',
          value: _isLoading ? '...' : _currencyFormat.format(_todayIncome),
          subtitle: 'Total income today',
          icon: Icons.trending_up,
          color: AppTheme.successGreen,
          onTap: _navigateToFinance,
        ),
        
        // Expenses Summary Card (CLICKABLE)
        SummaryCard(
          title: 'Today\'s Expenses',
          value: _isLoading ? '...' : _currencyFormat.format(_todayExpenses),
          subtitle: 'Total expenses today',
          icon: Icons.trending_down,
          color: AppTheme.errorRed,
          onTap: _navigateToFinance,
        ),
        
        // Cash Breakdown
        _buildCashBreakdownCard(),
      ],
    );
  }

  Widget _buildCashBreakdownCard() {
    return FutureBuilder<Map<String, double>>(
      future: _dbHelper.getCashBreakdown(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final breakdown = snapshot.data!;
        final total = (breakdown['notes'] ?? 0.0) + (breakdown['r5'] ?? 0.0) + (breakdown['r2'] ?? 0.0) + (breakdown['r1'] ?? 0.0) + (breakdown['50c'] ?? 0.0);
        final notes = breakdown['notes'] ?? 0.0;
        final coins = (breakdown['r5'] ?? 0.0) + (breakdown['r2'] ?? 0.0) + (breakdown['r1'] ?? 0.0) + (breakdown['50c'] ?? 0.0);
        final notesPercent = total == 0 ? 0 : ((notes / total) * 100).round();
        final coinsPercent = total == 0 ? 0 : ((coins / total) * 100).round();
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CashBreakdownScreen())),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryBrown.withOpacity(0.1), AppTheme.successGreen.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryBrown.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryBrown, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Cash Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text(_currencyFormat.format(total), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.successGreen, fontWeight: FontWeight.bold))])),
                    const Icon(Icons.chevron_right, color: AppTheme.primaryBrown),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: _buildBreakdownItem(emoji: '💵', label: 'Notes', amount: notes, percentage: notesPercent, color: AppTheme.successGreen)), Container(width: 1, height: 40, color: Colors.grey[300]), Expanded(child: _buildBreakdownItem(emoji: '🪙', label: 'Coins', amount: coins, percentage: coinsPercent, color: AppTheme.primaryBrown))]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdownItem({required String emoji, required String label, required double amount, required int percentage, required Color color}) {
    return Column(children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 16)), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600))]), const SizedBox(height: 4), Text(_currencyFormat.format(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)), Text('$percentage%', style: TextStyle(fontSize: 11, color: Colors.grey[500]))]);
  }

  /// Quick Actions Section (ALL WORKING)
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
              onTap: _showNewOrderScreen,
            ),
            _buildQuickActionButton(
              icon: Icons.inventory,
              label: 'Add Stock',
              onTap: _showAddStockDialog,
            ),
            _buildQuickActionButton(
              icon: Icons.person_add,
              label: 'Add Employee',
              onTap: _showAddEmployeeDialog,
            ),
            _buildQuickActionButton(
              icon: Icons.local_shipping,
              label: 'Add Vehicle',
              onTap: _showAddVehicleScreen,
            ),
            _buildQuickActionButton(
              icon: Icons.attach_money,
              label: 'Record Income',
              onTap: _showRecordIncomeDialog,
            ),
            _buildQuickActionButton(
              icon: Icons.money_off,
              label: 'Record Expense',
              onTap: _showRecordExpenseDialog,
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
}