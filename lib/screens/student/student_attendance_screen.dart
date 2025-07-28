import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String studentEmail;
  const StudentAttendanceScreen({super.key, required this.studentEmail});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> attendanceDocs = [];
  Map<String, List<Map<String, dynamic>>> groupedBySubject = {};
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};
  double totalAttendance = 0;
  double lectureAttendance = 0;
  double labAttendance = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('attendance').get();
    final studentEmail = widget.studentEmail;
    final List<Map<String, dynamic>> allDocs = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final isPresent = (data['present'] as List).contains(studentEmail);
      final room = data['room']?.toString();
      final inferredType = (room == '111') ? 'Lecture' : 'Lab';

      allDocs.add({...data, 'marked': isPresent, 'type': inferredType});
    }

    // Grouping
    final Map<String, List<Map<String, dynamic>>> subjectWise = {};
    final Map<String, List<Map<String, dynamic>>> dateWise = {};
    int total = 0,
        present = 0,
        lectureTotal = 0,
        lecturePresent = 0,
        labTotal = 0,
        labPresent = 0;

    for (var doc in allDocs) {
      final subject = doc['subject'] ?? 'Unknown';
      final date = doc['date'] ?? 'Unknown';
      final isPresent = doc['marked'] == true;
      final type = doc['type'];

      final subjectKey = "$subject (${type})"; // Capitalized already
      subjectWise.putIfAbsent(subjectKey, () => []).add(doc);
      dateWise.putIfAbsent(date, () => []).add(doc);

      total++;
      if (isPresent) present++;

      if (type == 'Lecture') {
        lectureTotal++;
        if (isPresent) lecturePresent++;
      } else {
        labTotal++;
        if (isPresent) labPresent++;
      }
    }

    // Sort subject keys namewise, Lecture before Lab
    final sortedSubjectWise = Map.fromEntries(
      subjectWise.entries.toList()..sort((a, b) {
        final subjectA = a.key.split(' (')[0];
        final typeA = a.key.contains('Lab') ? 1 : 0;
        final subjectB = b.key.split(' (')[0];
        final typeB = b.key.contains('Lab') ? 1 : 0;
        return subjectA.compareTo(subjectB) != 0
            ? subjectA.compareTo(subjectB)
            : typeA.compareTo(typeB); // Lecture (0) comes before Lab (1)
      }),
    );

    setState(() {
      attendanceDocs = allDocs;
      groupedBySubject = sortedSubjectWise;
      groupedByDate = dateWise;
      totalAttendance = total == 0 ? 0 : (present / total) * 100;
      lectureAttendance =
          lectureTotal == 0 ? 0 : (lecturePresent / lectureTotal) * 100;
      labAttendance = labTotal == 0 ? 0 : (labPresent / labTotal) * 100;
      isLoading = false;
    });
  }

  Color statusColor(bool marked) {
    return marked ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Attendance")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Attendance Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Overall: ${totalAttendance.toStringAsFixed(2)}%"),
                        Text(
                          "Lecture: ${lectureAttendance.toStringAsFixed(2)}%",
                        ),
                        Text("Lab: ${labAttendance.toStringAsFixed(2)}%"),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.book), text: "Subject-wise"),
                      Tab(icon: Icon(Icons.calendar_today), text: "Day-wise"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        /// SUBJECT-WISE TAB
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children:
                              groupedBySubject.entries.map((entry) {
                                final presentCount =
                                    entry.value
                                        .where((e) => e['marked'])
                                        .length;
                                final totalCount = entry.value.length;
                                final percentage =
                                    (presentCount / totalCount) * 100;

                                return Card(
                                  child: ListTile(
                                    title: Text(entry.key),
                                    subtitle: Text(
                                      "$presentCount / $totalCount Present",
                                    ),
                                    trailing: Text(
                                      "${percentage.toStringAsFixed(1)}%",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        /// DAY-WISE TAB
                        Column(
                          children: [
                            TableCalendar(
                              firstDay: DateTime.utc(2023, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: selectedDate,
                              calendarFormat: CalendarFormat.week,
                              selectedDayPredicate:
                                  (day) => isSameDay(day, selectedDate),
                              onDaySelected: (selectedDay, _) {
                                setState(() => selectedDate = selectedDay);
                              },
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    "Attendance for ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...?groupedByDate[DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(selectedDate)]
                                          ?.map((e) {
                                            final inferredType =
                                                (e['room'] == '111')
                                                    ? 'Lecture'
                                                    : 'Lab';
                                            return Card(
                                              child: ListTile(
                                                title: Text(
                                                  e['subject'] ?? 'Unknown',
                                                ),
                                                subtitle: Text(
                                                  "$inferredType | Room: ${e['room']}",
                                                ),
                                                trailing: Text(
                                                  e['marked'] == true
                                                      ? 'Present'
                                                      : 'Absent',
                                                  style: TextStyle(
                                                    color: statusColor(
                                                      e['marked'] == true,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList() ??
                                      [
                                        const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: Text(
                                              "No attendance data for this day.",
                                            ),
                                          ),
                                        ),
                                      ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
