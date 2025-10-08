// faculty_subject_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'faculty_assignment_upload_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'faculty_view_submissions_screen.dart';
import '../../widgets/assignment_card.dart';

/// Mode enum for this page
enum AssignmentMode { upload, viewSubmissions }

class FacultySubjectListScreen extends StatelessWidget {
  final AssignmentMode mode;

  const FacultySubjectListScreen({super.key, required this.mode});

  Future<List<String>> _getAssignedSubjects() async {
    final facultyEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    final supabase = Supabase.instance.client; // Ensure Supabase is initialized in your app's main function
    final res = await supabase
        .from('assignments')
        .select('subject_name')
        .eq('faculty_email', facultyEmail);

    if (res == null) return [];

    final data = res as List<dynamic>? ?? [];
    final subjects =
        data
            .map((r) => (r as Map<String, dynamic>)['subject_name'] as String)
            .toSet()
            .toList();

    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    final isUpload = mode == AssignmentMode.upload;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpload ? 'Upload Assignment' : 'View Submissions'),
      ),
      body: FutureBuilder<List<String>>(
        future: _getAssignedSubjects(),
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
              final subject = subjects[index];
              return AssignmentCard(
                title: subject,
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
                              subjectId:
                                  '', // keep empty; handled in upload screen
                              subjectName: subject,
                            ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FacultyViewSubmissionsScreen(),
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
