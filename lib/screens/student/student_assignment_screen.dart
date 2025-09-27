import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// 1. Subject List Screen
class StudentAssignmentSubjectsScreen extends StatelessWidget {
  const StudentAssignmentSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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

/// 2. Assignment List Screen
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
              section("Missed Assignments", missed, isMissed: true),
            ],
          );
        },
      ),
    );
  }
}

/// 3. Assignment Detail & Submission
class StudentAssignmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final bool isMissed;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.isMissed,
  });

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  final supabase = Supabase.instance.client;
  final user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  Future<Map<String, dynamic>?> _fetchSubmission() async {
    if (user == null) return null;
    final res =
        await supabase
            .from('student_assignments')
            .select()
            .eq('assignment_id', widget.assignment['id'])
            .eq('student_id', user!.uid)
            .maybeSingle();
    return res;
  }

  Future<void> _uploadSubmission() async {
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first.")));
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No file selected.")));
        return;
      }

      setState(() => _isUploading = true);

      Uint8List? fileBytes = result.files.single.bytes;
      if (fileBytes == null && result.files.single.path != null) {
        fileBytes = await File(result.files.single.path!).readAsBytes();
      }

      if (fileBytes == null) throw Exception("Failed to read file bytes.");

      final fileName =
          "${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.pdf";

      await supabase.storage
          .from('student_submissions')
          .uploadBinary(fileName, fileBytes);

      final fileUrl = supabase.storage
          .from('student_submissions')
          .getPublicUrl(fileName);

      await supabase.from('student_assignments').insert({
        'assignment_id': widget.assignment['id'],
        'subject_name': widget.assignment['subject_name'] ?? 'Unknown Subject',
        'student_id': user!.uid,
        'student_email': user!.email,
        'file_url': fileUrl,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Submission uploaded!")));
      setState(() => _isUploading = false);
      setState(() {}); // refresh
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String _formatDate(dynamic val) {
    if (val == null) return '-';
    final dt = DateTime.tryParse(val.toString());
    return dt != null ? DateFormat('dd MMM yyyy, HH:mm').format(dt) : '-';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open file")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1D50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091227),
        title: Text(a['title'] ?? 'Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchSubmission(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final submission = snap.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a['description'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  "Due: ${_formatDate(a['due_date'])}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                if (a['file_url'] != null)
                  TextButton.icon(
                    onPressed: () => _openFile(a['file_url']),
                    icon: const Icon(Icons.open_in_new, color: Colors.blue),
                    label: const Text(
                      "Open Assignment File",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                const Divider(color: Colors.white30),
                Expanded(
                  child:
                      submission != null
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "You have submitted this assignment.",
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Submitted at: ${_formatDate(submission['submitted_at'])}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Marks: ${submission['marks'] ?? '-'}/10",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                          : widget.isMissed
                          ? const Center(
                            child: Text(
                              "You missed this assignment.",
                              style: TextStyle(color: Colors.red),
                            ),
                          )
                          : Center(
                            child:
                                _isUploading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton.icon(
                                      onPressed: _uploadSubmission,
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text("Upload Submission"),
                                    ),
                          ),
                ),
              ],
            );
          },
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
