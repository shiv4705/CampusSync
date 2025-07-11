import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestResetScreen extends StatefulWidget {
  const RequestResetScreen({super.key});

  @override
  State<RequestResetScreen> createState() => _RequestResetScreenState();
}

class _RequestResetScreenState extends State<RequestResetScreen> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _status;

  Future<void> _submitResetRequest() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _status = "Please enter your email.");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = null;
    });

    try {
      await FirebaseFirestore.instance.collection('reset_requests').add({
        'email': email,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });

      setState(() {
        _status = "Reset request submitted successfully.";
        _emailController.clear();
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
      appBar: AppBar(title: const Text("Request Password Reset")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Your Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitResetRequest,
                    child: const Text("Submit Request"),
                  ),
                ),
            const SizedBox(height: 16),
            if (_status != null)
              Text(
                _status!,
                style: TextStyle(
                  color:
                      _status!.startsWith("Error") ? Colors.red : Colors.green,
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
    _emailController.dispose();
    super.dispose();
  }
}
