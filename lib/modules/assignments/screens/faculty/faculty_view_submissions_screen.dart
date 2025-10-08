// faculty_view_submissions_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FacultyViewSubmissionsScreen extends StatefulWidget {
  const FacultyViewSubmissionsScreen({super.key});

  @override
  State<FacultyViewSubmissionsScreen> createState() =>
      _FacultyViewSubmissionsScreenState();
}

class _FacultyViewSubmissionsScreenState
    extends State<FacultyViewSubmissionsScreen> {
  final supabase = Supabase.instance.client;

  Future<List<String>> _getFacultySubjects() async {
    final facultyEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    final res = await supabase
        .from('assignments')
        .select('subject_name')
        .eq('faculty_email', facultyEmail);

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
    final cardColor = Theme.of(context).cardColor;

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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                color: cardColor,
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    subject,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SubjectAssignmentsScreen(subject: subject),
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

/// Assignments for a specific subject only
class SubjectAssignmentsScreen extends StatelessWidget {
  final String subject;
  final supabase = Supabase.instance.client;

  SubjectAssignmentsScreen({super.key, required this.subject});

  Future<List<Map<String, dynamic>>> _fetchAssignments() async {
    final facultyEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    final res = await supabase
        .from('assignments')
        .select()
        .eq('faculty_email', facultyEmail)
        .eq('subject_name', subject)
        .order('due_date', ascending: true);

    final data = res as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) return DateTime.tryParse(val);
    if (val is DateTime) return val;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAssignments(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignments = snap.data ?? [];
          if (assignments.isEmpty) {
            return const Center(child: Text("No assignments uploaded"));
          }

          final now = DateTime.now();
          final ongoing = <Map<String, dynamic>>[];
          final completed = <Map<String, dynamic>>[];

          for (final a in assignments) {
            final due = _parseDate(a['due_date']);
            if (due == null || !due.isBefore(now)) {
              ongoing.add(a);
            } else {
              completed.add(a);
            }
          }

          Widget section(String title, List<Map<String, dynamic>> list) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...list.map((a) {
                  final due = _parseDate(a['due_date']);
                  final dueText =
                      due != null ? DateFormat('dd MMM yyyy').format(due) : '-';
                  final titleText = a['title'] ?? 'Untitled';
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Due: $dueText'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AssignmentDetailScreen(assignment: a),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            );
          }

          return ListView(
            children: [
              if (ongoing.isNotEmpty) section('Ongoing Assignments', ongoing),
              if (completed.isNotEmpty)
                section('Completed Assignments', completed),
            ],
          );
        },
      ),
    );
  }
}

/// Assignment detail + submissions
class AssignmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchSubmissions() async {
    final assignmentId = widget.assignment['id'];
    if (assignmentId == null) return [];

    final res = await supabase
        .from('student_assignments')
        .select()
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);

    final data = res as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _openFile(String url) async {
    if (url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerPage(fileUrl: url)),
      );
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Could not open file")));
        }
      }
    }
  }

  Future<void> _saveMarks(int submissionId, int marks) async {
    try {
      final res =
          await supabase
              .from('student_assignments')
              .update({'marks': marks})
              .eq('id', submissionId)
              .select();

      if (res.isEmpty && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving marks')));
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Marks saved')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving marks: $e')));
      }
    }
  }

  String _formatDate(dynamic val) {
    if (val == null) return '-';
    if (val is String) {
      final dt = DateTime.tryParse(val);
      if (dt != null) return DateFormat('dd MMM yyyy, HH:mm').format(dt);
      return val;
    }
    if (val is DateTime) return DateFormat('dd MMM yyyy, HH:mm').format(val);
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final title = a['title'] ?? 'Untitled';
    final desc = a['description'] ?? '';
    final due = a['due_date'];
    final fileUrl = a['file_url'];
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              color: cardColor,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if ((desc as String).trim().isNotEmpty) Text(desc),
                    const SizedBox(height: 8),
                    Text('Due: ${_formatDate(due)}'),
                    if (fileUrl != null)
                      TextButton.icon(
                        onPressed: () => _openFile(fileUrl as String),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Assignment File'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchSubmissions(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final subs = snap.data ?? [];
                  if (subs.isEmpty) {
                    return const Center(
                      child: Text('No student has submitted it.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: subs.length,
                    itemBuilder: (context, idx) {
                      final sub = subs[idx];
                      final sid = sub['id'];
                      final studentEmail = sub['student_email'] ?? '-';
                      final parts = studentEmail.split('.');
                      final studentRollNumber =
                          parts.length >= 3
                              ? parts[2].split('@')[0]
                              : studentEmail;
                      final submittedAt = sub['submitted_at'];
                      final subFile = sub['file_url'];
                      final marksVal = sub['marks'];
                      final controller = TextEditingController(
                        text: marksVal != null ? marksVal.toString() : '',
                      );
                      final isMarksSaved = marksVal != null;

                      return Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentRollNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Email: $studentEmail'),
                              const SizedBox(height: 4),
                              Text('Submitted: ${_formatDate(submittedAt)}'),
                              if (subFile != null)
                                TextButton.icon(
                                  onPressed: () => _openFile(subFile as String),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Open File'),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      enabled: !isMarksSaved,
                                      decoration: const InputDecoration(
                                        labelText: 'Marks (0-10)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed:
                                        isMarksSaved
                                            ? null
                                            : () {
                                              final input =
                                                  controller.text.trim();
                                              final parsed = int.tryParse(
                                                input,
                                              );
                                              if (parsed == null ||
                                                  parsed < 0 ||
                                                  parsed > 10) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Enter marks between 0–10',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              if (sid != null) {
                                                _saveMarks(
                                                  sid is int
                                                      ? sid
                                                      : int.tryParse(
                                                            sid.toString(),
                                                          ) ??
                                                          sid,
                                                  parsed,
                                                );
                                              }
                                            },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PDF Viewer page
class PdfViewerPage extends StatelessWidget {
  final String fileUrl;
  const PdfViewerPage({super.key, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View PDF')),
      body: SfPdfViewer.network(fileUrl),
    );
  }
}
