import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectMaterialsPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectMaterialsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectMaterialsPage> createState() => SubjectMaterialsPageState();
}

class SubjectMaterialsPageState extends State<SubjectMaterialsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _supabase
                  .from('study_materials')
                  .select()
                  .eq('subject_id', widget.subjectId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final materials = snapshot.data ?? [];
                if (materials.isEmpty) {
                  return const Center(
                    child: Text(
                      "No materials yet.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final m = materials[index];
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
    );
  }
}
