import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/timetable_service.dart';
import '../../widgets/timetable_card.dart';

class FacultyTimetableScreen extends StatelessWidget {
  /// Faculty's personal timetable view: filters the global timetable by faculty
  /// identity (email/uid/displayName) and shows day-wise classes.
  const FacultyTimetableScreen({super.key});

  static const List<String> weekdayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  int getDayIndex(String? day) {
    final normalized = (day ?? '').trim().capitalize();
    return weekdayOrder.indexOf(normalized);
  }

  int getTimeIndex(String? time, List<String> timeSlots) {
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

  @override
  Widget build(BuildContext context) {
    const Color darkBlue2 = Color(0xFF0D1D50);

    // Get auth user to match rows to this faculty (email, uid or displayName).
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final facultyEmail = currentUser.email ?? '';
    final facultyUid = currentUser.uid;
    final facultyDisplayName = currentUser.displayName ?? '';
    final timetableService = TimetableService();

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
      body: StreamBuilder<QuerySnapshot>(
        stream: timetableService.getTimetableStream(),
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
          // Filter global timetable down to rows that belong to this faculty.
          final docs =
              allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final email = (data['email'] ?? '').toString();
                final fid = (data['facultyId'] ?? '').toString();
                final fname =
                    (data['faculty'] ?? data['facultyName'] ?? '').toString();
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

          const timeSlots = [
            '09:00 AM - 10:00 AM',
            '10:00 AM - 11:00 AM',
            '11:00 AM - 12:00 PM',
            '12:00 PM - 01:00 PM',
            '02:00 PM - 04:00 PM',
          ];

          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final dayA = getDayIndex(dataA['day']);
            final dayB = getDayIndex(dataB['day']);
            if (dayA != dayB) return dayA.compareTo(dayB);
            final timeA = getTimeIndex(dataA['time'], timeSlots);
            final timeB = getTimeIndex(dataB['time'], timeSlots);
            return timeA.compareTo(timeB);
          });

          // Build a day -> classes map with normalized display fields.
          // ✅ FIXED: Include 'faculty' field in class data
          final Map<String, List<Map<String, dynamic>>> timetableByDay = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final day = (data['day'] ?? 'Unknown').toString();

            timetableByDay.putIfAbsent(day, () => []).add({
              'subject': buildSubjectText(data),
              'time': data['time'] ?? 'N/A',
              'type': data['type'] ?? 'Lecture',
              'semester': data['semester'] ?? '-',
              'room': data['room'] ?? '-',
              'faculty': data['faculty'] ?? 'N/A', // 👈 added this line
            });
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children:
                weekdayOrder.map((day) {
                  final dayClasses = timetableByDay[day] ?? [];
                  return TimetableCard(day: day, classes: dayClasses);
                }).toList(),
          );
        },
      ),
    );
  }
}

extension CapExtension on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();
}
