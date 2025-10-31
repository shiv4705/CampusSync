import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'submission_popup_dialog.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String subject;
  const AssignmentDetailScreen({super.key, required this.subject});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  Future<List<Map<String, dynamic>>> _getAssignments() async {
    final supabase = Supabase.instance.client;

    final res = await supabase
        .from('assignments')
        .select()
        .eq('subject_name', widget.subject)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1D50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091227),
        title: Text("${widget.subject} - Assignments"),
      ),
      body: FutureBuilder(
        future: _getAssignments(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignments = snap.data!;
          if (assignments.isEmpty) {
            return const Center(
              child: Text(
                "No assignments for this subject",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: assignments.length,
            itemBuilder: (_, i) {
              final a = assignments[i];
              return Card(
                color: const Color(0xFF162447),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    a['title'] ?? "",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Due: ${a['due_date'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => SubmissionPopupDialog(assignment: a),
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
