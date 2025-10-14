import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_assignment_detail_screen.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  final String subjectName;
  const StudentAssignmentsScreen({super.key, required this.subjectName});

  Future<List<Map<String, dynamic>>> _fetchAssignments() async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('assignments')
        .select()
        .eq('subject_name', subjectName)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFF0D1D50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091227),
        title: Text(subjectName),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAssignments(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(
              child: Text(
                "No assignments found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final ongoing = <Map<String, dynamic>>[];
          final missed = <Map<String, dynamic>>[];

          for (final a in snap.data!) {
            final due = DateTime.tryParse(a['due_date'] ?? '');
            if (due == null || due.isAfter(now)) {
              ongoing.add(a);
            } else {
              missed.add(a);
            }
          }

          Widget section(
            String title,
            List<Map<String, dynamic>> list, {
            bool isMissed = false,
          }) {
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...list.map((a) {
                  final due = DateTime.tryParse(a['due_date'] ?? '');
                  final dueText =
                      due != null
                          ? DateFormat('dd MMM yyyy').format(due)
                          : 'No due date';
                  return Card(
                    color: Colors.white.withOpacity(0.08),
                    child: ListTile(
                      title: Text(
                        a['title'] ?? 'Untitled',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Due: $dueText",
                        style: const TextStyle(color: Colors.white70),
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
                                (_) => StudentAssignmentDetailScreen(
                                  assignment: a,
                                  isMissed: isMissed,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          }

          return ListView(
            children: [
              section("Ongoing Assignments", ongoing),
              section("Completed Assignments", missed, isMissed: true),
            ],
          );
        },
      ),
    );
  }
}
