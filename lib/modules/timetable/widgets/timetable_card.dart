import 'package:flutter/material.dart';

class TimetableCard extends StatelessWidget {
  final String day;
  final List<Map<String, dynamic>> classes;
  final Function(Map<String, dynamic>)? onEdit; // <-- add this parameter

  const TimetableCard({
    super.key,
    required this.day,
    required this.classes,
    this.onEdit,
  });

  /// Visual card that groups a day's classes into an expandable list.
  /// If `onEdit` is supplied, tapping a class will call it with that class data.

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.06),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        // If there are no classes show an empty hint, otherwise render each row.
        children:
            classes.isEmpty
                ? [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "No classes scheduled.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ]
                : classes.map((data) {
                  final subjectText =
                      (data['subject'] ?? '') +
                      (data['subjectName'] != null
                          ? ' - ${data['subjectName']}'
                          : '');
                  final time = (data['time'] ?? 'N/A').toString();
                  final type = (data['type'] ?? 'Lecture').toString();
                  final semester = (data['semester'] ?? '-').toString();
                  final room = (data['room'] ?? '-').toString();
                  final faculty = (data['faculty'] ?? 'N/A').toString();

                  return Card(
                    color: Colors.white.withOpacity(0.08),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Faculty: $faculty",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
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
                      onTap: () {
                        if (onEdit != null) {
                          onEdit!(data); // <-- call onEdit when tapped
                        }
                      },
                    ),
                  );
                }).toList(),
      ),
    );
  }
}
