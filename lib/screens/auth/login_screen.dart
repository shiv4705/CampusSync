import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campussync/screens/dashboard/admin_dashboard.dart';
import 'package:campussync/screens/dashboard/faculty_dashboard.dart';
import 'package:campussync/screens/dashboard/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Role detection based on email
String _detectRoleFromEmail(String email) {
  if (email.startsWith('sample.admin@')) {
    return 'admin';
  } else if (email.startsWith('sample.faculty.')) {
    return 'faculty';
  } else if (email.startsWith('sample.student.')) {
    return 'student';
  } else {
    return 'unknown';
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CampusSync Login"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // College Logo
            Center(child: Image.asset('assets/icon.png', height: 120)),
            const SizedBox(height: 24),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password field with visibility toggle
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: const Text("Forgot Password?"),
              ),
            ),
            const SizedBox(height: 24),

            // Login button or loading spinner
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text("Login"),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // LOGIN FUNCTION
  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Please enter both email and password.");
      setState(() => _isLoading = false);
      return;
    }

    final role = _detectRoleFromEmail(email);
    if (role == 'unknown') {
      _showInvalidEmailDialog();
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else if (role == 'faculty') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FacultyDashboard()),
          );
        } else if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Please check your credentials and try again.";
      _showErrorDialog(message);
    } catch (_) {
      _showErrorDialog("Something went wrong. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // FORGOT PASSWORD HANDLER
  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog(
        "Please enter your email above before requesting reset.",
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reset_requests').add({
        'email': email,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Request Submitted"),
              content: Text("Password reset request submitted for $email."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } catch (e) {
      _showErrorDialog("Error submitting request. Try again later.");
    }
  }

  void _showInvalidEmailDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Invalid Email Format"),
            content: const Text(
              "Your email address does not match any known role.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Login Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
