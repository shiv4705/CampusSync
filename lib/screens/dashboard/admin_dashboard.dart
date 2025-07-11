import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../admin/add_user_screen.dart';
import '../admin/reset_password_screen.dart';
import '../admin/view_feedback_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text("CampusSync - Admin Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, Admin",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 30),

            // Add New User
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Add New User"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // Reset User Password
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_reset),
              label: const Text("Reset User Password"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResetPasswordScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // View Feedback
            ElevatedButton.icon(
              icon: const Icon(Icons.feedback),
              label: const Text("View Feedback"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewFeedbackScreen()),
                );
              },
            ),

            const Spacer(),

            // Logout
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
