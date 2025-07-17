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
  String? selectedDocId;
  String? selectedSubject;
  String? selectedSemester;
  String? selectedRoom;

  List<Map<String, dynamic>> students = [];
  Set<String> presentEmails = {};

  bool isLoading = false;
  List<DocumentSnapshot> todayClasses = [];

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchTodayClasses();
  }

  Future<void> fetchTodayClasses() async {
    setState(() => isLoading = true);

    final today = DateFormat('EEEE').format(DateTime.now()); // e.g., Monday

    final snapshot =
        await FirebaseFirestore.instance
            .collection('timetable')
            .where('email', isEqualTo: currentUser!.email)
            .where('day', isEqualTo: today)
            .get();

    todayClasses = snapshot.docs;
    setState(() => isLoading = false);
  }

  Future<void> loadStudents(String semester) async {
    print("Loading students for semester: $semester");

    final studentSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('semester', isEqualTo: semester)
            .get();

    print("Found ${studentSnapshot.docs.length} students");

    students =
        studentSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

    setState(() {});
  }

  Future<void> submitAttendance() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${date}_${selectedSubject?.split(" - ").first}';

    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'date': date,
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
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// Dropdown for today's classes
                      DropdownButtonFormField<String>(
                        value: selectedDocId,
                        items:
                            todayClasses.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final display =
                                  "${data['subject']} (${data['time']})";
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(display),
                              );
                            }).toList(),
                        onChanged: (docId) async {
                          final selectedDoc = todayClasses.firstWhere(
                            (doc) => doc.id == docId,
                          );
                          final data =
                              selectedDoc.data() as Map<String, dynamic>;

                          selectedDocId = docId;
                          selectedSubject = data['subject'];
                          selectedSemester = data['semester'];
                          selectedRoom = data['room'];
                          presentEmails.clear();

                          await loadStudents(selectedSemester!);
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          labelText: "Select Class",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// List of students
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

                      /// Submit Button
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
