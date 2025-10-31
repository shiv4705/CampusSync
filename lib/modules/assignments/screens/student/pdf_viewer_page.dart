import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Lightweight in-app PDF viewer page used across student/faculty flows.
/// Accepts either a remote URL or a local file path as `fileUrl`.
class PdfViewerPage extends StatelessWidget {
  final String fileUrl;
  const PdfViewerPage({super.key, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    // SfPdfViewer.network can handle http URLs; passing a local file path
    // will also work when a file:// or absolute path is provided.
    return Scaffold(
      appBar: AppBar(title: const Text('View PDF')),
      body: SfPdfViewer.network(fileUrl),
    );
  }
}
