import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'timetable',
  );

  Stream<QuerySnapshot> getTimetableStream() => _collection.snapshots();

  Future<void> addTimetable(Map<String, dynamic> data) async {
    await _collection.add(data);
  }

  Future<void> updateTimetable(String docId, Map<String, dynamic> data) async {
    await _collection.doc(docId).update(data);
  }

  Future<void> deleteTimetable(String docId) async {
    await _collection.doc(docId).delete();
  }

  /// ✅ Check if a room already has a class at the same day and time
  Future<bool> isSlotTaken(String day, String time, String room) async {
    final query =
        await _collection
            .where('day', isEqualTo: day)
            .where('time', isEqualTo: time)
            .where('room', isEqualTo: room)
            .get();
    return query.docs.isNotEmpty;
  }

  /// ✅ Check if a faculty already has a class at the same day and time (any room)
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
