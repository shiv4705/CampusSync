import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_timetable_screen.dart';
import 'edit_timetable_screen.dart';

class ManageTimetableScreen extends StatelessWidget {
  const ManageTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Timetable")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTimetableScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('timetable')
                .orderBy('day')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading timetable"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No timetable entries found."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final subject = data['subject'] ?? 'Unknown Subject';
              final faculty = data['faculty'] ?? 'Unknown Faculty';
              final email = data['email'] ?? '';
              final type = data['type'] ?? 'Lecture';
              final day = data['day'] ?? 'N/A';
              final time = data['time'] ?? 'N/A';
              final semester = data['semester'] ?? '-';
              final room = data['room'] ?? '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    subject,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Faculty: $faculty"),
                        if (email.isNotEmpty) Text("Email: $email"),
                        Text("Type: $type | Day: $day | Time: $time"),
                        Text("Semester: $semester | Room: $room"),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EditTimetableScreen(
                                docId: doc.id,
                                initialData: data,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
