import 'package:flutter/material.dart';
import '../../services/feedback_service.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  const SubmitFeedbackScreen({super.key});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final FeedbackService _service = FeedbackService();
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _submitFeedback() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      setState(() => _statusMessage = "Please fill in all fields.");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await _service.submitFeedback(title, message);

      setState(() {
        _statusMessage = "Feedback submitted successfully.";
        _titleController.clear();
        _messageController.clear();
      });
    } catch (e) {
      setState(() => _statusMessage = "Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Feedback")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: theme.cardColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We value your feedback",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Your feedback helps us improve the learning experience.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: "Feedback Title",
                    hintText: "e.g. Bad Teaching in XYZ Subject",
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: "Message",
                    hintText: "Describe your feedback here...",
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        child: const Text("Submit"),
                      ),
                    ),
                const SizedBox(height: 16),
                if (_statusMessage != null)
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color:
                          _statusMessage!.startsWith("Error")
                              ? Colors.red
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
