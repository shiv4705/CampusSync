import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class EventCalendarScreen extends StatelessWidget {
  final String pdfAssetPath;

  const EventCalendarScreen({
    super.key,
    this.pdfAssetPath = "assets/event_calendar.pdf",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1D50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091227),
        title: const Text("Event Calendar"),
      ),
      body: SfPdfViewer.asset(pdfAssetPath),
    );
  }
}
