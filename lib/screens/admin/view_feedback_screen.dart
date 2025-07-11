import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;

class ViewFeedbackScreen extends StatelessWidget {
  const ViewFeedbackScreen({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown time";
    return DateFormat('dd MM yyyy, hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Feedback")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading feedback"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedbackDocs = snapshot.data?.docs ?? [];

          if (feedbackDocs.isEmpty) {
            return const Center(child: Text("No feedback submitted."));
          }

          return ListView.builder(
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final doc = feedbackDocs[index];
              final text = doc['text'] ?? '';
              final timestamp = doc['timestamp'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(text),
                  subtitle: Text(_formatTimestamp(timestamp)),
                  leading: const Icon(Icons.feedback_outlined),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
