import 'package:flutter/material.dart';

class TimetableTable extends StatelessWidget {
  final List<String> days;
  final List<String> times;
  final Map<String, Map<String, Map<String, dynamic>>> timetableGrid;

  const TimetableTable({
    super.key,
    required this.days,
    required this.times,
    required this.timetableGrid,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Horizontal scroll
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical, // Vertical scroll
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
                      final cellData = timetableGrid[day]?[timeSlot] ?? {};
                      final subject = cellData['subject'] ?? '-';
                      final faculty = cellData['faculty'] ?? '';
                      final room = cellData['room'] ?? '';

                      return DataCell(
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                subject.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (faculty.isNotEmpty)
                                Text(
                                  faculty.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              if (room.isNotEmpty)
                                Text(
                                  "Room: $room",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
