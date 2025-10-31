import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/screens/login_screen.dart';
import '../timetable/screens/faculty/faculty_timetable_screen.dart';
import '../attendance/screens/faculty/mark_attendance_screen.dart';
import '../study_materials/screens/faculty/faculty_classroom_page.dart';
import '../assignments/screens/faculty/faculty_subject_list_screen.dart';
import '../event_calendar/screens/event_calendar.dart';
import '../dashboard/dashboard_card.dart';

/// Faculty dashboard exposing timetable, attendance marking, assignments
/// and other faculty tools via animated dashboard cards.
class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard>
    with SingleTickerProviderStateMixin {
  String facultyName = "";

  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _fetchFacultyDetails();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    int itemCount = 5;
    _fadeAnimations = List.generate(itemCount, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(itemCount, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Play the entry animations for dashboard tiles.
    _controller.forward();
  }

  Future<void> _fetchFacultyDetails() async {
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
          facultyName = snapshot.docs.first['name'] ?? "Faculty";
        });
      } else {
        setState(() => facultyName = "Faculty");
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF091227);
    const Color darkBlue2 = Color(0xFF0D1D50);
    const Color primaryColor = Color(0xFF9AB6FF);

    final List<Map<String, dynamic>> dashboardItems = [
      {
        "title": "View Timetable",
        "icon": Icons.calendar_today,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FacultyTimetableScreen()),
            ),
      },
      {
        "title": "Mark Attendance",
        "icon": Icons.check_circle_outline,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
            ),
      },
      {
        "title": "Study Materials",
        "icon": Icons.menu_book,
        "onTap":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FacultyClassroomPage()),
            ),
      },
      {
        "title": "Assignments",
        "icon": Icons.assignment,
        "onTap": () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder:
                (_) => Container(
                  decoration: BoxDecoration(
                    color: darkBlue1.withOpacity(0.98),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.upload_file,
                            color: Colors.lightBlueAccent,
                          ),
                          title: const Text(
                            "Upload Assignment",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const FacultySubjectListScreen(
                                      mode: AssignmentMode.upload,
                                    ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.visibility,
                            color: Colors.lightBlueAccent,
                          ),
                          title: const Text(
                            "View Submissions",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const FacultySubjectListScreen(
                                      mode: AssignmentMode.viewSubmissions,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          );
        },
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Welcome, $facultyName",
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
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: DashboardCard(
                  title: dashboardItems[index]["title"],
                  icon: dashboardItems[index]["icon"],
                  color: primaryColor,
                  onTap: dashboardItems[index]["onTap"],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
