import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/assignment_service.dart';
import '../../widgets/submission_card.dart';
import 'submission_popup_dialog.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String subject;
  const AssignmentDetailScreen({super.key, required this.subject});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final _service = AssignmentService();

  Future<List<Map<String, dynamic>>> _fetchAssignments() async {
    return await _service.getAssignmentsBySubject(widget.subject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subject)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAssignments(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text("No assignments found"));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final a = data[i];
              final due =
                  a['due_date'] != null
                      ? DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(a['due_date']))
                      : '-';
              return Card(
                color: Colors.white.withOpacity(0.06),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Text(
                    a['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "Due: $due",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
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
