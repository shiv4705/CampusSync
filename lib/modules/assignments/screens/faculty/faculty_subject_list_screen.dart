// lib/modules/assignments/screens/faculty/faculty_subject_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'faculty_assignment_upload_screen.dart';
import 'faculty_view_submissions_screen.dart';
import '../../widgets/assignment_card.dart';

enum AssignmentMode { upload, viewSubmissions }

class FacultySubjectListScreen extends StatelessWidget {
  final AssignmentMode mode;
  const FacultySubjectListScreen({super.key, required this.mode});

  /// Fetch subjects documents assigned to current faculty
  Future<List<Map<String, dynamic>>> _fetchSubjectsForFaculty() async {
    final facultyId = FirebaseAuth.instance.currentUser?.uid;
    if (facultyId == null || facultyId.isEmpty) return [];

    final snap =
        await FirebaseFirestore.instance
            .collection('subjects')
            .where('facultyId', isEqualTo: facultyId)
            .get();

    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  /// Extract leading subject code from "DSA102 - Data Structures & Algorithms"
  String _extractSubjectCode(String subjectString) {
    // try split by ' - ' first, then fallback to first token
    final parts = subjectString.split(RegExp(r'\s*-\s*'));
    final left = parts.isNotEmpty ? parts[0] : subjectString;
    // extract alnum prefix (e.g. DSA102)
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
                    // faculty_assignment_upload_screen.dart expects (subjectId, subjectName)
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
                    // faculty_view_submissions_screen.dart in your repo doesn't take a subjectName param
                    // It itself lists subjects and then opens SubjectAssignmentsScreen.
                    // Use the existing screen (no named parameter) to avoid the "named parameter not defined" error.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FacultyViewSubmissionsScreen(),
                      ),
                    );
                    // If you want to directly open the subject's submissions screen here,
                    // and you have access to SubjectAssignmentsScreen in your imports,
                    // replace the above with:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectAssignmentsScreen(subject: subjectDisplay)));
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
