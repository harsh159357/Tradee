import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0E11), // Binance Dark
    primaryColor: const Color(0xFFF0B90B), // Binance Yellow
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF0B90B),
      secondary: Color(0xFF2DBD85), // Binance Green
      surface: Color(0xFF1E2329),
      error: Color(0xFFF6465D), // Binance Red
    ),
    cardColor: const Color(0xFF1E2329),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
      titleLarge: TextStyle(color: Colors.white70, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
      bodySmall: TextStyle(color: Colors.white54, fontSize: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E2329),
      selectedItemColor: Color(0xFFF0B90B),
      unselectedItemColor: Colors.white54,
    ),
  );
}
