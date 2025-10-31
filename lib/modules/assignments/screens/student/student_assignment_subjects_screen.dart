import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'student_assignment_screen.dart';

/// Shows all available subjects to students; tapping a subject opens its assignments.
class StudentAssignmentSubjectsScreen extends StatelessWidget {
  const StudentAssignmentSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Simple gate: student must be logged in to view assignments.
      return const Scaffold(
        backgroundColor: Color(0xFF0D1D50),
        body: Center(
          child: Text(
            "Please login to view assignments",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1D50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091227),
        title: const Text("Assignments"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No subjects found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final subjects = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subjectName = subjects[index]['subject'] ?? '';
              return Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    subjectName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                  ),
                  onTap: () {
                    // Open the student assignments list for this subject.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => StudentAssignmentsScreen(
                              subjectName: subjectName,
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
