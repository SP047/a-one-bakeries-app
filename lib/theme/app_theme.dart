import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Theme Configuration
/// 
/// This file contains the complete theme for A-One Bakeries App.
/// We use a warm, bakery-inspired color palette:
/// - Warm Brown: Main brand color (like fresh baked bread)
/// - Cream: Background color (like flour/dough)
/// - Orange: Accent color (warm and inviting)
/// - Dark Brown: Text and emphasis

class AppTheme {
  // Color Palette - Bakery Inspired Colors
  static const Color primaryBrown = Color(0xFF8B4513);      // Saddle Brown - main color
  static const Color secondaryOrange = Color(0xFFFF8C42);   // Orange - accent color
  static const Color creamBackground = Color(0xFFFFF8E7);   // Cream - background
  static const Color darkBrown = Color(0xFF3E2723);         // Dark Brown - text
  static const Color lightCream = Color(0xFFFFFBF0);        // Light cream - cards
  static const Color errorRed = Color(0xFFD32F2F);          // Error color
  static const Color successGreen = Color(0xFF388E3C);      // Success color

  /// Main Light Theme
  static ThemeData lightTheme = ThemeData(
    // Brightness
    brightness: Brightness.light,
    
    // Primary Colors
    primaryColor: primaryBrown,
    scaffoldBackgroundColor: creamBackground,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryBrown,
      secondary: secondaryOrange,
      surface: lightCream,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkBrown,
      onError: Colors.white,
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryBrown,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: lightCream,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBrown,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBrown,
        side: const BorderSide(color: primaryBrown, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryOrange,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBrown, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryBrown.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBrown, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        color: darkBrown,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.poppins(
        color: darkBrown.withOpacity(0.5),
        fontSize: 14,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: primaryBrown,
      size: 24,
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: primaryBrown.withOpacity(0.2),
      thickness: 1,
      space: 1,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBrown,
      unselectedItemColor: darkBrown.withOpacity(0.5),
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Text Theme
    textTheme: TextTheme(
      // Headings
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkBrown,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkBrown,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkBrown,
      ),
      
      // Titles
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkBrown,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkBrown,
      ),
      
      // Body Text
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkBrown,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkBrown,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: darkBrown,
      ),
      
      // Labels
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkBrown,
      ),
    ),
  );
}