import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_materials_page.dart';

class FacultyClassroomPage extends StatefulWidget {
  /// Faculty view that lists classrooms (subjects) assigned to the current faculty.
  /// Tapping a row opens the subject's materials page.
  const FacultyClassroomPage({super.key});

  @override
  State<FacultyClassroomPage> createState() => _FacultyClassroomPageState();
}

class _FacultyClassroomPageState extends State<FacultyClassroomPage> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _classrooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    // Load subjects where `facultyId` matches the current user's id.
    // NOTE: replace the demo `currentUserId` with real auth user id retrieval.
    try {
      final currentUserId =
          "iJjBlzX54pZRCVqUcLPEg1c2LhC3"; // demo, replace with auth logic

      final snapshot =
          await _firestore
              .collection('subjects')
              .where('facultyId', isEqualTo: currentUserId)
              .get();

      setState(() {
        // Convert Firestore docs to a simple list of maps for the UI.
        _classrooms =
            snapshot.docs
                .map((doc) => {"id": doc.id, "subject": doc['subject']})
                .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading classrooms: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text("My Classrooms"),
        backgroundColor: darkBlue,
      ),
      // Body: show a loader, empty message or the classroom list.
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _classrooms.isEmpty
              ? const Center(
                child: Text(
                  "No classrooms assigned.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _classrooms.length,
                itemBuilder: (context, index) {
                  final classroom = _classrooms[index];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    child: ListTile(
                      title: Text(
                        classroom['subject'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SubjectMaterialsPage(
                                  subjectId: classroom['id'],
                                  subjectName: classroom['subject'],
                                  isFaculty: true,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
