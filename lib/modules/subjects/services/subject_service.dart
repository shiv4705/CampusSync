import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  final CollectionReference _subjectsRef = FirebaseFirestore.instance
      .collection('subjects');

  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Load all faculty users
  Future<List<Map<String, dynamic>>> getAllFaculties() async {
    final snapshot = await _usersRef.where('role', isEqualTo: 'faculty').get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'No Name'})
        .toList();
  }

  /// Assign a subject to a faculty
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

  /// Optional: Fetch all subjects
  Stream<QuerySnapshot> getAllSubjects() {
    return _subjectsRef.orderBy('createdAt', descending: true).snapshots();
  }
}
