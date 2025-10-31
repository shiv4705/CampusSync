import 'package:flutter/material.dart';
import '../../services/subject_service.dart';

class AdminAssignSubjectScreen extends StatefulWidget {
  /// Admin screen to assign a subject to a faculty member.
  /// Select a faculty, enter subject code + name and submit to create the subject.
  const AdminAssignSubjectScreen({super.key});

  @override
  State<AdminAssignSubjectScreen> createState() =>
      _AdminAssignSubjectScreenState();
}

class _AdminAssignSubjectScreenState extends State<AdminAssignSubjectScreen> {
  final SubjectService _service = SubjectService();
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
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    // Load available faculty users for the dropdown using SubjectService.
    try {
      faculties = await _service.getAllFaculties();
    } catch (e) {
      debugPrint("Error loading faculties: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _assignSubject() async {
    // Validate inputs then call service to create the subject document.
    if (selectedFacultyId == null ||
        subjectCodeController.text.trim().isEmpty ||
        subjectNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      await _service.assignSubject(
        facultyId: selectedFacultyId!,
        facultyName: selectedFacultyName!,
        subjectCode: subjectCodeController.text.trim(),
        subjectName: subjectNameController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject assigned successfully")),
      );

      // Reset form on success.
      setState(() {
        selectedFacultyId = null;
        selectedFacultyName = null;
        subjectCodeController.clear();
        subjectNameController.clear();
      });
    } catch (e) {
      debugPrint("Error assigning subject: $e");
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
                          onPressed: _assignSubject,
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

  @override
  void dispose() {
    subjectCodeController.dispose();
    subjectNameController.dispose();
    super.dispose();
  }
}
