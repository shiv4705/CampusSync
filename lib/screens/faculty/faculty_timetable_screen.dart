import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FacultyTimetableScreen extends StatelessWidget {
  const FacultyTimetableScreen({super.key});

  static const List<String> weekdayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const List<String> timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];

  int getDayIndex(String? day) {
    final normalized = (day ?? '').trim().toLowerCase().capitalize();
    return weekdayOrder.indexOf(normalized);
  }

  int getTimeIndex(String? time) {
    final normalized = (time ?? '').trim();
    return timeSlots.indexOf(normalized);
  }

  String buildSubjectText(Map<String, dynamic> data) {
    final oldSubject = (data['subject'] ?? '').toString();
    final code = (data['subjectCode'] ?? '').toString();
    final name = (data['subjectName'] ?? '').toString();

    if (oldSubject.isNotEmpty) return oldSubject;
    if (code.isNotEmpty && name.isNotEmpty) return "$code - $name";
    if (code.isNotEmpty) return code;
    if (name.isNotEmpty) return name;
    return "Unknown Subject";
  }

  String buildFacultyText(Map<String, dynamic> data) {
    final old = (data['faculty'] ?? '').toString();
    final newer = (data['facultyName'] ?? '').toString();
    if (newer.isNotEmpty) return newer;
    if (old.isNotEmpty) return old;
    return "Unknown Faculty";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final facultyEmail = currentUser.email ?? '';
    final facultyUid = currentUser.uid;
    final facultyDisplayName = currentUser.displayName ?? '';

    const Color darkBlue1 = Color(0xFF091227);
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        title: const Text(
          "My Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
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
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('timetable').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error loading timetable",
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];

            // Include both old (email) and new (facultyId / facultyName) matches
            final docs =
                allDocs.where((d) {
                  final data = (d.data() as Map<String, dynamic>);
                  final email = (data['email'] ?? '').toString();
                  final fid = (data['facultyId'] ?? '').toString();
                  final fname = (data['facultyName'] ?? '').toString();
                  return email == facultyEmail ||
                      fid == facultyUid ||
                      (fname.isNotEmpty && fname == facultyDisplayName);
                }).toList();

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No timetable entries found.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            final sortedDocs =
                docs.toList()..sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  final dayA = getDayIndex(dataA['day']);
                  final dayB = getDayIndex(dataB['day']);
                  if (dayA != dayB) return dayA.compareTo(dayB);

                  final timeA = getTimeIndex(dataA['time']);
                  final timeB = getTimeIndex(dataB['time']);
                  return timeA.compareTo(timeB);
                });

            // Group timetable by day
            final Map<String, List<Map<String, dynamic>>> timetableByDay = {};
            for (var doc in sortedDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final day = (data['day'] ?? 'Unknown').toString();
              timetableByDay.putIfAbsent(day, () => []).add(data);
            }

            return ListView(
              padding: const EdgeInsets.all(12),
              children:
                  weekdayOrder.map((day) {
                    final dayClasses = timetableByDay[day] ?? [];

                    return Card(
                      color: Colors.white.withOpacity(0.06),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        iconColor: Colors.blueAccent,
                        collapsedIconColor: Colors.white70,
                        title: Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        children:
                            dayClasses.isEmpty
                                ? [
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      "No classes scheduled.",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ]
                                : dayClasses.map((data) {
                                  final subjectText = buildSubjectText(data);
                                  final time =
                                      (data['time'] ?? 'N/A').toString();
                                  final type =
                                      (data['type'] ?? 'Lecture').toString();
                                  final semester =
                                      (data['semester'] ?? '-').toString();
                                  final room = (data['room'] ?? '-').toString();

                                  return Card(
                                    color: Colors.white.withOpacity(0.08),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      title: Text(
                                        subjectText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "$time • $type",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            "Semester: $semester • Room: $room",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ),
    );
  }
}

// ✅ Capitalize extension
extension CapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
