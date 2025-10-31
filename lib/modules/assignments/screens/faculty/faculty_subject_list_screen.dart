// lib/modules/assignments/screens/faculty/faculty_subject_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'faculty_assignment_upload_screen.dart';
import '../../widgets/assignment_card.dart';
import 'assignment_detail_screen.dart';

enum AssignmentMode { upload, viewSubmissions }

class FacultySubjectListScreen extends StatelessWidget {
  /// Screen that lists subjects assigned to the logged-in faculty.
  /// Mode determines whether tapping a subject uploads an assignment or views submissions.
  final AssignmentMode mode;
  const FacultySubjectListScreen({super.key, required this.mode});

  /// Fetch subjects where the current user is listed as faculty.
  Future<List<Map<String, dynamic>>> _fetchSubjectsForFaculty() async {
    final facultyId = FirebaseAuth.instance.currentUser?.uid;
    if (facultyId == null || facultyId.isEmpty) return [];

    final snap =
        await FirebaseFirestore.instance
            .collection('subjects')
            .where('facultyId', isEqualTo: facultyId)
            .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Extract an alphanumeric subject code from display string (e.g., "CS101 - Intro").
  String _extractSubjectCode(String subjectString) {
    final parts = subjectString.split(RegExp(r'\s*-\s*'));
    final left = parts.isNotEmpty ? parts[0] : subjectString;
    final match = RegExp(r'^[A-Za-z0-9]+').firstMatch(left.trim());
    return match?.group(0) ?? left.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isUpload = mode == AssignmentMode.upload;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpload ? 'Upload Assignment' : 'View Submissions'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSubjectsForFaculty(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snap.data ?? [];
          if (subjects.isEmpty) {
            return const Center(child: Text("No subjects assigned"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final sub = subjects[index];
              final subjStr =
                  (sub['subject'] ?? sub['subjectName'] ?? '').toString();
              final subjectDisplay =
                  subjStr.isNotEmpty ? subjStr : 'Unknown Subject';
              final subjectCode = _extractSubjectCode(subjectDisplay);

              return AssignmentCard(
                title: subjectDisplay,
                subtitle:
                    isUpload
                        ? 'Tap to upload assignment'
                        : 'Tap to view submissions',
                onTap: () {
                  if (isUpload) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => FacultyAssignmentUploadScreen(
                              subjectId: subjectCode,
                              subjectName: subjectDisplay,
                            ),
                      ),
                    );
                  } else {
                    // Navigate to list of assignments and their submissions for the subject.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                AssignmentDetailScreen(subject: subjectDisplay),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
