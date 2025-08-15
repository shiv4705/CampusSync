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

  final Color primaryColor = const Color(0xFF4CAF50);

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
      String subjectCode = subjectCodeController.text.trim();
      String subjectName = subjectNameController.text.trim();
      String formattedSubject = "$subjectCode - $subjectName";

      await FirebaseFirestore.instance.collection('subjects').add({
        'faculty': selectedFacultyName,
        'subject': formattedSubject,
        'facultyId': selectedFacultyId,
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1D50),
      appBar: AppBar(
        title: const Text("Assign Subject to Faculty"),
        backgroundColor: const Color(0xFF0D1D50),
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Faculty Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedFacultyId,
                        decoration: _inputDecoration("Select Faculty"),
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
                        onChanged:
                            (val) => setState(() => selectedFacultyId = val),
                        dropdownColor: const Color(0xFF0A152E),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subject Code
                      TextField(
                        controller: subjectCodeController,
                        decoration: _inputDecoration("Subject Code"),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),

                      // Subject Name
                      TextField(
                        controller: subjectNameController,
                        decoration: _inputDecoration("Subject Name"),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),

                      // Assign Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: assignSubject,
                          icon: const Icon(Icons.check, color: Colors.black),
                          label: const Text(
                            "Assign Subject",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
