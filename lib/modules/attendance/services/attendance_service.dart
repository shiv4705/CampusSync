import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Small service that encapsulates attendance-related Firestore operations.
/// Used by faculty screens to find unmarked classes and write attendance docs.
class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DateTime collegeStartDate = DateTime(2025, 8, 11);

  /// Returns all calendar dates from `collegeStartDate` up to today.
  List<DateTime> getAllDatesFromStart() {
    final today = DateTime.now();
    final daysDiff = today.difference(collegeStartDate).inDays;
    return List.generate(
      daysDiff + 1,
      (i) => collegeStartDate.add(Duration(days: i)),
    );
  }

  /// Scan the faculty's timetable across dates and return classes
  /// that don't yet have an `attendance` document (unmarked classes).
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

  /// Load student documents for a semester; returns a list of maps.
  Future<List<Map<String, dynamic>>> loadStudents(String semester) async {
    final snap =
        await _db
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('semester', isEqualTo: semester)
            .get();
    return snap.docs.map((d) => d.data()).cast<Map<String, dynamic>>().toList();
  }

  /// Submit attendance for the provided class map and present student emails.
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

  /// Mark a scheduled class as not taken; writes a reason and isTaken=false.
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

/// Small DateTime helper to convert weekday integer to name string.
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
