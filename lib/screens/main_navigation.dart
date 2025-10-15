import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/screens/dashboard_screen.dart';
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
  // For now, only Dashboard is implemented. Others are placeholders.
  final List<Widget> _screens = [
    const DashboardScreen(),           // Index 0
    const PlaceholderScreen(title: 'Stock'),           // Index 1
    const PlaceholderScreen(title: 'Employees'),       // Index 2
    const PlaceholderScreen(title: 'Orders'),          // Index 3
    const PlaceholderScreen(title: 'Income & Expenses'), // Index 4
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

/// Placeholder Screen Widget
/// 
/// This is a temporary screen shown for sections that haven't been built yet.
/// We'll replace these with actual screens in later phases.

class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: AppTheme.primaryBrown.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon in next phases',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}