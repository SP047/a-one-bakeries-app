import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/screens/main_navigation.dart';

/// Main Entry Point of A-One Bakeries App
/// 
/// This is where the app starts. We initialize the app with our custom theme
/// and set up the main navigation controller which manages the bottom nav bar.

void main() {
  runApp(const AOneBakeriesApp());
}

class AOneBakeriesApp extends StatelessWidget {
  const AOneBakeriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App Configuration
      title: 'A-One Bakeries',
      debugShowCheckedModeBanner: false, // Remove debug banner
      
      // Apply our custom theme
      theme: AppTheme.lightTheme,
      
      // Home screen - Main Navigation with Dashboard
      home: const MainNavigation(),
    );
  }
}

/// Placeholder Home Screen
/// 
/// This is a temporary screen to test our theme setup.
/// We'll replace this with the actual Dashboard in Phase 2.

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A-One Bakeries'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon Placeholder
            Icon(
              Icons.bakery_dining,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            
            // Welcome Text
            Text(
              'Welcome to A-One Bakeries',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Business Management System',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.darkBrown.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            
            // Test Button
            ElevatedButton.icon(
              onPressed: () {
                // Button action (placeholder)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme is working perfectly!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Test Theme'),
            ),
            const SizedBox(height: 16),
            
            // Phase Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBrown.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Phase 1 Complete! ✅',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Next: Dashboard & Navigation',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}