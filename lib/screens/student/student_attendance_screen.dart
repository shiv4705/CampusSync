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
      final isTaken = data['isTaken'] as bool? ?? true;
      final isPresent =
          isTaken && (data['present'] as List).contains(studentEmail);

      allDocs.add({
        ...data,
        'type': (data['room'] == '111') ? 'Lecture' : 'Lab',
        'status': isTaken ? (isPresent ? 'Present' : 'Absent') : 'Not Taken',
      });
    }

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
      final status = doc['status'];
      final type = doc['type'];

      final subjectKey = "$subject ($type)";
      subjectWise.putIfAbsent(subjectKey, () => []).add(doc);
      dateWise.putIfAbsent(date, () => []).add(doc);

      if (status == 'Present') {
        total++;
        present++;
        if (type == 'Lecture') {
          lectureTotal++;
          lecturePresent++;
        } else {
          labTotal++;
          labPresent++;
        }
      } else if (status == 'Absent') {
        total++;
        if (type == 'Lecture')
          lectureTotal++;
        else
          labTotal++;
      }
      // Not Taken classes are excluded from percentage calculations
    }

    setState(() {
      attendanceDocs = allDocs;
      groupedBySubject = subjectWise;
      groupedByDate = dateWise;
      totalAttendance = total == 0 ? 0 : (present / total) * 100;
      lectureAttendance =
          lectureTotal == 0 ? 0 : (lecturePresent / lectureTotal) * 100;
      labAttendance = labTotal == 0 ? 0 : (labPresent / labTotal) * 100;
      isLoading = false;
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.greenAccent;
      case 'Absent':
        return Colors.redAccent;
      case 'Not Taken':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue2 = Color(0xFF0D1D50);
    const Color darkBlue1 = Color(0xFF091227);

    return Scaffold(
      backgroundColor: darkBlue1,
      appBar: AppBar(
        title: const Text("Your Attendance"),
        backgroundColor: darkBlue2,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
              : Column(
                children: [
                  // Summary Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Attendance Summary",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAttendanceCircle(
                              "Overall",
                              totalAttendance,
                              Colors.blueAccent,
                            ),
                            _buildAttendanceCircle(
                              "Lecture",
                              lectureAttendance,
                              Colors.greenAccent,
                            ),
                            _buildAttendanceCircle(
                              "Lab",
                              labAttendance,
                              Colors.orangeAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blueAccent,
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [
                      Tab(icon: Icon(Icons.book), text: "Subject-wise"),
                      Tab(icon: Icon(Icons.calendar_today), text: "Day-wise"),
                    ],
                  ),

                  // Tab contents
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Subject-wise view
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children:
                              groupedBySubject.entries.map((entry) {
                                final totalCount = entry.value.length;
                                final presentCount =
                                    entry.value
                                        .where((e) => e['status'] == 'Present')
                                        .length;
                                final percentage =
                                    totalCount == 0
                                        ? 0
                                        : (presentCount / totalCount) * 100;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "$presentCount / $totalCount Present",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                    ),
                                    trailing: Text(
                                      "${percentage.toStringAsFixed(1)}%",
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        // Day-wise view with calendar
                        Column(
                          children: [
                            TableCalendar(
                              firstDay: DateTime.utc(2023, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: selectedDate,
                              calendarFormat: CalendarFormat.week,
                              daysOfWeekStyle: const DaysOfWeekStyle(
                                weekdayStyle: TextStyle(color: Colors.white),
                                weekendStyle: TextStyle(color: Colors.white),
                              ),
                              calendarStyle: const CalendarStyle(
                                defaultTextStyle: TextStyle(
                                  color: Colors.white,
                                ),
                                weekendTextStyle: TextStyle(
                                  color: Colors.white,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: Colors.blueGrey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: const HeaderStyle(
                                titleTextStyle: TextStyle(color: Colors.white),
                                formatButtonVisible: false,
                                leftChevronIcon: Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ),
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
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...?groupedByDate[DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(selectedDate)]
                                          ?.map((e) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                ),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  e['subject'] ?? 'Unknown',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  "${e['type']} | Room: ${e['room']}",
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                                trailing: Text(
                                                  e['status'],
                                                  style: TextStyle(
                                                    color: statusColor(
                                                      e['status'],
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
                                              style: TextStyle(
                                                color: Colors.white54,
                                              ),
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

  Widget _buildAttendanceCircle(String title, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.white12,
                color: color,
                strokeWidth: 8,
              ),
              Center(
                child: Text(
                  "${value.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
