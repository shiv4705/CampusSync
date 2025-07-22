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
    'semester': '',
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

  Map<String, String> _facultyEmailMap = {};
  bool _isLoadingFaculty = true;

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
      setState(() {
        _isLoadingFaculty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching faculty list.")),
      );
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _data['email'] = _facultyEmailMap[_data['faculty']] ?? '';

      try {
        // ✅ Check for any class scheduled at the same day and time
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
          return; // Don't proceed to add
        }

        // No clash, proceed to add
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Timetable Entry")),
      body:
          _isLoadingFaculty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Faculty Dropdown
                      DropdownButtonFormField(
                        items:
                            _facultyEmailMap.keys
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _data['faculty'] = val),
                        onSaved: (val) => _data['faculty'] = val,
                        decoration: const InputDecoration(
                          labelText: "Faculty",
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Subject Dropdown
                      DropdownButtonFormField(
                        items:
                            _subjects.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: '${e.key} - ${e.value}',
                                    child: Text('${e.key} - ${e.value}'),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _data['subject'] = val),
                        onSaved: (val) => _data['subject'] = val,
                        decoration: const InputDecoration(
                          labelText: "Subject",
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Type Dropdown
                      DropdownButtonFormField(
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
                        onChanged: (val) => setState(() => _data['type'] = val),
                        onSaved: (val) => _data['type'] = val,
                        decoration: const InputDecoration(
                          labelText: "Type",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Day Dropdown
                      DropdownButtonFormField(
                        items:
                            _days
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _data['day'] = val),
                        onSaved: (val) => _data['day'] = val,
                        decoration: const InputDecoration(
                          labelText: "Day",
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Time Dropdown
                      DropdownButtonFormField(
                        items:
                            _timeSlots
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _data['time'] = val),
                        onSaved: (val) => _data['time'] = val,
                        decoration: const InputDecoration(
                          labelText: "Time",
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Semester
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Semester",
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _data['semester'] = val,
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Room
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Room",
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _data['room'] = val,
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Entry"),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
