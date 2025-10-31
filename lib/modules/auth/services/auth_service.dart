import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campussyncnew/modules/dashboard/admin_dashboard.dart';
import 'package:campussyncnew/modules/dashboard/faculty_dashboard.dart';
import 'package:campussyncnew/modules/dashboard/student_dashboard.dart';

/// Authentication helper that handles login and forgot-password flows.
/// NOTE: role detection here is heuristic (email prefix) used to route to dashboards.
class AuthService {
  /// Very small heuristic to detect a role from an email pattern used in demo data.
  String _detectRoleFromEmail(String email) {
    if (email.startsWith('sample.admin@')) return 'admin';
    if (email.startsWith('sample.faculty.')) return 'faculty';
    if (email.startsWith('sample.student.')) return 'student';
    return 'unknown';
  }

  /// Perform sign-in and navigate to the appropriate dashboard on success.
  Future<void> handleLogin(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _showDialog(
        context,
        "Login Error",
        "Please enter both email and password.",
      );
      return;
    }

    final role = _detectRoleFromEmail(email);
    if (role == 'unknown') {
      _showDialog(
        context,
        "Invalid Email Format",
        "Your email address does not match any known role.",
      );
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        Widget dashboard;
        switch (role) {
          case 'admin':
            dashboard = const AdminDashboard();
            break;
          case 'faculty':
            dashboard = const FacultyDashboard();
            break;
          default:
            dashboard = const StudentDashboard();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
        );
      }
    } on FirebaseAuthException {
      _showDialog(
        context,
        "Login Error",
        "Please check your credentials and try again.",
      );
    } catch (_) {
      _showDialog(context, "Error", "Something went wrong. Try again.");
    }
  }

  /// Add a reset request document to Firestore so admins can process it.
  Future<void> handleForgotPassword(BuildContext context, String email) async {
    if (email.isEmpty) {
      _showDialog(
        context,
        "Error",
        "Please enter your email before reset request.",
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reset_requests').add({
        'email': email,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });
      _showDialog(
        context,
        "Request Submitted",
        "Password reset request submitted for $email.",
      );
    } catch (_) {
      _showDialog(
        context,
        "Error",
        "Error submitting request. Try again later.",
      );
    }
  }

  /// Small helper to show themed alert dialogs.
  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF17233F),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Color(0xFF9AB6FF)),
                ),
              ),
            ],
          ),
    );
  }
}
