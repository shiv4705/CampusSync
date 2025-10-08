import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF10192E),
    primaryColor: const Color(0xFF9AB6FF),
    canvasColor: const Color(0xFF17233F),

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

    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white70,
    ),

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

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9AB6FF),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 3,
      ),
    ),

    cardColor: const Color(0xFF17233F),

    tabBarTheme: const TabBarTheme(
      labelColor: Color(0xFF9AB6FF),
      unselectedLabelColor: Colors.white54,
      indicatorColor: Color(0xFF9AB6FF),
    ),

    dialogBackgroundColor: const Color(0xFF17233F),
  );
}
