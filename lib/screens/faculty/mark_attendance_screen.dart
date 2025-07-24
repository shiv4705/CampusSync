import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  String? selectedKey;
  String? selectedSubject;
  String? selectedSemester;
  String? selectedRoom;
  String? selectedDate;

  List<Map<String, dynamic>> students = [];
  Set<String> presentEmails = {};

  bool isLoading = false;
  List<Map<String, dynamic>> unmarkedClasses = [];

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchUnmarkedClasses();
  }

  /// Step 1: Generate list of dates from Monday to today
  List<DateTime> getWeekDatesUntilToday() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    return List.generate(weekday, (i) => monday.add(Duration(days: i)));
  }

  /// Step 2: Fetch all unmarked classes for the week
  Future<void> fetchUnmarkedClasses() async {
    setState(() => isLoading = true);
    unmarkedClasses.clear();

    final email = currentUser!.email;
    final dates = getWeekDatesUntilToday();

    for (var date in dates) {
      final dayName = DateFormat('EEEE').format(date); // e.g., Monday
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      final timetableSnap =
          await FirebaseFirestore.instance
              .collection('timetable')
              .where('email', isEqualTo: email)
              .where('day', isEqualTo: dayName)
              .get();

      for (var doc in timetableSnap.docs) {
        final data = doc.data();
        final subjectCode = (data['subject'] as String).split(" - ").first;
        final attendanceId = '${dateString}_$subjectCode';

        final attendanceSnap =
            await FirebaseFirestore.instance
                .collection('attendance')
                .doc(attendanceId)
                .get();

        if (!attendanceSnap.exists) {
          unmarkedClasses.add({
            'key': '$attendanceId|$dateString',
            'subject': data['subject'],
            'semester': data['semester'],
            'room': data['room'],
            'date': dateString,
            'time': data['time'],
          });
        }
      }
    }

    setState(() => isLoading = false);
  }

  /// Step 3: Load students of selected semester
  Future<void> loadStudents(String semester) async {
    final studentSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('semester', isEqualTo: semester)
            .get();

    students =
        studentSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
    setState(() {});
  }

  /// Step 4: Submit attendance
  Future<void> submitAttendance() async {
    final docId = selectedKey!.split('|').first;

    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'date': selectedDate,
      'subject': selectedSubject,
      'facultyEmail': currentUser!.email,
      'semester': selectedSemester,
      'room': selectedRoom,
      'present': presentEmails.toList(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance submitted successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : unmarkedClasses.isEmpty
              ? const Center(
                child: Text(
                  "No attendance remaining for this week",
                  style: TextStyle(fontSize: 16),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// Dropdown to select unmarked class
                      DropdownButtonFormField<String>(
                        value: selectedKey,
                        items:
                            unmarkedClasses.map<DropdownMenuItem<String>>((
                              data,
                            ) {
                              final label =
                                  "${data['subject']} (${data['date']} - ${data['time']})";
                              return DropdownMenuItem<String>(
                                value: data['key'],
                                child: Text(label),
                              );
                            }).toList(),
                        onChanged: (val) async {
                          final selected = unmarkedClasses.firstWhere(
                            (e) => e['key'] == val,
                          );

                          selectedKey = val;
                          selectedSubject = selected['subject'];
                          selectedSemester = selected['semester'];
                          selectedRoom = selected['room'];
                          selectedDate = selected['date'];
                          presentEmails.clear();

                          await loadStudents(selectedSemester!);
                        },
                        decoration: const InputDecoration(
                          labelText: "Select Class (Unmarked)",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// List of students to mark
                      if (students.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          itemBuilder: (_, index) {
                            final student = students[index];
                            final email = student['email'];
                            final name = student['name'];
                            final isPresent = presentEmails.contains(email);

                            return CheckboxListTile(
                              value: isPresent,
                              title: Text(name),
                              subtitle: Text(email),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    presentEmails.add(email);
                                  } else {
                                    presentEmails.remove(email);
                                  }
                                });
                              },
                            );
                          },
                        ),

                      if (students.isNotEmpty) const SizedBox(height: 12),
                      if (students.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: submitAttendance,
                          icon: const Icon(Icons.check),
                          label: const Text("Submit Attendance"),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
