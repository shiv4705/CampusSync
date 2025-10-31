import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Small wrapper around Firestore operations for feedback.
class FeedbackService {
  final CollectionReference _feedbackRef = FirebaseFirestore.instance
      .collection('feedback');

  /// Insert a feedback document with the current user's email (if available).
  Future<void> submitFeedback(String title, String message) async {
    final user = FirebaseAuth.instance.currentUser;
    await _feedbackRef.add({
      'title': title,
      'message': message,
      'email': user?.email ?? '',
      'timestamp': Timestamp.now(),
    });
  }

  /// Stream all feedback ordered by timestamp (newest first) for admin view.
  Stream<QuerySnapshot> getAllFeedback() {
    return _feedbackRef.orderBy('timestamp', descending: true).snapshots();
  }
}
