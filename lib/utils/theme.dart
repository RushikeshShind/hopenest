import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          prefixIconColor: Colors.teal,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}