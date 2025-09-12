import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SubjectMaterialsPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectMaterialsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectMaterialsPage> createState() => _SubjectMaterialsPageState();
}

class _SubjectMaterialsPageState extends State<SubjectMaterialsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _announcements = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMaterials();
    _loadAnnouncements();
  }

  Future<void> _loadMaterials() async {
    final res = await _supabase
        .from('study_materials')
        .select()
        .eq('subject_id', widget.subjectId)
        .order('created_at', ascending: false);

    setState(() {
      _materials = List<Map<String, dynamic>>.from(res);
    });
  }

  Future<void> _loadAnnouncements() async {
    try {
      final snapshot =
          await _firestore
              .collection('announcements')
              .where('subject_id', isEqualTo: widget.subjectId)
              .orderBy('created_at', descending: true)
              .get();

      setState(() {
        _announcements =
            snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Convert 'created_at' to DateTime if it's a Timestamp
              if (data['created_at'] is Timestamp) {
                data['created_at'] = (data['created_at'] as Timestamp).toDate();
              }
              return data;
            }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading announcements: $e")),
      );
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cannot open link")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening link: $e")));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1976D2);
    const Color cardColor = Color(0xFF1E1E2C);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Materials"), Tab(text: "Announcements")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ----------------- MATERIALS TAB -----------------
          _materials.isEmpty
              ? const Center(child: Text("No materials yet."))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _materials.length,
                itemBuilder: (context, index) {
                  final m = _materials[index];
                  final dateTime =
                      m['created_at'] != null
                          ? DateTime.tryParse(m['created_at'])
                          : null;
                  final formattedTime =
                      dateTime != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(dateTime)
                          : '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (formattedTime.isNotEmpty)
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          if (formattedTime.isNotEmpty)
                            const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  m['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (m['file_url'] != null ||
                                  m['link_url'] != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.open_in_new,
                                    color: Colors.white,
                                  ),
                                  onPressed:
                                      () => _openUrl(
                                        m['file_url'] ?? m['link_url'],
                                      ),
                                ),
                            ],
                          ),
                          if (m['description'] != null &&
                              m['description'].toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                m['description'],
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

          // ----------------- ANNOUNCEMENTS TAB -----------------
          _announcements.isEmpty
              ? const Center(child: Text("No announcements yet."))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final a = _announcements[index];
                  final dateTime = a['created_at'] as DateTime?;
                  final formattedTime =
                      dateTime != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(dateTime)
                          : '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFF1E1E2C),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (formattedTime.isNotEmpty)
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          if (formattedTime.isNotEmpty)
                            const SizedBox(height: 4),
                          Text(
                            a['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (a['description'] != null &&
                              a['description'].toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                a['description'],
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () async {
          if (_tabController.index == 0) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadMaterialPage(subjectId: widget.subjectId),
              ),
            );
            _loadMaterials();
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => UploadAnnouncementPage(subjectId: widget.subjectId),
              ),
            );
            _loadAnnouncements();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ----------------- MATERIALS UPLOAD PAGE -----------------
class UploadMaterialPage extends StatefulWidget {
  final String subjectId;
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = File(result.files.single.path!);

    setState(() {
      _drafts.add({
        'type': 'pdf',
        'file': file,
        'name': result.files.single.name,
      });
    });
  }

  Future<void> _publishMaterials() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _drafts.isEmpty ||
        _titleController.text.trim().isEmpty) {
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
        String? fileUrl;
        if (draft['type'] == 'pdf') {
          final file = draft['file'] as File;
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${draft['name']}';
          await _supabase.storage
              .from('study_materials')
              .upload(fileName, file);
          fileUrl = _supabase.storage
              .from('study_materials')
              .getPublicUrl(fileName);
        }

        await _supabase.from('study_materials').insert({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'file_url': fileUrl,
          'uploaded_by': user.uid,
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
    const primaryColor = Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Material"),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Title",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 41, 40, 40),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: "Description",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 41, 40, 40),
            ),
          ),
          const SizedBox(height: 20),
          if (_drafts.isNotEmpty) ...[
            const Text(
              "Drafts",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ..._drafts.map(
              (d) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(d['name']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _drafts.remove(d)),
                  ),
                ),
              ),
            ),
            const Divider(),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Add PDF"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isPublishing
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                onPressed: _publishMaterials,
                icon: const Icon(Icons.publish),
                label: const Text("Publish"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
        ],
      ),
    );
  }
}

// ----------------- ANNOUNCEMENT UPLOAD PAGE -----------------
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _titleController.text.trim().isEmpty) {
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
        'uploaded_by': user.uid,
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
    const primaryColor = Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Announcement"),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Title",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 41, 40, 40),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: "Description",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 41, 40, 40),
            ),
          ),
          const SizedBox(height: 20),
          _isPublishing
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                onPressed: _publishAnnouncement,
                icon: const Icon(Icons.publish),
                label: const Text("Publish"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
        ],
      ),
    );
  }
}
