import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Simple card used to display a feedback entry in admin list views.
class FeedbackCard extends StatelessWidget {
  final String title;
  final String message;
  final Timestamp? timestamp;
  final VoidCallback onTap;

  const FeedbackCard({
    super.key,
    required this.title,
    required this.message,
    this.timestamp,
    required this.onTap,
  });

  /// Format the Firestore timestamp into a human readable string.
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown time";
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.feedback_outlined, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(timestamp),
          style: const TextStyle(color: Colors.white70),
        ),
        onTap: onTap,
      ),
    );
  }
}
