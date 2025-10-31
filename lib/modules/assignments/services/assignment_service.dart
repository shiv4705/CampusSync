import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper/service for assignment-related operations (uploads, queries, marks).
class AssignmentService {
  final _supabase = Supabase.instance.client;

  /// Get assignments created by a faculty (filter by email).
  Future<List<Map<String, dynamic>>> getAssignmentsByFaculty(
    String facultyEmail,
  ) async {
    final res = await _supabase
        .from('assignments')
        .select()
        .eq('faculty_email', facultyEmail)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Get assignments for a subject name.
  Future<List<Map<String, dynamic>>> getAssignmentsBySubject(
    String subjectName,
  ) async {
    final res = await _supabase
        .from('assignments')
        .select()
        .eq('subject_name', subjectName)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Upload an assignment file to Supabase storage and return public URL.
  Future<String?> uploadAssignmentFile(
    File file,
    String destinationPath,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      await _supabase.storage
          .from('assignments')
          .uploadBinary(destinationPath, bytes);
      return _supabase.storage
          .from('assignments')
          .getPublicUrl(destinationPath);
    } catch (e) {
      // Log and return null on failure.
      debugPrint('AssignmentService.uploadAssignmentFile error: $e');
      return null;
    }
  }

  /// Create an assignment row and return the inserted map (or null).
  Future<Map<String, dynamic>?> createAssignment({
    required String subjectId,
    required String subjectName,
    required String title,
    String? description,
    required String facultyEmail,
    String? fileUrl,
    DateTime? dueDate,
  }) async {
    final payload = {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'title': title,
      'description': description ?? '',
      'faculty_email': facultyEmail,
      'file_url': fileUrl,
      'due_date': dueDate?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _supabase.from('assignments').insert(payload).select();
    if ((res as List).isEmpty) return null;
    return Map<String, dynamic>.from(res[0]);
  }

  /// Fetch submissions for a given assignment id.
  Future<List<Map<String, dynamic>>> getSubmissions(
    String? assignmentId,
  ) async {
    if (assignmentId == null) return [];

    final res = await _supabase
        .from('student_assignments')
        .select()
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);

    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Upload raw student submission bytes and return public URL.
  Future<String?> uploadStudentSubmission(
    Uint8List bytes,
    String destPath,
  ) async {
    try {
      await _supabase.storage
          .from('student_submissions')
          .uploadBinary(destPath, bytes);
      return _supabase.storage
          .from('student_submissions')
          .getPublicUrl(destPath);
    } catch (e) {
      debugPrint('uploadStudentSubmission error: $e');
      return null;
    }
  }

  /// Insert a submission row into `student_assignments`.
  Future<void> createSubmission(Map<String, dynamic> data) async {
    await _supabase.from('student_assignments').insert(data);
  }

  /// Save marks for a student's submission (assignmentId + studentId).
  Future<void> saveMarks(
    String assignmentId,
    String studentId,
    int marks,
  ) async {
    await _supabase
        .from('student_assignments')
        .update({'marks': marks})
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId);
  }

  /// Convenience alias used by some UI call-sites.
  Future<void> updateMarks(String assignmentId, String studentId, int marks) {
    return saveMarks(assignmentId, studentId, marks);
  }

  /// Open a file URL or convert a storage path to a public URL then launch it.
  Future<void> openFile(String? url) async {
    if (url == null || url.isEmpty || url == "No file") {
      debugPrint("⚠️ No file URL found");
      return;
    }

    String finalUrl = url;

    // If not a full URL → convert storage path to public URL
    if (!url.startsWith("http")) {
      finalUrl = _supabase.storage
          .from('student_submissions')
          .getPublicUrl(url);
    }

    final uri = Uri.tryParse(finalUrl);
    if (uri == null) {
      debugPrint("❌ Invalid URL: $finalUrl");
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not open: $finalUrl");
    }
  }

  /// Show a small dialog for the faculty to enter marks (1-10).
  Future<int?> enterMarksDialog(BuildContext context) async {
    final marksController = TextEditingController();
    String? error;

    return showDialog<int?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Enter Marks (1-10)"),
              content: TextField(
                controller: marksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "7", errorText: error),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(marksController.text.trim());

                    if (val == null || val < 1 || val > 10) {
                      setState(() => error = "Enter number 1-10");
                      return;
                    }

                    Navigator.pop(context, val);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
