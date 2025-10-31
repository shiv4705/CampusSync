// faculty_assignment_upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/assignment_service.dart';

/// Screen for faculty to upload an assignment PDF for a subject.
/// Handles picking a file, optional due date and creating the assignment row.

class FacultyAssignmentUploadScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const FacultyAssignmentUploadScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<FacultyAssignmentUploadScreen> createState() =>
      _FacultyAssignmentUploadScreenState();
}

class _FacultyAssignmentUploadScreenState
    extends State<FacultyAssignmentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _pickedFile;
  DateTime? _dueDate;
  bool _isUploading = false;

  final _service = AssignmentService();

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (res != null && res.files.single.path != null) {
      setState(() => _pickedFile = File(res.files.single.path!));
    }
  }

  /// Pick a PDF file from device storage (does not load bytes into memory).

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isUploading = true);

    try {
      String? fileUrl;
      if (_pickedFile != null) {
        // Create a namespaced destination path to avoid collisions.
        final destPath =
            '${user.email}/${widget.subjectName}/${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.path.split('/').last}';
        fileUrl = await _service.uploadAssignmentFile(_pickedFile!, destPath);
        if (fileUrl == null) throw Exception('File upload failed');
      }

      final inserted = await _service.createAssignment(
        subjectId: widget.subjectId,
        subjectName: widget.subjectName,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        facultyEmail: user.email ?? '',
        fileUrl: fileUrl,
        dueDate: _dueDate,
      );

      if (inserted == null)
        throw Exception('Failed to insert assignment record');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment uploaded: ${inserted['title']}')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Dispose controllers to avoid memory leaks.

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: Text('Upload - ${widget.subjectName}')),
      body:
          _isUploading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Enter title'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickPdf,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Pick PDF'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _pickedFile != null
                                  ? _pickedFile!.path.split('/').last
                                  : 'No file chosen',
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
                          if (picked != null) setState(() => _dueDate = picked);
                        },
                        child: Text(
                          _dueDate == null
                              ? 'Pick due date'
                              : 'Due: ${_dueDate!.toLocal().toIso8601String().split("T")[0]}',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Upload Assignment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
