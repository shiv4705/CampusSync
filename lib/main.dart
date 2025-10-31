import 'package:flutter/material.dart';
import 'core/app_initializer.dart';
import 'core/app_theme.dart';
import 'core/routes.dart';

/// App entrypoint: initialize SDKs then start the Flutter app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize(); // init Firebase & Supabase
  runApp(const CampusSyncApp());
}

/// Root widget for the CampusSync application.
class CampusSyncApp extends StatelessWidget {
  const CampusSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New CampusSync',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme, // use centralized dark theme
      initialRoute: Routes.login, // start at login
      onGenerateRoute: Routes.generateRoute, // route factory
    );
  }
}
