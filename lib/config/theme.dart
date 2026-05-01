import 'package:flutter/material.dart';

class AppTheme {
  // Gold Color Palette
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFC700);
  static const Color goldLight = Color(0xFFFFE066);
  static const Color goldAccent = Color(0xFFFFF59D);
  
  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color greyDark = Color(0xFF424242);
  static const Color greyMedium = Color(0xFF757575);
  static const Color greyLight = Color(0xFFBDBDBD);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // Gradient Colors
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [gold, goldLight, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.light,
        primary: gold,
        secondary: goldDark,
        surface: surfaceLight,
        background: white,
        error: Colors.red,
        onPrimary: black,
        onSecondary: black,
        onSurface: black,
        onBackground: black,
        onError: white,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: gold,
        foregroundColor: black,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 8,
        shadowColor: gold.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: black,
          elevation: 4,
          shadowColor: gold.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: black,
        elevation: 8,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: gold,
        unselectedItemColor: greyMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: black,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: black,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: black,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: black,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: black,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: black,
        size: 24,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        filled: true,
        fillColor: surfaceLight,
        labelStyle: const TextStyle(color: greyMedium),
        hintStyle: const TextStyle(color: greyLight),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
        primary: gold,
        secondary: goldLight,
        surface: surfaceDark,
        background: black,
        error: Colors.red,
        onPrimary: black,
        onSecondary: black,
        onSurface: white,
        onBackground: white,
        onError: white,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: gold,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: gold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: greyDark,
        elevation: 8,
        shadowColor: gold.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: black,
          elevation: 4,
          shadowColor: gold.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: black,
        elevation: 8,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: gold,
        unselectedItemColor: greyMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: white,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: white,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: white,
        size: 24,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        filled: true,
        fillColor: greyDark,
        labelStyle: const TextStyle(color: greyMedium),
        hintStyle: const TextStyle(color: greyLight),
      ),
    );
  }
}
