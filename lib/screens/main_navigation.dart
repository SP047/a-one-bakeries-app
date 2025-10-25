import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/screens/dashboard_screen.dart';
import 'package:a_one_bakeries_app/screens/stock_screen.dart';
import 'package:a_one_bakeries_app/screens/employee_screen.dart';
import 'package:a_one_bakeries_app/screens/orders_screen.dart';
import 'package:a_one_bakeries_app/screens/finance_screen.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';

/// Main Navigation Controller
/// 
/// This widget manages the bottom navigation bar and switches between
/// different screens based on the selected tab.
/// 
/// It uses setState to track which screen is currently active.

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Current selected index (0 = Dashboard, 1 = Stock, etc.)
  int _currentIndex = 0;

  // List of screens corresponding to each navigation item
  final List<Widget> _screens = [
    const DashboardScreen(),      // Index 0 - Dashboard
    const StockScreen(),          // Index 1 - Stock
    const EmployeeScreen(),       // Index 2 - Employees
    const OrdersScreen(),         // Index 3 - Orders
    const FinanceScreen(),        // Index 4 - Finance
  ];

  /// Handle navigation tap
  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the current screen based on selected index
      body: _screens[_currentIndex],
      
      // Custom Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        
        // Navigation Items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
        ],
      ),
    );
  }
}