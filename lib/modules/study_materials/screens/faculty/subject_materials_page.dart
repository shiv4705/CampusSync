// ----------------- SUBJECT MATERIALS PAGE -----------------
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'upload_material_page.dart';
import 'upload_announcement_page.dart';

class SubjectMaterialsPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final bool isFaculty; // faculty flag

  const SubjectMaterialsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.isFaculty = false,
  });

  @override
  State<SubjectMaterialsPage> createState() => _SubjectMaterialsPageState();
}

class _SubjectMaterialsPageState extends State<SubjectMaterialsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _materials = [];
  bool _loadingMaterials = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final res = await _supabase
          .from('study_materials')
          .select()
          .eq('subject_id', widget.subjectId)
          .order('created_at', ascending: false);

      setState(() {
        _materials = List<Map<String, dynamic>>.from(res);
        _loadingMaterials = false;
      });
    } catch (e) {
      setState(() => _loadingMaterials = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading materials: $e")));
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open link")));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF091227);
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: darkBlue2,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Materials"), Tab(text: "Announcements")],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue1, darkBlue2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // ----------------- MATERIALS TAB -----------------
            _loadingMaterials
                ? const Center(child: CircularProgressIndicator())
                : _materials.isEmpty
                ? const Center(
                  child: Text(
                    "No materials yet.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
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
                      color: Colors.white.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                                if (m['file_url'] != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _openUrl(m['file_url']),
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
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('announcements')
                      .where('subject_id', isEqualTo: widget.subjectId)
                      .orderBy('created_at', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final announcements = snapshot.data?.docs ?? [];
                if (announcements.isEmpty) {
                  return const Center(
                    child: Text(
                      "No announcements yet.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final a =
                        announcements[index].data() as Map<String, dynamic>;
                    final createdAt = a['created_at'];
                    DateTime? dateTime;
                    if (createdAt is Timestamp) {
                      dateTime = createdAt.toDate();
                    }
                    final formattedTime =
                        dateTime != null
                            ? DateFormat('dd MMM yyyy, HH:mm').format(dateTime)
                            : '';

                    return Card(
                      color: Colors.white.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton:
          widget.isFaculty
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "add_material",
                    child: const Icon(Icons.picture_as_pdf),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => UploadMaterialPage(
                                subjectId: widget.subjectId,
                              ),
                        ),
                      ).then((_) => _loadMaterials());
                    },
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: "add_announcement",
                    child: const Icon(Icons.campaign),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => UploadAnnouncementPage(
                                subjectId: widget.subjectId,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              )
              : null,
    );
  }
}
