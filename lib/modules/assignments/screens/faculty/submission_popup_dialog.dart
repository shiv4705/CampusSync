import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';

class SubmissionPopupDialog extends StatefulWidget {
  /// Popup dialog that lists student submissions for the provided assignment.
  final Map<String, dynamic> assignment;
  const SubmissionPopupDialog({super.key, required this.assignment});

  @override
  State<SubmissionPopupDialog> createState() => _SubmissionPopupDialogState();
}

class _SubmissionPopupDialogState extends State<SubmissionPopupDialog> {
  final _service = AssignmentService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();

    // Resolve assignment id from a few common possible keys and fetch submissions.
    final rawId =
        widget.assignment['id'] ??
        widget.assignment['assignment_id'] ??
        widget.assignment['_id'] ??
        widget.assignment['uid'] ??
        widget.assignment['assignmentId'];

    final assignmentId = rawId?.toString();

    if (assignmentId == null) {
      _future = Future.value([]);
    } else {
      _future = _service.getSubmissions(assignmentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF162447),
      title: Text(
        widget.assignment['title'] ?? "Submissions",
        style: const TextStyle(color: Colors.white),
      ),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final submissions = snap.data!;

          if (submissions.isEmpty) {
            return const Text(
              "No submissions yet",
              style: TextStyle(color: Colors.white),
            );
          }

          return SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              itemCount: submissions.length,
              itemBuilder: (_, i) {
                final s = submissions[i];

                // Each row shows student email, marks and actions to open file or enter marks.
                return ListTile(
                  title: Text(
                    s['student_email'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Marks: ${s['marks'] ?? '-'}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Open submitted file',
                        onPressed: () {
                          final fileUrl = s['file_url']?.toString();
                          if (fileUrl == null || fileUrl.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No submitted file URL found'),
                              ),
                            );
                            return;
                          }
                          _service.openFile(fileUrl);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Enter marks',
                        onPressed: () async {
                          // Open a dialog to enter marks and save them to DB.
                          final marks = await _service.enterMarksDialog(
                            context,
                          );
                          if (marks != null) {
                            final rawAssignId =
                                s['assignment_id'] ??
                                s['assignmentId'] ??
                                s['_id'] ??
                                s['uid'];

                            final assignmentId = rawAssignId?.toString();

                            if (assignmentId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Assignment id missing — cannot save marks',
                                  ),
                                ),
                              );
                              return;
                            }

                            await _service.saveMarks(
                              assignmentId,
                              s['student_id']?.toString() ?? '',
                              marks,
                            );

                            setState(() {
                              // Refresh the submission list after marking.
                              _future = _service.getSubmissions(assignmentId);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    final fileUrl = s['file_url']?.toString();
                    if (fileUrl != null && fileUrl.isNotEmpty) {
                      _service.openFile(fileUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No submitted file to open'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
