import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTimetableScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const EditTimetableScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EditTimetableScreen> createState() => _EditTimetableScreenState();
}

class _EditTimetableScreenState extends State<EditTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _data;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  final List<String> _types = ['Lecture', 'Lab'];

  final Map<String, String> _facultyEmailMap = {
    'Parth Patel': 'sample.faculty.parthpatel@gmail.com',
    'Shiv Patel': 'sample.faculty.shivpatel@gmail.com',
  };

  final Map<String, String> _subjects = {
    'MAD101': 'Mobile App Development',
    'DSA102': 'Data Structures & Algorithms',
    'DBMS103': 'Database Management Systems',
  };

  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];

  @override
  void initState() {
    _data = Map<String, dynamic>.from(widget.initialData);
    super.initState();
  }

  Future<void> _update() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Update email based on selected faculty
      _data['email'] = _facultyEmailMap[_data['faculty']] ?? '';

      await FirebaseFirestore.instance
          .collection('timetable')
          .doc(widget.docId)
          .update(_data);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('timetable')
        .doc(widget.docId)
        .delete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Timetable Entry")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Faculty Dropdown
              DropdownButtonFormField(
                value: _data['faculty'],
                items:
                    _facultyEmailMap.keys
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                onChanged: (val) => setState(() => _data['faculty'] = val),
                onSaved: (val) => _data['faculty'] = val,
                decoration: const InputDecoration(
                  labelText: "Faculty",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || (val as String).isEmpty
                            ? 'Faculty is required'
                            : null,
              ),
              const SizedBox(height: 12),

              /// Subject Dropdown
              DropdownButtonFormField(
                value: _data['subject'],
                items:
                    _subjects.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: '${e.key} - ${e.value}',
                            child: Text('${e.key} - ${e.value}'),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _data['subject'] = val),
                onSaved: (val) => _data['subject'] = val,
                decoration: const InputDecoration(
                  labelText: "Subject",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || (val as String).isEmpty
                            ? 'Subject is required'
                            : null,
              ),
              const SizedBox(height: 12),

              /// Type Dropdown
              DropdownButtonFormField(
                value: _data['type'],
                items:
                    _types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (val) => setState(() => _data['type'] = val),
                onSaved: (val) => _data['type'] = val,
                decoration: const InputDecoration(
                  labelText: "Type",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || (val as String).isEmpty
                            ? 'Type is required'
                            : null,
              ),
              const SizedBox(height: 12),

              /// Day Dropdown
              DropdownButtonFormField(
                value: _data['day'],
                items:
                    _days
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (val) => setState(() => _data['day'] = val),
                onSaved: (val) => _data['day'] = val,
                decoration: const InputDecoration(
                  labelText: "Day",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || (val as String).isEmpty
                            ? 'Day is required'
                            : null,
              ),
              const SizedBox(height: 12),

              /// Time Slot Dropdown
              DropdownButtonFormField(
                value: _data['time'],
                items:
                    _timeSlots
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (val) => setState(() => _data['time'] = val),
                onSaved: (val) => _data['time'] = val,
                decoration: const InputDecoration(
                  labelText: "Time",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || (val as String).isEmpty
                            ? 'Time is required'
                            : null,
              ),
              const SizedBox(height: 12),

              /// Semester
              TextFormField(
                initialValue: _data['semester'],
                decoration: const InputDecoration(
                  labelText: "Semester",
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _data['semester'] = val,
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? 'Semester is required'
                            : null,
              ),
              const SizedBox(height: 12),

              /// Room
              TextFormField(
                initialValue: _data['room'],
                decoration: const InputDecoration(
                  labelText: "Room",
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _data['room'] = val,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Room is required' : null,
              ),
              const SizedBox(height: 20),

              /// Update Button
              ElevatedButton.icon(
                onPressed: _update,
                icon: const Icon(Icons.update),
                label: const Text("Update Entry"),
              ),
              const SizedBox(height: 12),

              /// Delete Button
              ElevatedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete),
                label: const Text("Delete Entry"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
