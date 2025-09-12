import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_materials_page.dart';

class FacultyClassroomPage extends StatefulWidget {
  const FacultyClassroomPage({super.key});

  @override
  State<FacultyClassroomPage> createState() => _FacultyClassroomPageState();
}

class _FacultyClassroomPageState extends State<FacultyClassroomPage> {
  List<Map<String, dynamic>> _facultySubjects = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignedSubjects();
  }

  Future<void> _fetchAssignedSubjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('subjects')
            .where('facultyId', isEqualTo: user.uid)
            .get();

    setState(() {
      _facultySubjects =
          snapshot.docs
              .map((doc) => {"id": doc.id, "subject": doc['subject']})
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue2 = Color(0xFF0D1D50);
    const cardColor = Colors.white24;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Subjects"),
        backgroundColor: darkBlue2,
        elevation: 0,
      ),
      backgroundColor: darkBlue2,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              _facultySubjects.isEmpty
                  ? const Center(
                    child: Text(
                      "No subjects assigned.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                  : GridView.builder(
                    itemCount: _facultySubjects.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (context, index) {
                      final subject = _facultySubjects[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SubjectMaterialsPage(
                                    subjectId: subject['id'],
                                    subjectName: subject['subject'],
                                  ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: cardColor.withOpacity(0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.book,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: Text(
                                    subject['subject'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
