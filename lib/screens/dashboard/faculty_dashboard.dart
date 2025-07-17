import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campussync/screens/auth/login_screen.dart';
import 'package:campussync/screens/faculty/faculty_timetable_screen.dart';
import 'package:campussync/screens/faculty/mark_attendance_screen.dart'; // ✅ NEW

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              "Welcome Faculty!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            /// View Timetable
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("View Timetable"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FacultyTimetableScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            /// Mark Attendance (Today’s Classes)
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Mark Attendance"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
