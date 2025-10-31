import 'package:flutter/material.dart';

/// Centralized app theme definitions.
/// Contains reusable ThemeData instances (darkTheme used app-wide).
class AppTheme {
  /// Dark theme used throughout the application.
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF10192E),
    primaryColor: const Color(0xFF9AB6FF),
    canvasColor: const Color(0xFF17233F),

    // AppBar styling for a consistent top bar across screens.
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF17233F),
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Text styling defaults for body and display text.
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white70,
    ),

    // Default InputDecoration styling for TextFields and forms.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF24355D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.white54),
      labelStyle: const TextStyle(color: Colors.white70),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9AB6FF), width: 1.5),
      ),
    ),

    // ElevatedButton default styling used app-wide.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9AB6FF),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 3,
      ),
    ),

    // Default background color for Card widgets.
    cardColor: const Color(0xFF17233F),

    // TabBar color and indicator defaults.
    tabBarTheme: const TabBarTheme(
      labelColor: Color(0xFF9AB6FF),
      unselectedLabelColor: Colors.white54,
      indicatorColor: Color(0xFF9AB6FF),
    ),

    // Dialog background color for AlertDialogs, etc.
    dialogBackgroundColor: const Color(0xFF17233F),
  );
}
