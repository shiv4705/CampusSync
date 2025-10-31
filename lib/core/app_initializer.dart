import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

/// App SDK initializer. Call `AppInitializer.initialize()` before `runApp()`.
class AppInitializer {
  /// Initialize Firebase and Supabase (minimal, one-line comment).
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Initialize Supabase client (keep keys out of source in production).
    await Supabase.initialize(
      url: 'https://nyjhscoadbhbhepddxjx.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55amhzY29hZGJoYmhlcGRkeGp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1NjUxMTgsImV4cCI6MjA3MzE0MTExOH0.27_QbrcXSrQkM7w4r3s3rt6j_kjL2lagdQYRJqC5xqI',
    );
  }
}
