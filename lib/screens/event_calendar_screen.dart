import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class EventCalendarScreen extends StatelessWidget {
  const EventCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1D50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091227),
        title: const Text("Event Calendar"),
      ),
      body: SfPdfViewer.asset("assets/event_calendar.pdf"),
    );
  }
}
