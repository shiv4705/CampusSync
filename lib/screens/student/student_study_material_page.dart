import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_materials_page_student.dart';

class StudentStudyMaterialPage extends StatefulWidget {
  const StudentStudyMaterialPage({super.key});

  @override
  State<StudentStudyMaterialPage> createState() =>
      _StudentStudyMaterialPageState();
}

class _StudentStudyMaterialPageState extends State<StudentStudyMaterialPage> {
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('subjects').get();

    setState(() {
      _subjects =
          snapshot.docs
              .map((doc) => {"id": doc.id, "subject": doc['subject']})
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF091227);
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        title: const Text(
          "Study Materials",
          style: TextStyle(fontWeight: FontWeight.bold),
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
        child:
            _subjects.isEmpty
                ? const Center(
                  child: Text(
                    "No subjects available.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
                : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
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
                        color: Colors.white.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        elevation: 4,
                        child: Center(
                          child: Text(
                            subject['subject'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
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
