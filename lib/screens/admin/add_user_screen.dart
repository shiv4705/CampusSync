import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _message;

  String _detectRole(String email) {
    if (email.startsWith('sample.faculty.')) return 'faculty';
    if (email.startsWith('sample.student.')) return 'student';
    return 'unknown';
  }

  Future<void> _addUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final role = _detectRole(email);

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(
        () =>
            _message =
                "Error: Email, password, and confirm password cannot be empty.",
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() => _message = "Error: Passwords do not match.");
      return;
    }

    if (role == 'unknown') {
      setState(
        () => _message = "Error: Invalid email format for role detection.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Store user info in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        _message = "User created successfully as '$role'.";
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _message = "Error: ${e.message}");
    } catch (e) {
      setState(() => _message = "Error: Something went wrong.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New User")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color:
                      _message!.contains('Error') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Create User"),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
