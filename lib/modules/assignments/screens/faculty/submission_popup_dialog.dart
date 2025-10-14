import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/assignment_service.dart';
import '../../widgets/submission_card.dart';

class SubmissionPopupDialog extends StatefulWidget {
  final Map<String, dynamic> assignment;
  const SubmissionPopupDialog({super.key, required this.assignment});

  @override
  State<SubmissionPopupDialog> createState() => _SubmissionPopupDialogState();
}

class _SubmissionPopupDialogState extends State<SubmissionPopupDialog> {
  final _service = AssignmentService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    final id = widget.assignment['id'] ?? widget.assignment['assignment_id'];
    _future = _service.getSubmissions(id.toString());
  }

  String _formatDate(dynamic val) {
    if (val == null) return '-';
    if (val is String) {
      final dt = DateTime.tryParse(val);
      if (dt != null) return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    }
    return val.toString();
  }

  /// ✅ Extract roll number correctly from email
  String _extractRollNo(String email) {
    try {
      final localPart = email.split('@').first; // before '@'
      final lastSegment = localPart.split('.').last; // after last '.'
      return lastSegment.toUpperCase(); // e.g. 25IT001
    } catch (_) {
      return 'Unknown';
    }
  }

  /// ✅ Open Supabase file links properly
  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open file')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0E1B3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.assignment['title'] ?? 'Assignment',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final subs = snap.data ?? [];
            if (subs.isEmpty) {
              return const Center(
                child: Text(
                  'No student submissions yet',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final s = subs[index];
                final rollNo = _extractRollNo(s['student_email'] ?? '');
                return SubmissionCard(
                  studentName: rollNo,
                  email: s['student_email'] ?? '',
                  submittedAt: _formatDate(s['submitted_at']),
                  fileUrl: s['file_url'],
                  marks: s['marks'],
                  onOpenFile:
                      s['file_url'] != null
                          ? () => _openFile(s['file_url'])
                          : null,
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
