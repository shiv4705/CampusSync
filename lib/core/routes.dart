import 'package:flutter/material.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/dashboard/admin_dashboard.dart';
import '../modules/dashboard/faculty_dashboard.dart';
import '../modules/dashboard/student_dashboard.dart';

class Routes {
  static const login = '/login';
  static const adminDashboard = '/admin-dashboard';
  static const facultyDashboard = '/faculty-dashboard';
  static const studentDashboard = '/student-dashboard';

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
