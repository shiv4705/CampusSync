import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campussync/screens/auth/login_screen.dart';
import 'package:campussync/screens/faculty/faculty_timetable_screen.dart';
import 'package:campussync/screens/faculty/mark_attendance_screen.dart';
import 'package:campussync/screens/faculty/faculty_classroom_page.dart';
import 'package:campussync/screens/faculty/faculty_subject_list_screen.dart';
import 'package:campussync/screens/faculty/faculty_view_submissions_screen.dart';

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

    int itemCount = 4;
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
          facultyName =
              snapshot.docs.first.data().containsKey('name')
                  ? snapshot.docs.first['name']
                  : "Faculty";
        });
      } else {
        setState(() {
          facultyName = "Faculty";
        });
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
            builder: (_) {
              return Container(
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
                              builder: (_) => const FacultySubjectListScreen(),
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
                                  (_) => const FacultyViewSubmissionsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      },
    ];

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFF9AB6FF), Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: Text(
            "Welcome, $facultyName",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
        child: Padding(
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
                  child: _buildDashboardCard(
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
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isHovered
                          ? Colors.blueAccent.withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isHovered
                            ? Colors.blueAccent.withOpacity(0.5)
                            : Colors.black.withOpacity(0.3),
                    blurRadius: isHovered ? 16 : 10,
                    spreadRadius: isHovered ? 2 : 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 42, color: color),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
