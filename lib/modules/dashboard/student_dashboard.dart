import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/screens/login_screen.dart';
import '../feedback/screens/student/submit_feedback_screen.dart';
import '../timetable/screens/student/student_timetable_screen.dart';
import '../attendance/screens/student/student_attendance_screen.dart';
import '../study_materials/screens/student/student_material_page.dart';
import '../assignments/screens/student/student_assignment_subjects_screen.dart';
import '../event_calendar/screens/event_calendar.dart';
import '../dashboard/dashboard_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String studentName = "";

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  Future<void> _fetchStudentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          studentName = snapshot.docs.first['name'] ?? "Student";
        });
      } else {
        setState(() => studentName = "Student");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF091227);
    const Color darkBlue2 = Color(0xFF0D1D50);
    const Color primaryColor = Color(0xFF9AB6FF);

    final String? studentEmail = FirebaseAuth.instance.currentUser?.email;

    final List<Map<String, dynamic>> dashboardItems = [
      {
        "title": "View Timetable",
        "icon": Icons.calendar_today,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentTimetableScreen()),
            ),
      },
      {
        "title": "Submit Feedback",
        "icon": Icons.feedback,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubmitFeedbackScreen()),
            ),
      },
      {
        "title": "View Attendance",
        "icon": Icons.fact_check,
        "onTap": () {
          if (studentEmail != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StudentAttendanceScreen(studentEmail: studentEmail),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Error: Unable to fetch student email."),
              ),
            );
          }
        },
      },
      {
        "title": "Study Materials",
        "icon": Icons.menu_book,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentMaterialPage()),
            ),
      },
      {
        "title": "Assignments",
        "icon": Icons.assignment,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentAssignmentSubjectsScreen(),
              ),
            ),
      },
      {
        "title": "Event Calendar",
        "icon": Icons.event_note,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventCalendarScreen()),
            ),
      },
    ];

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Welcome, $studentName",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue1, darkBlue2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: dashboardItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            return DashboardCard(
              title: dashboardItems[index]["title"],
              icon: dashboardItems[index]["icon"],
              color: primaryColor,
              onTap: dashboardItems[index]["onTap"],
            );
          },
        ),
      ),
    );
  }
}
