// assignment_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentService {
  final _supabase = Supabase.instance.client;

  /// Fetch assignments uploaded by a faculty (by faculty email)
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

  /// Fetch assignments for a subject
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

  /// Upload file using a File object (returns public URL or null)
  Future<String?> uploadAssignmentFile(
    File file,
    String destinationPath,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = destinationPath; // full path (can include folders)
      // Supabase storage expects bytes for uploadBinary or file via multipart; here use uploadBinary
      await _supabase.storage.from('assignments').uploadBinary(fileName, bytes);
      final publicUrl = _supabase.storage
          .from('assignments')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('AssignmentService.uploadAssignmentFile error: $e');
      return null;
    }
  }

  /// Insert assignment metadata row
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
    if (res == null || (res as List).isEmpty) return null;
    return Map<String, dynamic>.from(res[0]);
  }

  /// Fetch submissions for an assignment ID
  Future<List<Map<String, dynamic>>> getSubmissions(int assignmentId) async {
    final res = await _supabase
        .from('student_assignments')
        .select()
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Upload student submission bytes
  Future<String?> uploadStudentSubmission(
    Uint8List bytes,
    String destPath,
  ) async {
    try {
      await _supabase.storage
          .from('student_submissions')
          .uploadBinary(destPath, bytes);
      final publicUrl = _supabase.storage
          .from('student_submissions')
          .getPublicUrl(destPath);
      return publicUrl;
    } catch (e) {
      print('uploadStudentSubmission error: $e');
      return null;
    }
  }

  /// Save submission record
  Future<void> createSubmission(Map<String, dynamic> data) async {
    await _supabase.from('student_assignments').insert(data);
  }

  /// Save marks for a submission row (by id)
  Future<void> saveMarks(int submissionId, int marks) async {
    await _supabase
        .from('student_assignments')
        .update({'marks': marks})
        .eq('id', submissionId);
  }
}
