import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  const SubmitFeedbackScreen({super.key});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _status;

  Future<void> _submitFeedback() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final email = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    if (title.isEmpty || message.isEmpty) {
      setState(() => _status = "Please fill in both fields.");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = null;
    });

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'title': title,
        'message': message,
        'email': email,
        'timestamp': Timestamp.now(),
      });

      setState(() {
        _status = "Feedback submitted successfully.";
        _titleController.clear();
        _messageController.clear();
      });
    } catch (e) {
      setState(() => _status = "Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Message",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit"),
                  ),
                ),
            const SizedBox(height: 16),
            if (_status != null)
              Text(
                _status!,
                style: TextStyle(
                  color:
                      _status!.contains("successfully")
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
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
