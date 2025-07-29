import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../admin/view_reset_requests.screen.dart';
import '../admin/add_user_screen.dart';
import '../admin/view_feedback_screen.dart';
import '../admin/view_all_users_screen.dart';
import '../admin/timetable/manage_timetable_screen.dart';
import '../auth/login_screen.dart';

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

    // Number of cards
    int itemCount = 5;

    // Create staggered animations
    _fadeAnimations = List.generate(itemCount, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
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

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF9AB6FF);
    final Color darkBlue1 = const Color(0xFF0A152E);
    final Color darkBlue2 = const Color(0xFF0D1D50);

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
          child: const Text(
            "Admin Dashboard",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkBlue1, darkBlue2],
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
                    context,
                    title: dashboardItems[index]["title"],
                    icon: dashboardItems[index]["icon"],
                    color: primaryColor,
                    page: dashboardItems[index]["page"],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Premium Card Widget with Hover/Tap Glow
  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isHovered
                          ? Colors.blueAccent.withOpacity(0.4)
                          : Colors.white.withOpacity(0.15),
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
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => page),
                  );
                },
                splashColor: Colors.blueAccent.withOpacity(0.2),
                highlightColor: Colors.transparent,
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
          ),
        );
      },
    );
  }
}
