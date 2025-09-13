import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFD4AF37), // Gold
    onPrimary: Colors.black,
    secondary: const Color(0xFF1C1C1C), // Deep black
    onSecondary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    surface: const Color(0xFF0E0E0E), // replaces background
    onSurface: Colors.white,          // replaces onBackground
  ),
    scaffoldBackgroundColor: const Color(0xFF0E0E0E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1C),
      foregroundColor: Color(0xFFD4AF37),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),


  );
}