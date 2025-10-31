import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/timetable_service.dart';
import '../../widgets/timetable_table.dart';

class StudentTimetableScreen extends StatelessWidget {
  /// Student view of the class timetable for a semester.
  /// Shows a grid table and day-wise details derived from timetable documents.
  StudentTimetableScreen({super.key});

  final String semester = '7';
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];
  final List<String> times = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];

  String subjectCodeOnly(Map<String, dynamic> data) {
    final oldSubject = (data['subject'] ?? '').toString();
    if (oldSubject.isNotEmpty) {
      final parts = oldSubject.split(' - ');
      if (parts.isNotEmpty && parts.first.trim().isNotEmpty)
        return parts.first.trim();
      return oldSubject.split(' ').first;
    }
    final code = (data['subjectCode'] ?? '').toString();
    return code;
  }

  String facultyName(Map<String, dynamic> data) {
    final old = (data['faculty'] ?? '').toString();
    final newer = (data['facultyName'] ?? '').toString();
    if (newer.isNotEmpty) return newer;
    if (old.isNotEmpty) return old;
    return "Unknown Faculty";
  }

  @override
  Widget build(BuildContext context) {
    // color constant used by the scaffold background
    const Color darkBlue2 = Color(0xFF0D1D50);
    final timetableService = TimetableService();

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        title: const Text("Class Timetable"),
        backgroundColor: darkBlue2,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: timetableService.getTimetableStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading timetable",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          final docs =
              allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final sem = data['semester'];
                return sem == null || sem.toString() == semester;
              }).toList();

          // Prepare timetable grid (day->time->cell) and a day-wise details list.
          Map<String, Map<String, Map<String, dynamic>>> timetableGrid = {
            for (var day in days) day: {for (var time in times) time: {}},
          };
          Map<String, List<Map<String, dynamic>>> dayWiseDetails = {
            for (var day in days) day: [],
          };

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final day = (data['day'] ?? '').toString();
            final time = (data['time'] ?? '').toString();
            if (timetableGrid.containsKey(day) &&
                timetableGrid[day]!.containsKey(time)) {
              timetableGrid[day]![time] = {
                'subject': subjectCodeOnly(data),
                'type': data['type'] ?? '',
                'faculty': facultyName(data),
                'room': data['room'] ?? '-',
              };
            }
            if (dayWiseDetails.containsKey(day)) dayWiseDetails[day]!.add(data);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal scroll only for table
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: TimetableTable(
                    days: days,
                    times: times,
                    timetableGrid: timetableGrid,
                  ),
                ),
                const SizedBox(height: 20),
                // Day-wise details
                ...dayWiseDetails.entries.map((entry) {
                  if (entry.value.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...entry.value.map((data) {
                        final time = data['time'] ?? 'N/A';
                        final type = data['type'] ?? 'Lecture';
                        final room = data['room'] ?? '-';
                        final subject =
                            data['subject'] ??
                            data['subjectName'] ??
                            'Unknown Subject';
                        final faculty = facultyName(data);
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            "$time • $subject | $type | $faculty | Room: $room",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
