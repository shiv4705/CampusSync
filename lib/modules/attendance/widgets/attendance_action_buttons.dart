import 'package:flutter/material.dart';

class AttendanceActionButtons extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onNotTaken;

  const AttendanceActionButtons({
    super.key,
    required this.onSubmit,
    required this.onNotTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              "Submit Attendance",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNotTaken,
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text(
              "Mark as Not Taken",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
