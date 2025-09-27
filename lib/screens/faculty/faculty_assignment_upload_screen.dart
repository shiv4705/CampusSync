// FacultyAssignmentUploadScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacultyAssignmentUploadScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const FacultyAssignmentUploadScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  _FacultyAssignmentUploadScreenState createState() =>
      _FacultyAssignmentUploadScreenState();
}

class _FacultyAssignmentUploadScreenState
    extends State<FacultyAssignmentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _pickedFile;
  DateTime? _dueDate;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  /// Pick PDF file
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
      });
    }
  }

  /// Upload to Supabase storage (assignments bucket)
  Future<String?> _uploadToSupabase(File file) async {
    try {
      final fileName =
          "assignment_${DateTime.now().millisecondsSinceEpoch}.pdf";

      // Upload file to Supabase bucket "assignments"
      await supabase.storage.from("assignments").upload(fileName, file);

      // Get public URL
      final fileUrl = supabase.storage
          .from("assignments")
          .getPublicUrl(fileName);

      return fileUrl;
    } catch (e) {
      print("Supabase Upload Error: $e");
      return null;
    }
  }

  /// Upload assignment metadata to Supabase table "assignments"
  Future<void> _uploadAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Please select a due date")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fileUrl;

      // Upload the file to Supabase if a file is picked
      if (_pickedFile != null) {
        fileUrl = await _uploadToSupabase(_pickedFile!);
        if (fileUrl == null) {
          throw Exception("Failed to upload PDF to Supabase");
        }
      }

      final user = FirebaseAuth.instance.currentUser;

      // Insert assignment details into the Supabase "assignments" table
      final inserted =
          await supabase.from("assignments").insert({
            "subject_id": widget.subjectId,
            "subject_name": widget.subjectName,
            "title": _titleController.text.trim(),
            "description": _descController.text.trim(),
            "due_date": _dueDate?.toIso8601String(),
            "faculty_email": user?.email,
            "file_url": fileUrl,
            "created_at": DateTime.now().toIso8601String(),
          }).select();

      // Retrieve the uploaded assignment title
      final uploadedTitle =
          inserted.isNotEmpty
              ? inserted[0]['title']
              : _titleController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ '$uploadedTitle' uploaded for ${widget.subjectName}",
          ),
        ),
      );

      Navigator.pop(context);
    } on PostgrestException catch (e) {
      // Handle Supabase-specific errors
      print("Supabase Insert Error: ${e.message}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Supabase Error: ${e.message}")));
    } catch (e) {
      // Handle general errors
      print("General Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Assignment - ${widget.subjectName}")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: "Title"),
                          validator:
                              (val) => val!.isEmpty ? "Enter title" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: "Description",
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.attach_file),
                              label: const Text("Pick PDF"),
                            ),
                            const SizedBox(width: 8),
                            if (_pickedFile != null)
                              Expanded(
                                child: Text(
                                  _pickedFile!.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: Text(
                            _dueDate == null
                                ? "Pick Due Date"
                                : "Due: ${_dueDate!.toLocal().toString().split(" ")[0]}",
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _uploadAssignment,
                          child: const Text("Upload Assignment"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
