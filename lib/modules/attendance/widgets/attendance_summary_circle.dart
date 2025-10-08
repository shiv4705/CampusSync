import 'package:flutter/material.dart';

class AttendanceSummaryCircle extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const AttendanceSummaryCircle({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.white12,
                color: color,
                strokeWidth: 8,
              ),
              Center(
                child: Text(
                  "${value.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
