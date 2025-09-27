import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'faculty_assignment_upload_screen.dart';

class FacultySubjectListScreen extends StatelessWidget {
  const FacultySubjectListScreen({super.key});

  /// ✅ Fetch subjects assigned to this faculty
  Future<List<Map<String, dynamic>>> _getAssignedSubjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot =
        await FirebaseFirestore.instance
            .collection('subjects')
            .where('facultyId', isEqualTo: user.uid) // match facultyId field
            .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) {
      return {'id': doc.id, 'subject': doc['subject'] as String};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Subjects")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAssignedSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No subjects assigned"));
          }

          final subjects = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(subject['subject']),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => FacultyAssignmentUploadScreen(
                              subjectId: subject['id'],
                              subjectName: subject['subject'],
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
