import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/feedback_service.dart';
import '../../widgets/feedback_card.dart';

/// Admin view that streams and lists submitted feedback.
/// Tapping an item shows the full message in a dialog.
class ViewFeedbackScreen extends StatefulWidget {
  const ViewFeedbackScreen({super.key});

  @override
  State<ViewFeedbackScreen> createState() => _ViewFeedbackScreenState();
}

class _ViewFeedbackScreenState extends State<ViewFeedbackScreen>
    with TickerProviderStateMixin {
  final FeedbackService _service = FeedbackService();

  /// Show the feedback message in a dialog when a list item is tapped.
  void _showMessageDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF0D1D50),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF0A152E);
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        title: const Text(
          "Feedback",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue1, darkBlue2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _service.getAllFeedback(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error loading feedback",
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final feedbackDocs = snapshot.data?.docs ?? [];
            if (feedbackDocs.isEmpty) {
              return const Center(
                child: Text(
                  "No feedback submitted.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: feedbackDocs.length,
              itemBuilder: (context, index) {
                final doc = feedbackDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'No Title';
                final message = data['message'] ?? 'No Message';
                final timestamp = data['timestamp'] as Timestamp?;

                // Staggered animation
                final animController = AnimationController(
                  vsync: this,
                  duration: const Duration(milliseconds: 500),
                );
                final fadeAnim = CurvedAnimation(
                  parent: animController,
                  curve: Curves.easeIn,
                );
                Timer(Duration(milliseconds: 100 * index), () {
                  if (mounted) animController.forward();
                });

                return FadeTransition(
                  opacity: fadeAnim,
                  child: FeedbackCard(
                    title: title,
                    message: message,
                    timestamp: timestamp,
                    onTap: () => _showMessageDialog(context, title, message),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
