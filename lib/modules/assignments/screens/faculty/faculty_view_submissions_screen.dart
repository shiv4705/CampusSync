import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'submission_popup_dialog.dart'; // <-- import your existing popup

class FacultyViewSubmissionsScreen extends StatelessWidget {
  const FacultyViewSubmissionsScreen({super.key});

  Future<List<String>> _getFacultySubjects() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final supabase = Supabase.instance.client;

    final res = await supabase
        .from('subjects')
        .select('subject')
        .eq('facultyId', FirebaseAuth.instance.currentUser?.uid ?? '');

    final data = res as List<dynamic>? ?? [];
    return data.map((e) => e['subject'] as String).toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Submissions')),
      body: FutureBuilder<List<String>>(
        future: _getFacultySubjects(),
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
              return Card(
                color: const Color(0xFF162447),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    subject,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tap to view student submissions',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => SubmissionPopupDialog(
                            assignment: {
                              'title': subject,
                              'id': subject.hashCode, // unique placeholder id
                            },
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
