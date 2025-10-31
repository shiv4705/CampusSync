import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/timetable_service.dart';

class AddTimetableScreen extends StatefulWidget {
  /// Admin screen to add a new timetable slot for a subject and faculty.
  /// Validates room/faculty availability before inserting the document.
  const AddTimetableScreen({super.key});

  @override
  State<AddTimetableScreen> createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timetableService = TimetableService();

  String day = 'Monday';
  String time = '09:00 AM - 10:00 AM';
  String type = 'Lecture';
  String semester = '7';
  String? selectedSubject;
  String? subjectCode;
  String? facultyName;
  String? facultyId;
  String room = '';

  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  final List<String> timeslots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];

  final List<String> types = ['Lecture', 'Practical'];

  List<Map<String, dynamic>> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    // Load `subjects` documents to populate subject dropdown and derive faculty.
    final snapshot =
        await FirebaseFirestore.instance.collection('subjects').get();
    setState(() {
      subjects =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> handleAddTimetable() async {
    // Validate form inputs and save; then perform safety checks and insert.
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (selectedSubject == null || facultyName == null || facultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid subject or faculty data')),
      );
      return;
    }

    // 1) Check if the room/time slot is already occupied.
    final roomTaken = await _timetableService.isSlotTaken(day, time, room);
    if (roomTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This room slot is already taken!')),
      );
      return;
    }

    // 2) Check if the faculty is busy at this slot.
    final facultyBusy = await _timetableService.isFacultyBusy(
      day,
      time,
      facultyName!,
    );
    if (facultyBusy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty already has a class at this time!'),
        ),
      );
      return;
    }

    // 3) Safe to add the timetable entry.
    await _timetableService.addTimetable({
      'day': day,
      'time': time,
      'subject': selectedSubject,
      'subjectCode': subjectCode,
      'faculty': facultyName,
      'facultyId': facultyId,
      'room': room,
      'type': type,
      'semester': semester,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timetable added successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        title: const Text("Add Timetable"),
        backgroundColor: darkBlue2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: day,
                decoration: const InputDecoration(
                  labelText: "Day",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items:
                    weekdays
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(d),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => day = val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: time,
                decoration: const InputDecoration(
                  labelText: "Time",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items:
                    timeslots
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => time = val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: const InputDecoration(
                  labelText: "Subject",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items:
                    subjects.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['subject'],
                        child: Text(s['subject']),
                      );
                    }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedSubject = val!;
                    // Derive subject code from subject string (before " - ")
                    subjectCode = val.split(' - ').first.trim();

                    // Get faculty name and ID from subject document
                    final subject = subjects.firstWhere(
                      (s) => s['subject'] == val,
                    );
                    facultyName = subject['faculty'];
                    facultyId = subject['facultyId'];
                  });
                },
                validator: (v) => v == null ? "Required" : null,
              ),
              const SizedBox(height: 10),
              if (subjectCode != null)
                Text(
                  "Subject Code: $subjectCode",
                  style: const TextStyle(color: Colors.white70),
                ),
              if (facultyName != null)
                Text(
                  "Faculty: $facultyName",
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Room",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                onSaved: (v) => room = v ?? '',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: "Type",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items:
                    types
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => type = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: handleAddTimetable,
                child: const Text("Add Timetable"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
