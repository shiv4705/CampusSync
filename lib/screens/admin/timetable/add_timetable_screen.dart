import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTimetableScreen extends StatefulWidget {
  const AddTimetableScreen({super.key});

  @override
  State<AddTimetableScreen> createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {
    'faculty': '',
    'facultyId': '',
    'subjectCode': '',
    'subject': '',
    'type': 'Lecture',
    'day': '',
    'time': '',
    'room': '',
    'semester': '', // added semester
  };

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];
  final List<String> _types = ['Lecture', 'Lab'];
  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];
  final List<String> _rooms = ['111', '112'];

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  bool _isLoadingSubjects = true;
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedFacultyName;

  final Color primaryColor = const Color(0xFF9AB6FF);
  final Color darkBlue1 = const Color(0xFF0A152E);
  final Color darkBlue2 = const Color(0xFF0D1D50);

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('subjects').get();

      final List<Map<String, dynamic>> subjectsList =
          snapshot.docs.map((doc) {
            final Map<String, dynamic> raw = doc.data() as Map<String, dynamic>;

            String subjectCode = '';
            String subjectName = '';

            if ((raw['subjectCode'] != null &&
                    raw['subjectCode'].toString().trim().isNotEmpty) ||
                (raw['subjectName'] != null &&
                    raw['subjectName'].toString().trim().isNotEmpty)) {
              subjectCode = (raw['subjectCode'] ?? '').toString().trim();
              subjectName = (raw['subjectName'] ?? '').toString().trim();
            }

            if ((subjectCode.isEmpty || subjectName.isEmpty) &&
                raw['subject'] != null) {
              final s = raw['subject'].toString();
              final parts = s.split(' - ');
              if (parts.length >= 2) {
                subjectCode = parts.first.trim();
                subjectName = parts.sublist(1).join(' - ').trim();
              } else {
                subjectName = s.trim();
              }
            }

            String facultyName =
                (raw['facultyName'] ?? raw['faculty'] ?? '').toString().trim();

            String facultyId =
                (raw['facultyId'] ??
                        raw['facultyUid'] ??
                        raw['faculty_id'] ??
                        '')
                    .toString()
                    .trim();

            return {
              'id': doc.id,
              'subjectCode': subjectCode,
              'subjectName': subjectName,
              'facultyName': facultyName,
              'facultyId': facultyId,
            };
          }).toList();

      setState(() {
        _subjects = subjectsList;
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error fetching subjects.")));
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final clashQuery =
            await FirebaseFirestore.instance
                .collection('timetable')
                .where('day', isEqualTo: _data['day'])
                .where('time', isEqualTo: _data['time'])
                .get();

        if (clashQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A class is already scheduled at this day and time.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('timetable').add(_data);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: darkBlue2,
      appBar: AppBar(
        title: const Text("Add Timetable Entry"),
        backgroundColor: darkBlue2,
        elevation: 0,
      ),
      body:
          _isLoadingSubjects
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<Map<String, dynamic>>(
                          isExpanded: true,
                          items:
                              _subjects.map((s) {
                                final display =
                                    (s['subjectCode'] != null &&
                                            s['subjectCode']
                                                .toString()
                                                .isNotEmpty)
                                        ? "${s['subjectCode']} - ${s['subjectName']}"
                                        : s['subjectName'] ?? 'Unknown Subject';
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: s,
                                  child: Text(
                                    display,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final selected = val;
                            setState(() {
                              _data['subjectCode'] =
                                  selected['subjectCode'] ?? '';
                              final combined =
                                  (selected['subjectCode'] != null &&
                                          (selected['subjectCode'] as String)
                                              .isNotEmpty)
                                      ? "${selected['subjectCode']} - ${selected['subjectName']}"
                                      : (selected['subjectName'] ?? '');
                              _data['subject'] = combined;
                              _data['faculty'] = selected['facultyName'] ?? '';
                              _data['facultyId'] = selected['facultyId'] ?? '';
                              _selectedFacultyName =
                                  selected['facultyName'] ?? '';
                            });
                          },
                          validator: (val) => val == null ? 'Required' : null,
                          decoration: _inputDecoration("Subject"),
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_selectedFacultyName != null &&
                            _selectedFacultyName!.isNotEmpty)
                          Text(
                            "Faculty: $_selectedFacultyName",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          items:
                              _semesters
                                  .map(
                                    (sem) => DropdownMenuItem(
                                      value: sem,
                                      child: Text("Semester $sem"),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) =>
                                  setState(() => _data['semester'] = val ?? ''),
                          validator: (val) => val == null ? 'Required' : null,
                          decoration: _inputDecoration("Semester"),
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _data['type'],
                          items:
                              _types
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _data['type'] = val),
                          decoration: _inputDecoration("Type"),
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          items:
                              _days
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _data['day'] = val),
                          validator: (val) => val == null ? 'Required' : null,
                          decoration: _inputDecoration("Day"),
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          items:
                              _timeSlots
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _data['time'] = val),
                          validator: (val) => val == null ? 'Required' : null,
                          decoration: _inputDecoration("Time"),
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          items:
                              _rooms
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _data['room'] = val),
                          validator: (val) => val == null ? 'Required' : null,
                          decoration: _inputDecoration("Room"),
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),

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
                            onPressed: _save,
                            icon: const Icon(Icons.add, color: Colors.black),
                            label: const Text(
                              "Add Entry",
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
              ),
    );
  }
}
