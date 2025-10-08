import 'package:flutter/material.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _LoginBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: LoginForm(),
          ),
        ),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  final Widget child;
  const _LoginBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10192E), Color(0xFF17233F)],
        ),
      ),
      child: child,
    );
  }
}
