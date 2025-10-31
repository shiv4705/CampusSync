import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  /// Service to read and write `subjects` and user lists in Firestore.
  final CollectionReference _subjectsRef = FirebaseFirestore.instance
      .collection('subjects');

  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Load all users with role == 'faculty' and return id/name pairs.
  Future<List<Map<String, dynamic>>> getAllFaculties() async {
    final snapshot = await _usersRef.where('role', isEqualTo: 'faculty').get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'No Name'})
        .toList();
  }

  /// Create a `subjects` document linking a faculty to a subject string.
  Future<void> assignSubject({
    required String facultyId,
    required String facultyName,
    required String subjectCode,
    required String subjectName,
  }) async {
    final formattedSubject = "$subjectCode - $subjectName";
    await _subjectsRef.add({
      'faculty': facultyName,
      'facultyId': facultyId,
      'subject': formattedSubject,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of all subjects (newest first) for admin listing screens.
  Stream<QuerySnapshot> getAllSubjects() {
    return _subjectsRef.orderBy('createdAt', descending: true).snapshots();
  }
}
