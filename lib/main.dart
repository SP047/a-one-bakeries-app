import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/screens/main_navigation.dart';

/// Main Entry Point of A-One Bakeries App
/// 
/// This is where the app starts. We initialize the app with our custom theme
/// and set up the main navigation controller which manages the bottom nav bar.

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
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