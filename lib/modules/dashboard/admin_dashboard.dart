import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/screens/login_screen.dart';
import '../users/screens/admin/add_user_screen.dart';
import '../users/screens/admin/view_all_users_screen.dart';
import '../feedback/screens/admin/view_feedback_screen.dart';
import '../reset_requests/screens/admin/view_reset_requests_screen.dart';
import '../timetable/screens/admin/manage_timetable_screen.dart';
import '../subjects/screens/admin/assign_subject_screen.dart';
import '../event_calendar/screens/event_calendar.dart';
import 'dashboard_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    int itemCount = 7;
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF9AB6FF);
    const Color darkBlue1 = Color(0xFF0A152E);
    const Color darkBlue2 = Color(0xFF0D1D50);

    final List<Map<String, dynamic>> dashboardItems = [
      {
        "title": "Add User",
        "icon": Icons.person_add,
        "page": const AddUserScreen(),
      },
      {
        "title": "View Users",
        "icon": Icons.people,
        "page": const ViewAllUsersScreen(),
      },
      {
        "title": "Feedback",
        "icon": Icons.feedback_outlined,
        "page": const ViewFeedbackScreen(),
      },
      {
        "title": "Reset Requests",
        "icon": Icons.vpn_key,
        "page": const ViewResetRequestsScreen(),
      },
      {
        "title": "Manage Timetable",
        "icon": Icons.calendar_month_outlined,
        "page": const ManageTimetableScreen(),
      },
      {
        "title": "Assign Subject",
        "icon": Icons.book_outlined,
        "page": const AdminAssignSubjectScreen(),
      },
      {
        "title": "Event Calendar",
        "icon": Icons.event_note,
        "page": const EventCalendarScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => dashboardItems[index]["page"],
                        ),
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
