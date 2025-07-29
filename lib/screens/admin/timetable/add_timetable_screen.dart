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
    'email': '',
    'subject': '',
    'type': 'Lecture',
    'day': '',
    'time': '',
    'room': '',
  };

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];
  final List<String> _types = ['Lecture', 'Lab'];
  final Map<String, String> _subjects = {
    'MAD101': 'Mobile App Development',
    'DSA102': 'Data Structures & Algorithms',
    'DBMS103': 'Database Management Systems',
    'SGP104': 'Software Group Project',
  };
  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];
  final List<String> _rooms = ['111', '112'];

  Map<String, String> _facultyEmailMap = {};
  bool _isLoadingFaculty = true;

  final Color primaryColor = const Color(0xFF9AB6FF);
  final Color darkBlue1 = const Color(0xFF0A152E);
  final Color darkBlue2 = const Color(0xFF0D1D50);

  @override
  void initState() {
    super.initState();
    _fetchFacultyList();
  }

  Future<void> _fetchFacultyList() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'faculty')
              .get();

      final Map<String, String> facultyMap = {};
      for (var doc in snapshot.docs) {
        final name = doc['name'] ?? '';
        final email = doc['email'] ?? '';
        if (name.isNotEmpty && email.isNotEmpty) {
          facultyMap[name] = email;
        }
      }

      setState(() {
        _facultyEmailMap = facultyMap;
        _isLoadingFaculty = false;
      });
    } catch (e) {
      setState(() => _isLoadingFaculty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching faculty list.")),
      );
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _data['email'] = _facultyEmailMap[_data['faculty']] ?? '';
      _data['semester'] = '7'; // Always store semester as 7

      try {
        // ✅ Check for clash
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
          _isLoadingFaculty
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
                        DropdownButtonFormField(
                          isExpanded: true,
                          items:
                              _facultyEmailMap.keys
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        f,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _data['faculty'] = val),
                          onSaved: (val) => _data['faculty'] = val,
                          decoration: _inputDecoration("Faculty"),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField(
                          isExpanded: true,
                          items:
                              _subjects.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: '${e.key} - ${e.value}',
                                      child: Text(
                                        '${e.key} - ${e.value}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _data['subject'] = val),
                          onSaved: (val) => _data['subject'] = val,
                          decoration: _inputDecoration("Subject"),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField(
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
                          onSaved: (val) => _data['type'] = val,
                          decoration: _inputDecoration("Type"),
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField(
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
                          onSaved: (val) => _data['day'] = val,
                          decoration: _inputDecoration("Day"),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField(
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
                          onSaved: (val) => _data['time'] = val,
                          decoration: _inputDecoration("Time"),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
                          dropdownColor: darkBlue1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField(
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
                          onSaved: (val) => _data['room'] = val,
                          decoration: _inputDecoration("Room"),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
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
