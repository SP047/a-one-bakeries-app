import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/screens/dashboard_screen.dart';
import 'package:a_one_bakeries_app/screens/stock_screen.dart';
import 'package:a_one_bakeries_app/screens/employee_screen.dart';
import 'package:a_one_bakeries_app/screens/orders_screen.dart';
import 'package:a_one_bakeries_app/screens/finance_screen.dart';

/// Main Navigation Controller
/// 
/// Manages bottom navigation bar and switches between screens.
/// Uses setState to track the current active screen.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // -------------------- STATE --------------------
  /// Current selected tab index
  int _currentIndex = 0;

  /// Screens corresponding to each bottom navigation tab
  final List<Widget> _screens = const [
    DashboardScreen(), // Index 0
    StockScreen(),     // Index 1
    EmployeeScreen(),  // Index 2
    OrdersScreen(),    // Index 3
    FinanceScreen(),   // Index 4
  ];

  // -------------------- NAVIGATION HANDLER --------------------
  /// Called when a navigation item is tapped
  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // -------------------- BUILD METHOD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the currently selected screen
      body: _screens[_currentIndex],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed, // Fixed for more than 3 items
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,

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
