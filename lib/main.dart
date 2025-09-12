import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://nyjhscoadbhbhepddxjx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55amhzY29hZGJoYmhlcGRkeGp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1NjUxMTgsImV4cCI6MjA3MzE0MTExOH0.27_QbrcXSrQkM7w4r3s3rt6j_kjL2lagdQYRJqC5xqI',
  );

  runApp(const CampusSyncApp());
}

class CampusSyncApp extends StatelessWidget {
  const CampusSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusSync',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
        // ✅ Background colors consistent with login screen
        scaffoldBackgroundColor: const Color(
          0xFF10192E,
        ), // outer gradient color
        primaryColor: const Color(0xFF9AB6FF), // accent color
        canvasColor: const Color(0xFF17233F), // card background
        // ✅ AppBar style
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

        // ✅ Text colors
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white70,
        ),

        // ✅ Input fields
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

        // ✅ Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9AB6FF),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 3,
          ),
        ),

        // ✅ Card background (like login container)
        cardColor: const Color(0xFF17233F),

        // ✅ Tab bar
        tabBarTheme: const TabBarTheme(
          labelColor: Color(0xFF9AB6FF),
          unselectedLabelColor: Colors.white54,
          indicatorColor: Color(0xFF9AB6FF),
        ),

        // ✅ Dialog background matches login dialog
        dialogBackgroundColor: const Color(0xFF17233F),
      ),
      home: const LoginScreen(),
    );
  }
}
