import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentTimetableScreen extends StatelessWidget {
  StudentTimetableScreen({super.key});

  final String semester = '7'; // All students assumed to be in semester 7

  final List<String> orderedDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  final List<String> orderedTimes = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];

  int getDayIndex(String day) => orderedDays.indexOf(day);
  int getTimeIndex(String time) => orderedTimes.indexOf(time);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Class Timetable (Table View)")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('timetable')
                .where('semester', isEqualTo: semester)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading timetable"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No timetable entries found."));
          }

          final sortedDocs =
              docs.toList()..sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                final dayA = getDayIndex(dataA['day'] ?? '');
                final dayB = getDayIndex(dataB['day'] ?? '');
                if (dayA != dayB) return dayA.compareTo(dayB);

                final timeA = getTimeIndex(dataA['time'] ?? '');
                final timeB = getTimeIndex(dataB['time'] ?? '');
                return timeA.compareTo(timeB);
              });

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
              columns: const [
                DataColumn(label: Text("Day")),
                DataColumn(label: Text("Time")),
                DataColumn(label: Text("Subject")),
                DataColumn(label: Text("Type")),
                DataColumn(label: Text("Faculty")),
                DataColumn(label: Text("Room")),
              ],
              rows:
                  sortedDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(Text(data['day'] ?? '')),
                        DataCell(Text(data['time'] ?? '')),
                        DataCell(Text(data['subject'] ?? '')),
                        DataCell(Text(data['type'] ?? '')),
                        DataCell(Text(data['faculty'] ?? '')),
                        DataCell(Text(data['room'] ?? '')),
                      ],
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}
