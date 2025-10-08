import 'package:flutter/material.dart';

class SubmissionCard extends StatelessWidget {
  final String studentName;
  final String email;
  final String submittedAt;
  final String? fileUrl;
  final int? marks;
  final VoidCallback? onOpenFile;

  const SubmissionCard({
    super.key,
    required this.studentName,
    required this.email,
    required this.submittedAt,
    this.fileUrl,
    this.marks,
    this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              studentName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Email: $email",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "Submitted: $submittedAt",
              style: const TextStyle(color: Colors.white70),
            ),
            if (fileUrl != null)
              TextButton(
                onPressed: onOpenFile,
                child: const Text(
                  "Open File",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            if (marks != null)
              Text(
                "Marks: $marks/10",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
