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
  String? selectedTime;

  List<Map<String, dynamic>> students = [];
  Set<String> presentEmails = {};

  bool isLoading = false;
  List<Map<String, dynamic>> unmarkedClasses = [];

  final currentUser = FirebaseAuth.instance.currentUser;

  // Colors
  final Color darkBlue1 = const Color(0xFF091227);
  final Color darkBlue2 = const Color(0xFF0D1D50);

  @override
  void initState() {
    super.initState();
    fetchUnmarkedClasses();
  }

  List<DateTime> getWeekDatesUntilToday() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    return List.generate(weekday, (i) => monday.add(Duration(days: i)));
  }

  Future<void> fetchUnmarkedClasses() async {
    setState(() => isLoading = true);
    unmarkedClasses.clear();

    final email = currentUser!.email;
    final dates = getWeekDatesUntilToday();

    for (var date in dates) {
      final dayName = DateFormat('EEEE').format(date);
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
        final time = data['time'];
        final uniqueKey = '$attendanceId|$dateString|$time';

        final attendanceSnap =
            await FirebaseFirestore.instance
                .collection('attendance')
                .doc(attendanceId)
                .get();

        if (!attendanceSnap.exists) {
          unmarkedClasses.add({
            'key': uniqueKey,
            'subject': data['subject'],
            'semester': data['semester'],
            'room': data['room'],
            'date': dateString,
            'time': time,
          });
        }
      }
    }

    setState(() => isLoading = false);
  }

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

  Future<void> submitAttendance() async {
    final parts = selectedKey!.split('|');
    final docId = parts[0];

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

    setState(() {
      selectedKey = null;
      selectedSubject = null;
      selectedSemester = null;
      selectedRoom = null;
      selectedDate = null;
      selectedTime = null;
      students.clear();
      presentEmails.clear();
    });

    await fetchUnmarkedClasses();
  }

  void toggleSelectAll() {
    setState(() {
      if (presentEmails.length == students.length) {
        presentEmails.clear();
      } else {
        presentEmails = students.map((e) => e['email'] as String).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue1,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        title: const Text("Mark Attendance"),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
              : unmarkedClasses.isEmpty
              ? const Center(
                child: Text(
                  "No attendance remaining for this week",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              )
              : Container(
                color: darkBlue1,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: darkBlue1,
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        value:
                            (selectedKey != null &&
                                    unmarkedClasses.any(
                                      (e) => e['key'] == selectedKey,
                                    ))
                                ? selectedKey
                                : null,
                        items:
                            unmarkedClasses.map((data) {
                              final key = data['key'].toString().trim();
                              final subjectCode =
                                  (data['subject'] as String)
                                      .split(" - ")
                                      .first;
                              final label =
                                  "$subjectCode | ${data['date']} | ${data['time']}";
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged: (val) async {
                          final selected = unmarkedClasses.firstWhere(
                            (e) => e['key'] == val,
                          );

                          setState(() {
                            selectedKey = val;
                            selectedSubject = selected['subject'];
                            selectedSemester = selected['semester'];
                            selectedRoom = selected['room'];
                            selectedDate = selected['date'];
                            selectedTime = selected['time'];
                            presentEmails.clear();
                            students.clear();
                          });

                          await loadStudents(selectedSemester!);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: darkBlue1,
                          labelText: "Select Class",
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// Show class details
                      if (selectedKey != null)
                        Card(
                          color: Colors.white.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Subject: $selectedSubject",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Date: $selectedDate",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Time: $selectedTime",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Semester: $selectedSemester",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Room: $selectedRoom",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),

                      /// Select All Button
                      if (students.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: toggleSelectAll,
                            icon: Icon(
                              presentEmails.length == students.length
                                  ? Icons.remove_done
                                  : Icons.done_all,
                              color: Colors.white70,
                            ),
                            label: Text(
                              presentEmails.length == students.length
                                  ? "Deselect All"
                                  : "Select All",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),

                      /// Students List
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
                              title: Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                email,
                                style: const TextStyle(color: Colors.white70),
                              ),
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

                      const SizedBox(height: 12),

                      /// Submit Button
                      if (students.isNotEmpty)
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: submitAttendance,
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text(
                              "Submit Attendance",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
