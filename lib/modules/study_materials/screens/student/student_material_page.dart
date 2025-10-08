import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../faculty/subject_materials_page.dart';

class StudentMaterialPage extends StatefulWidget {
  const StudentMaterialPage({super.key});

  @override
  State<StudentMaterialPage> createState() => _StudentMaterialPageState();
}

class _StudentMaterialPageState extends State<StudentMaterialPage> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      setState(() {
        _subjects =
            snapshot.docs
                .map((doc) => {"id": doc.id, "subject": doc['subject']})
                .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading subjects: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(title: const Text("Subjects"), backgroundColor: darkBlue),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _subjects.isEmpty
              ? const Center(
                child: Text(
                  "No subjects found.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _subjects.length,
                itemBuilder: (context, i) {
                  final subject = _subjects[i];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    child: ListTile(
                      title: Text(
                        subject['subject'],
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
                                  subjectId: subject['id'],
                                  subjectName: subject['subject'],
                                  isFaculty: false, // Students cannot upload
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
