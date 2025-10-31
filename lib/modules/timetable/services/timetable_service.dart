import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableService {
  /// Simple Firestore-backed service for CRUD and conflict checks on timetable.
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'timetable',
  );

  /// Real-time stream of all timetable documents.
  Stream<QuerySnapshot> getTimetableStream() => _collection.snapshots();

  /// Add a new timetable document.
  Future<void> addTimetable(Map<String, dynamic> data) async {
    await _collection.add(data);
  }

  /// Update an existing timetable document by id.
  Future<void> updateTimetable(String docId, Map<String, dynamic> data) async {
    await _collection.doc(docId).update(data);
  }

  /// Delete a timetable document by id.
  Future<void> deleteTimetable(String docId) async {
    await _collection.doc(docId).delete();
  }

  /// Check if a room is already booked at `day` + `time`.
  Future<bool> isSlotTaken(String day, String time, String room) async {
    final query =
        await _collection
            .where('day', isEqualTo: day)
            .where('time', isEqualTo: time)
            .where('room', isEqualTo: room)
            .get();
    return query.docs.isNotEmpty;
  }

  /// Check if a faculty (by name) is busy at `day` + `time` (any room).
  Future<bool> isFacultyBusy(
    String day,
    String time,
    String facultyName,
  ) async {
    final query =
        await _collection
            .where('day', isEqualTo: day)
            .where('time', isEqualTo: time)
            .where('facultyName', isEqualTo: facultyName)
            .get();
    return query.docs.isNotEmpty;
  }
}
