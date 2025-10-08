import 'package:flutter/material.dart';
import 'core/app_initializer.dart';
import 'core/app_theme.dart';
import 'core/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize(); // centralized Firebase & Supabase init
  runApp(const CampusSyncApp());
}

class CampusSyncApp extends StatelessWidget {
  const CampusSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New CampusSync',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme, // centralized theme
      initialRoute: Routes.login, // defined in routes.dart
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
