import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementService {
  /// Thin wrapper to fetch announcements for a subject from Firestore.
  final _firestore = FirebaseFirestore.instance;

  /// Returns a list of announcement maps for `subjectId`, converting timestamps.
  Future<List<Map<String, dynamic>>> getAnnouncements(String subjectId) async {
    final snapshot =
        await _firestore
            .collection('announcements')
            .where('subject_id', isEqualTo: subjectId)
            .orderBy('created_at', descending: true)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate();
      }
      return data;
    }).toList();
  }
}
