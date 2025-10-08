import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/reset_request_card.dart';

class ViewResetRequestsScreen extends StatelessWidget {
  const ViewResetRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF0A152E);
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        title: const Text(
          "Password Reset Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue1, darkBlue2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('reset_requests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Unable to load reset requests.",
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No reset requests found.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return ResetRequestCard(
                  doc: docs[index],
                  index: index,
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            backgroundColor: darkBlue2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text(
                              "Delete Request",
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              "Are you sure you want to delete this request?",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      await docs[index].reference.delete();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
