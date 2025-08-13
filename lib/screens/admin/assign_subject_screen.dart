import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAssignSubjectScreen extends StatefulWidget {
  @override
  State<AdminAssignSubjectScreen> createState() =>
      _AdminAssignSubjectScreenState();
}

class _AdminAssignSubjectScreenState extends State<AdminAssignSubjectScreen> {
  String? selectedFacultyId;
  String? selectedFacultyName;
  final TextEditingController subjectCodeController = TextEditingController();
  final TextEditingController subjectNameController = TextEditingController();

  List<Map<String, dynamic>> faculties = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFaculties();
  }

  Future<void> loadFaculties() async {
    try {
      QuerySnapshot facultySnap =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'faculty')
              .get();

      faculties =
          facultySnap.docs
              .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'No Name'})
              .toList();

      setState(() => isLoading = false);
    } catch (e) {
      print("Error loading faculties: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> assignSubject() async {
    if (selectedFacultyId == null ||
        subjectCodeController.text.trim().isEmpty ||
        subjectNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('subjects').add({
        'subjectCode': subjectCodeController.text.trim(),
        'subjectName': subjectNameController.text.trim(),
        'facultyId': selectedFacultyId,
        'facultyName': selectedFacultyName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject assigned successfully")),
      );

      setState(() {
        selectedFacultyId = null;
        selectedFacultyName = null;
        subjectCodeController.clear();
        subjectNameController.clear();
      });
    } catch (e) {
      print("Error assigning subject: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Subject to Faculty")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedFacultyId,
                        decoration: InputDecoration(
                          labelText: "Select Faculty",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items:
                            faculties
                                .map(
                                  (faculty) => DropdownMenuItem<String>(
                                    value: faculty['id'],
                                    child: Text(faculty['name']),
                                    onTap: () {
                                      selectedFacultyName = faculty['name'];
                                    },
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() => selectedFacultyId = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: subjectCodeController,
                        decoration: InputDecoration(
                          labelText: "Subject Code",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: subjectNameController,
                        decoration: InputDecoration(
                          labelText: "Subject Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            "Assign Subject",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: assignSubject,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
