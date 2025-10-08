import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DateTime collegeStartDate = DateTime(2025, 8, 11);

  List<DateTime> getAllDatesFromStart() {
    final today = DateTime.now();
    final daysDiff = today.difference(collegeStartDate).inDays;
    return List.generate(
      daysDiff + 1,
      (i) => collegeStartDate.add(Duration(days: i)),
    );
  }

  Future<List<Map<String, dynamic>>> fetchUnmarkedClasses() async {
    if (currentUser?.email == null) return [];
    List<Map<String, dynamic>> unmarkedClasses = [];
    final dates = getAllDatesFromStart();

    for (final date in dates) {
      final dayName = date.weekdayName();
      final dateString =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final timetableSnap =
          await _db
              .collection('timetable')
              .where('facultyId', isEqualTo: currentUser!.uid)
              .where('day', isEqualTo: dayName)
              .get();

      for (final doc in timetableSnap.docs) {
        final data = doc.data();
        final subject = data['subject']?.toString().trim() ?? 'Unknown';
        final time = data['time']?.toString().trim() ?? '';
        final attendanceId =
            '${dateString}_${subject.split(" - ").first}_$time';

        final attendanceSnap =
            await _db.collection('attendance').doc(attendanceId).get();
        if (!attendanceSnap.exists) {
          unmarkedClasses.add({
            'key': attendanceId,
            'subject': subject,
            'semester': data['semester'] ?? '',
            'room': data['room'] ?? '',
            'date': dateString,
            'time': time,
          });
        }
      }
    }

    return unmarkedClasses;
  }

  Future<List<Map<String, dynamic>>> loadStudents(String semester) async {
    final snap =
        await _db
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('semester', isEqualTo: semester)
            .get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  Future<void> submitAttendance(
    Map<String, dynamic> classData,
    Set<String> presentEmails,
  ) async {
    final docId = classData['key'];
    await _db.collection('attendance').doc(docId).set({
      'date': classData['date'],
      'subject': classData['subject'],
      'facultyEmail': currentUser!.email,
      'semester': classData['semester'],
      'room': classData['room'],
      'present': presentEmails.toList(),
      'isTaken': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsNotTaken(Map<String, dynamic> classData) async {
    final docId = classData['key'];
    await _db.collection('attendance').doc(docId).set({
      'date': classData['date'],
      'subject': classData['subject'],
      'facultyEmail': currentUser!.email,
      'semester': classData['semester'],
      'room': classData['room'],
      'isTaken': false,
      'reason': 'Class not conducted',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

extension DateTimeX on DateTime {
  String weekdayName() {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "";
    }
  }
}
