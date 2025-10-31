import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/study_material_service.dart';

class UploadMaterialPage extends StatefulWidget {
  final String subjectId;

  /// Upload PDF study materials to Supabase storage and create DB records.
  /// Multiple PDFs can be added as drafts and published together.
  const UploadMaterialPage({super.key, required this.subjectId});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  List<Map<String, dynamic>> _drafts = [];
  bool _isPublishing = false;

  Future<void> _addPdf() async {
    // Pick a PDF from the device and add it to in-memory drafts list.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = File(result.files.single.path!);

    setState(
      () => _drafts.add({'file': file, 'name': result.files.single.name}),
    );
  }

  Future<void> _publishMaterials() async {
    // Upload each drafted PDF to Supabase storage and insert a materials row.
    if (_titleController.text.trim().isEmpty || _drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter title and add at least one material"),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      for (var draft in _drafts) {
        final file = draft['file'] as File;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${draft['name']}';
        await _supabase.storage.from('study_materials').upload(fileName, file);
        final fileUrl = _supabase.storage
            .from('study_materials')
            .getPublicUrl(fileName);

        await _supabase.from('study_materials').insert({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'file_url': fileUrl,
          'subject_id': widget.subjectId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      setState(() => _drafts.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Materials published!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Publish failed: $e")));
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Material")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Description"),
          ),
          const SizedBox(height: 20),
          if (_drafts.isNotEmpty)
            ..._drafts.map(
              (d) => ListTile(
                title: Text(d['name']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => setState(() => _drafts.remove(d)),
                ),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Add PDF"),
          ),
          const SizedBox(height: 12),
          _isPublishing
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                onPressed: _publishMaterials,
                icon: const Icon(Icons.publish),
                label: const Text("Publish"),
              ),
        ],
      ),
    );
  }
}
