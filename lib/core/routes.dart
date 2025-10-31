import 'package:flutter/material.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/dashboard/admin_dashboard.dart';
import '../modules/dashboard/faculty_dashboard.dart';
import '../modules/dashboard/student_dashboard.dart';

/// Centralized route names and a route generator for Navigator.
///
/// Keeps all route strings in one place and maps them to pages.
class Routes {
  // Route name for the login screen.
  static const login = '/login';

  // Admin dashboard route.
  static const adminDashboard = '/admin-dashboard';

  // Faculty dashboard route.
  static const facultyDashboard = '/faculty-dashboard';

  // Student dashboard route.
  static const studentDashboard = '/student-dashboard';

  /// Map incoming route names to MaterialPageRoute builders.
  /// Returns a 'Page not found' scaffold for unknown routes.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case facultyDashboard:
        return MaterialPageRoute(builder: (_) => const FacultyDashboard());
      case studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentDashboard());
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
