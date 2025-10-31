import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/timetable_service.dart';
import '../../widgets/timetable_card.dart';
import 'add_timetable_screen.dart';
import 'edit_timetable_screen.dart';

class ManageTimetableScreen extends StatelessWidget {
  /// Admin listing for timetable entries grouped by weekday.
  /// Allows creating new slots and editing existing ones.
  const ManageTimetableScreen({super.key});

  static const List<String> weekdayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  Widget build(BuildContext context) {
    const Color darkBlue2 = Color(0xFF0D1D50);
    final timetableService = TimetableService();

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        title: const Text("Manage Timetable"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTimetableScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: timetableService.getTimetableStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text(
                "Error loading timetable",
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(
              child: Text(
                "No timetable entries.",
                style: TextStyle(color: Colors.white70),
              ),
            );

          // Group documents into a day->list map for rendering per weekday.
          final Map<String, List<Map<String, dynamic>>> timetableByDay = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final day = (data['day'] ?? 'Unknown').toString();
            timetableByDay.putIfAbsent(day, () => []).add(data);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children:
                weekdayOrder.map((day) {
                  final dayClasses = timetableByDay[day] ?? [];
                  return TimetableCard(
                    day: day,
                    classes: dayClasses,
                    onEdit: (classData) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTimetableScreen(data: classData),
                        ),
                      );
                    },
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
