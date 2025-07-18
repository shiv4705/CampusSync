import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  Map<String, Map<String, int>> subjectCounts =
      {}; // subject -> {lectureTotal, lecturePresent, labTotal, labPresent}
  int totalClasses = 0;
  int totalPresent = 0;
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> selectedDayClasses = [];

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    final email = currentUser?.email;
    if (email == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('attendance')
            .where('present', arrayContains: email)
            .get();

    final allSnapshot =
        await FirebaseFirestore.instance.collection('attendance').get();

    Map<String, Map<String, int>> counts = {};
    int total = 0;
    int present = 0;

    for (var doc in allSnapshot.docs) {
      final data = doc.data();
      final subject = data['subject'] ?? '';
      final type =
          (data['subject'] ?? '').toString().toLowerCase().contains('lab')
              ? 'lab'
              : 'lecture';

      counts.putIfAbsent(
        subject,
        () => {
          'lectureTotal': 0,
          'lecturePresent': 0,
          'labTotal': 0,
          'labPresent': 0,
        },
      );
      if (type == 'lecture') {
        counts[subject]!['lectureTotal'] =
            counts[subject]!['lectureTotal']! + 1;
      } else {
        counts[subject]!['labTotal'] = counts[subject]!['labTotal']! + 1;
      }

      total++;
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final subject = data['subject'] ?? '';
      final type =
          (data['subject'] ?? '').toString().toLowerCase().contains('lab')
              ? 'lab'
              : 'lecture';

      if (!counts.containsKey(subject)) continue;

      if (type == 'lecture') {
        counts[subject]!['lecturePresent'] =
            counts[subject]!['lecturePresent']! + 1;
      } else {
        counts[subject]!['labPresent'] = counts[subject]!['labPresent']! + 1;
      }

      present++;
    }

    setState(() {
      subjectCounts = counts;
      totalClasses = total;
      totalPresent = present;
    });

    fetchTimetableForDate(selectedDate);
  }

  Future<void> fetchTimetableForDate(DateTime date) async {
    final weekday = DateFormat('EEEE').format(date);
    final snapshot =
        await FirebaseFirestore.instance
            .collection('timetable')
            .where('semester', isEqualTo: '7')
            .where('day', isEqualTo: weekday)
            .get();

    final classes = snapshot.docs.map((e) => e.data()).toList();

    setState(() {
      selectedDayClasses = classes;
    });
  }

  double calculatePercentage(int present, int total) {
    if (total == 0) return 0;
    return (present / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Overview")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// Overall attendance
            Card(
              color: Colors.blue[50],
              child: ListTile(
                title: const Text("Overall Attendance"),
                subtitle: Text("${totalPresent} / $totalClasses classes"),
                trailing: Text(
                  "${calculatePercentage(totalPresent, totalClasses).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Per subject attendance
            const Text(
              "Subject-wise Attendance",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children:
                    subjectCounts.entries.map((entry) {
                      final subject = entry.key;
                      final values = entry.value;

                      final lecturePercent = calculatePercentage(
                        values['lecturePresent']!,
                        values['lectureTotal']!,
                      );
                      final labPercent = calculatePercentage(
                        values['labPresent']!,
                        values['labTotal']!,
                      );

                      return Card(
                        child: ListTile(
                          title: Text(subject),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Lecture: ${values['lecturePresent']} / ${values['lectureTotal']} (${lecturePercent.toStringAsFixed(1)}%)",
                              ),
                              Text(
                                "Lab: ${values['labPresent']} / ${values['labTotal']} (${labPercent.toStringAsFixed(1)}%)",
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            /// Calendar
            const Text(
              "Select a Day to View Schedule",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              focusedDay: selectedDate,
              firstDay: DateTime.utc(2023),
              lastDay: DateTime.utc(2030),
              calendarFormat: CalendarFormat.week,
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              onDaySelected: (selected, _) {
                setState(() {
                  selectedDate = selected;
                });
                fetchTimetableForDate(selected);
              },
            ),
            const SizedBox(height: 8),

            /// Classes of selected day
            if (selectedDayClasses.isNotEmpty)
              ...selectedDayClasses.map(
                (data) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(data['subject'] ?? ''),
                    subtitle: Text("${data['type']} | ${data['time']}"),
                    trailing: Text("Room: ${data['room'] ?? ''}"),
                  ),
                ),
              ),
            if (selectedDayClasses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("No classes scheduled on this day."),
              ),
          ],
        ),
      ),
    );
  }
}
