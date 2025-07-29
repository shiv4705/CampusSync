import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _message;

  late AnimationController _controller;
  List<Animation<Offset>> _slideAnimations = [];
  List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Delay animation initialization to avoid late error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int itemCount = 7; // Title + 4 fields + message + button

      _slideAnimations = List.generate(
        itemCount,
        (index) => Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              0.1 * index,
              0.6 + (0.1 * index),
              curve: Curves.easeOut,
            ),
          ),
        ),
      );

      _fadeAnimations = List.generate(
        itemCount,
        (index) => Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              0.1 * index,
              0.7 + (0.1 * index),
              curve: Curves.easeOut,
            ),
          ),
        ),
      );

      _controller.forward();
      setState(() {});
    });
  }

  String _detectRole(String email) {
    if (email.startsWith('sample.faculty.')) return 'faculty';
    if (email.startsWith('sample.student.')) return 'student';
    return 'unknown';
  }

  Future<void> _addUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final role = _detectRole(email);

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _message = "Error: All fields are required.");
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
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      };

      if (role == 'student') {
        userData['semester'] = '7';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      setState(() {
        _message = "User '$name' created successfully as '$role'.";
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _message = "Error: ${e.message}");
    } catch (_) {
      setState(() => _message = "Error: Something went wrong.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF9AB6FF);
    final Color darkBlue1 = const Color(0xFF0A152E);
    final Color darkBlue2 = const Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        title: const Text("Add New User"),
        backgroundColor: darkBlue2,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue1, darkBlue2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 360, // ✅ Inner card smaller
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _animatedItem(
                    0,
                    const Text(
                      "Create New User",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _animatedItem(
                    1,
                    _buildInputField(
                      "Full Name",
                      _nameController,
                      Icons.person,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _animatedItem(
                    2,
                    _buildInputField(
                      "Email",
                      _emailController,
                      Icons.email,
                      keyboard: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _animatedItem(
                    3,
                    _buildPasswordField(
                      "Password",
                      _passwordController,
                      _isPasswordVisible,
                      () {
                        setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _animatedItem(
                    4,
                    _buildPasswordField(
                      "Confirm Password",
                      _confirmPasswordController,
                      _isConfirmPasswordVisible,
                      () {
                        setState(
                          () =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_message != null)
                    _animatedItem(
                      5,
                      Text(
                        _message!,
                        style: TextStyle(
                          color:
                              _message!.contains('Error')
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  _isLoading
                      ? const CircularProgressIndicator(
                        color: Colors.blueAccent,
                      )
                      : _animatedItem(
                        6,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _addUser,
                            icon: const Icon(
                              Icons.person_add,
                              color: Colors.black,
                            ),
                            label: const Text(
                              "Create User",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedItem(int index, Widget child) {
    if (_slideAnimations.isEmpty || _fadeAnimations.isEmpty) {
      return child;
    }
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(opacity: _fadeAnimations[index], child: child),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF9AB6FF)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF9AB6FF)),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: toggleVisibility,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
