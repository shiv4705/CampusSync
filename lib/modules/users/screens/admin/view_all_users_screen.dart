import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';

class ViewAllUsersScreen extends StatefulWidget {
  const ViewAllUsersScreen({super.key});

  @override
  State<ViewAllUsersScreen> createState() => _ViewAllUsersScreenState();
}

class _ViewAllUsersScreenState extends State<ViewAllUsersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _studentSearchController = TextEditingController();
  final _facultySearchController = TextEditingController();
  final UserService _service = UserService();

  String _studentSearchQuery = '';
  String _facultySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentSearchController.dispose();
    _facultySearchController.dispose();
    super.dispose();
  }

  Widget _buildUserList(String role, String searchQuery) {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getUsersByRole(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Failed to load users.",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers =
            users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery) || email.contains(searchQuery);
            }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text(
              "No users found.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final data = filteredUsers[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'No Name';
            final email = data['email'] ?? 'No Email';

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + index * 100),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: child,
                  ),
                );
              },
              child: Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue1 = Color(0xFF0A152E);
    const darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        title: const Text(
          "All Users",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [Tab(text: "Students"), Tab(text: "Faculty")],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue1, darkBlue2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Students Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _studentSearchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search students...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged:
                        (value) => setState(() {
                          _studentSearchQuery = value.trim().toLowerCase();
                        }),
                  ),
                ),
                Expanded(child: _buildUserList('student', _studentSearchQuery)),
              ],
            ),
            // Faculty Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _facultySearchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search faculty...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged:
                        (value) => setState(() {
                          _facultySearchQuery = value.trim().toLowerCase();
                        }),
                  ),
                ),
                Expanded(child: _buildUserList('faculty', _facultySearchQuery)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
