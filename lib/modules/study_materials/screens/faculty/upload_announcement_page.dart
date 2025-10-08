import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/announcement_service.dart';

class UploadAnnouncementPage extends StatefulWidget {
  final String subjectId;
  const UploadAnnouncementPage({super.key, required this.subjectId});

  @override
  State<UploadAnnouncementPage> createState() => _UploadAnnouncementPageState();
}

class _UploadAnnouncementPageState extends State<UploadAnnouncementPage> {
  final _firestore = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPublishing = false;

  Future<void> _publishAnnouncement() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter title for announcement")),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await _firestore.collection('announcements').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'subject_id': widget.subjectId,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Announcement published!")));
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
      appBar: AppBar(title: const Text("Upload Announcement")),
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
          _isPublishing
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                onPressed: _publishAnnouncement,
                icon: const Icon(Icons.publish),
                label: const Text("Publish"),
              ),
        ],
      ),
    );
  }
}
