import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentTimetableScreen extends StatelessWidget {
  StudentTimetableScreen({super.key});

  final String semester = '7'; // All students assumed to be in semester 7

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

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF091227);
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        title: const Text("Class Timetable"),
        backgroundColor: darkBlue2,
        elevation: 0,
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
              FirebaseFirestore.instance
                  .collection('timetable')
                  .where('semester', isEqualTo: semester)
                  .snapshots(),
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

            final docs = snapshot.data?.docs ?? [];

            // Prepare timetable grid
            Map<String, Map<String, Map<String, dynamic>>> timetableGrid = {
              for (var day in days) day: {for (var time in times) time: {}},
            };

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final day = data['day'] ?? '';
              final time = data['time'] ?? '';
              if (timetableGrid.containsKey(day) &&
                  timetableGrid[day]!.containsKey(time)) {
                timetableGrid[day]![time] = {
                  'subject': (data['subject'] ?? '').split(' ').first,
                  'type': data['type'] ?? '',
                  'faculty': data['faculty'] ?? '',
                  'room': data['room'] ?? '',
                };
              }
            }

            // Group details day-wise
            Map<String, List<Map<String, dynamic>>> dayWiseDetails = {
              for (var day in days) day: [],
            };

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (dayWiseDetails.containsKey(data['day'])) {
                dayWiseDetails[data['day']]!.add(data);
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ---- TIMETABLE TABLE ----
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.blueAccent.withOpacity(0.2),
                      ),
                      dataRowColor: MaterialStateProperty.all(
                        Colors.white.withOpacity(0.05),
                      ),
                      border: TableBorder.all(color: Colors.white24, width: 1),
                      columnSpacing: 20,
                      columns: [
                        const DataColumn(
                          label: Text(
                            "Time",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...days.map(
                          (day) => DataColumn(
                            label: Text(
                              day,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows:
                          times.map((timeSlot) {
                            // Split time into two lines (no dash)
                            final timeParts = timeSlot.split('-');
                            final formattedTime =
                                timeParts.length == 2
                                    ? "${timeParts[0].trim()}\n${timeParts[1].trim()}"
                                    : timeSlot;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                ...days.map((day) {
                                  final cellData =
                                      timetableGrid[day]![timeSlot] ?? {};
                                  final subjectCode = cellData['subject'] ?? '';
                                  return DataCell(
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Center(
                                        child: Text(
                                          subjectCode.isNotEmpty
                                              ? subjectCode
                                              : '-',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ---- DAY-WISE DETAILS ----
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
                              "${data['time']} • ${data['subject']} | ${data['type']} | ${data['faculty']} | Room: ${data['room']}",
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
      ),
    );
  }
}
