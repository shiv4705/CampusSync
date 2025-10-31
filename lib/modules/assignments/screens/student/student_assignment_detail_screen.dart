import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_page.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  /// Shows assignment details to a student and allows submitting a PDF.
  /// `assignment` is the row data and `isMissed` marks whether deadline passed.
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
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  String? _uploadedFileUrl;

  /// Fetch current student's submission (if any) for this assignment.
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

  /// Let the student pick a PDF; stores bytes for upload/preview.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;
    setState(() {
      _pickedFileBytes = result.files.single.bytes;
      _pickedFileName = result.files.single.name; // original file name
    });
  }

  /// Preview the picked file (writes bytes to temp file) or open uploaded URL.
  void _previewPickedFile() {
    if (_pickedFileBytes != null) {
      final tempFile = File("${Directory.systemTemp.path}/$_pickedFileName");
      tempFile.writeAsBytesSync(_pickedFileBytes!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(fileUrl: tempFile.path),
        ),
      );
    } else if (_uploadedFileUrl != null) {
      _openFile(_uploadedFileUrl!);
    }
  }

  /// Upload the picked file to Supabase storage and insert a submission row.
  Future<void> _submitFile() async {
    if (_pickedFileBytes == null) return;
    setState(() => _isUploading = true);

    try {
      await supabase.storage
          .from('student_submissions')
          .uploadBinary(_pickedFileName!, _pickedFileBytes!);

      final fileUrl = supabase.storage
          .from('student_submissions')
          .getPublicUrl(_pickedFileName!);

      await supabase.from('student_assignments').insert({
        'assignment_id': widget.assignment['id'],
        'subject_name': widget.assignment['subject_name'] ?? 'Unknown Subject',
        'student_id': user!.uid,
        'student_email': user!.email,
        'file_url': fileUrl,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submission uploaded successfully!")),
      );

      setState(() {
        _uploadedFileUrl = fileUrl;
        _pickedFileBytes = null;
        _pickedFileName = null;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// Helper to render ISO date strings into human readable form.
  String _formatDate(dynamic val) {
    if (val == null) return '-';
    final dt = DateTime.tryParse(val.toString());
    return dt != null ? DateFormat('dd MMM yyyy, HH:mm').format(dt) : '-';
  }

  /// Open a URL; PDFs open in-app, other URLs are launched externally.
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

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: const Color(0xFF162447),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a['description'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Due Date: ${_formatDate(a['due_date'])}",
                            style: const TextStyle(color: Colors.orangeAccent),
                          ),
                          const SizedBox(height: 10),
                          if (a['file_url'] != null)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                              onPressed: () => _openFile(a['file_url']),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text("Open Assignment File"),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openFile(submission['file_url']),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text("View Submitted File"),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_pickedFileBytes != null)
                              Column(
                                children: [
                                  Text(
                                    "Selected File: $_pickedFileName",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _pickedFileBytes = null;
                                            _pickedFileName = null;
                                          });
                                        },
                                        icon: const Icon(Icons.cancel),
                                        label: const Text("Cancel"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed:
                                            _isUploading ? null : _submitFile,
                                        icon: const Icon(Icons.check),
                                        label: const Text("Turned In"),
                                      ),
                                      const SizedBox(width: 8),
                                      // Preview the picked PDF before submitting.
                                      ElevatedButton.icon(
                                        onPressed: _previewPickedFile,
                                        icon: const Icon(Icons.preview),
                                        label: const Text('Preview'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Pick PDF"),
                              ),
                            if (_isUploading)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: CircularProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
