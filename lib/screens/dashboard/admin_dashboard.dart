import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin/view_reset_requests.screen.dart';
import '../admin/add_user_screen.dart';
import '../admin/view_feedback_screen.dart';
import '../admin/view_all_users_screen.dart';
import '../admin/timetable/manage_timetable_screen.dart'; // Import the ManageTimetableScreen
import '../auth/login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Welcome, Admin!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Add User
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

            // View All Users
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("View All Users"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewAllUsersScreen()),
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
            const SizedBox(height: 16),

            // View Password Reset Requests
            ElevatedButton.icon(
              icon: const Icon(Icons.request_page),
              label: const Text("View Reset Requests"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewResetRequestsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Manage Timetable
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("Manage Timetable"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageTimetableScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

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
