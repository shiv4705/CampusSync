import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'timetable',
  );

  Stream<QuerySnapshot> getTimetableStream() {
    return _collection.snapshots();
  }

  Future<void> addTimetable(Map<String, dynamic> data) async {
    await _collection.add(data);
  }

  Future<void> updateTimetable(String docId, Map<String, dynamic> data) async {
    await _collection.doc(docId).update(data);
  }

  Future<void> deleteTimetable(String docId) async {
    await _collection.doc(docId).delete();
  }
}
