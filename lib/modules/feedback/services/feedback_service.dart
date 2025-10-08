import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final CollectionReference _feedbackRef = FirebaseFirestore.instance
      .collection('feedback');

  Future<void> submitFeedback(String title, String message) async {
    final user = FirebaseAuth.instance.currentUser;
    await _feedbackRef.add({
      'title': title,
      'message': message,
      'email': user?.email ?? '',
      'timestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getAllFeedback() {
    return _feedbackRef.orderBy('timestamp', descending: true).snapshots();
  }
}
