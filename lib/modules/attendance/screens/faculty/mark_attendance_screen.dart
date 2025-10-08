import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/unmarked_class_dropdown.dart';
import '../../widgets/student_checkbox_list.dart';
import '../../widgets/attendance_action_buttons.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  String? selectedKey,
      selectedSubject,
      selectedSemester,
      selectedRoom,
      selectedDate,
      selectedTime;
  List<Map<String, dynamic>> students = [];
  Set<String> presentEmails = {};
  bool isLoading = false;
  List<Map<String, dynamic>> unmarkedClasses = [];
  final currentUser = FirebaseAuth.instance.currentUser;
  final DateTime collegeStartDate = DateTime(2025, 8, 11);

  final Color darkBlue1 = const Color(0xFF091227),
      darkBlue2 = const Color(0xFF0D1D50);

  @override
  void initState() {
    super.initState();
    fetchUnmarkedClasses();
  }

  List<DateTime> getAllDatesFromStart() {
    final today = DateTime.now();
    final daysDiff = today.difference(collegeStartDate).inDays;
    return List.generate(
      daysDiff + 1,
      (i) => collegeStartDate.add(Duration(days: i)),
    );
  }

  Future<void> fetchUnmarkedClasses() async {
    setState(() => isLoading = true);
    unmarkedClasses.clear();

    if (currentUser?.email == null) {
      debugPrint('No current user. Email missing.');
      setState(() => isLoading = false);
      return;
    }

    final dates = getAllDatesFromStart();

    try {
      for (final date in dates) {
        final dayName = DateFormat('EEEE').format(date);
        final dateString = DateFormat('yyyy-MM-dd').format(date);

        final timetableSnap =
            await FirebaseFirestore.instance
                .collection('timetable')
                .where('facultyId', isEqualTo: currentUser!.uid)
                .where('day', isEqualTo: dayName)
                .get();

        for (final doc in timetableSnap.docs) {
          final data = doc.data();
          final subject =
              data['subject']?.toString().trim() ?? 'Unknown Subject';
          final subjectCode =
              data['subjectCode']?.toString().trim() ??
              subject.split(' - ').first;
          final time = data['time']?.toString().trim() ?? '';
          final sanitizedTime = time.replaceAll(RegExp(r'\s+|[:-]'), '_');
          final attendanceId = '${dateString}_${subjectCode}_$sanitizedTime';

          final attendanceSnap =
              await FirebaseFirestore.instance
                  .collection('attendance')
                  .doc(attendanceId)
                  .get();

          if (!attendanceSnap.exists) {
            unmarkedClasses.add({
              'key': attendanceId,
              'subject': subject,
              'semester': data['semester']?.toString() ?? '',
              'room': data['room']?.toString() ?? '',
              'date': dateString,
              'time': time,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching unmarked classes: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadStudents(String semester) async {
    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('semester', isEqualTo: semester)
            .get();

    students = snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    setState(() {});
  }

  Future<void> submitAttendance() async {
    if (selectedKey == null ||
        selectedDate == null ||
        selectedSubject == null ||
        selectedSemester == null ||
        selectedRoom == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Missing required fields.")));
      return;
    }

    final docId = selectedKey!;
    final email = currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in.")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
        'date': selectedDate,
        'subject': selectedSubject,
        'facultyEmail': email,
        'semester': selectedSemester,
        'room': selectedRoom,
        'present': presentEmails.toList(),
        'isTaken': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance submitted successfully")),
      );
      resetStateAndRefresh();
    } catch (e) {
      debugPrint("Firestore write error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit attendance: $e")),
      );
    }
  }

  Future<void> markAsNotTaken() async {
    if (selectedKey == null ||
        selectedDate == null ||
        selectedSubject == null ||
        selectedSemester == null ||
        selectedRoom == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Missing required fields.")));
      return;
    }

    final docId = selectedKey!;
    final email = currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in.")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
        'date': selectedDate,
        'subject': selectedSubject,
        'facultyEmail': email,
        'semester': selectedSemester,
        'room': selectedRoom,
        'isTaken': false,
        'reason': 'Class not conducted',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as not taken")));
      resetStateAndRefresh();
    } catch (e) {
      debugPrint("Firestore error (not taken): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to mark as not taken: $e")),
      );
    }
  }

  void resetStateAndRefresh() {
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
    fetchUnmarkedClasses();
  }

  void toggleSelectAll() {
    setState(() {
      if (presentEmails.length == students.length) {
        presentEmails.clear();
      } else {
        presentEmails = students.map((s) => s['email'] as String).toSet();
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
                  "No attendance remaining",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnmarkedClassDropdown(
                        selectedKey: selectedKey,
                        unmarkedClasses: unmarkedClasses,
                        dropdownColor: darkBlue1,
                        onChanged: (val) async {
                          final sel = unmarkedClasses.firstWhere(
                            (e) => e['key'] == val,
                          );
                          setState(() {
                            selectedKey = val;
                            selectedSubject = sel['subject'] as String;
                            selectedSemester = sel['semester'] as String;
                            selectedRoom = sel['room'] as String;
                            selectedDate = sel['date'] as String;
                            selectedTime = sel['time'] as String;
                            students.clear();
                            presentEmails.clear();
                          });
                          if (selectedSemester!.isNotEmpty)
                            await loadStudents(selectedSemester!);
                        },
                      ),
                      const SizedBox(height: 12),
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
                      if (students.isNotEmpty)
                        StudentCheckboxList(
                          students: students,
                          presentEmails: presentEmails,
                          onToggle: (email, val) {
                            setState(() {
                              if (val)
                                presentEmails.add(email);
                              else
                                presentEmails.remove(email);
                            });
                          },
                          onToggleAll: toggleSelectAll,
                        ),
                      const SizedBox(height: 16),
                      if (selectedKey != null)
                        AttendanceActionButtons(
                          onSubmit: submitAttendance,
                          onNotTaken: markAsNotTaken,
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
