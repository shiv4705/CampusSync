import 'package:flutter/material.dart';
import '../../services/timetable_service.dart';

class EditTimetableScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const EditTimetableScreen({super.key, required this.data});

  @override
  State<EditTimetableScreen> createState() => _EditTimetableScreenState();
}

class _EditTimetableScreenState extends State<EditTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timetableService = TimetableService();

  late String day, time, room, type;
  late String faculty, facultyId, semester, subject, subjectCode;

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

  @override
  void initState() {
    super.initState();

    // Editable fields with safe defaults
    day =
        (widget.data['day'] != null && weekdays.contains(widget.data['day']))
            ? widget.data['day']
            : weekdays[0];

    time =
        (widget.data['time'] != null && timeslots.contains(widget.data['time']))
            ? widget.data['time']
            : timeslots[0];

    type =
        (widget.data['type'] != null && types.contains(widget.data['type']))
            ? widget.data['type']
            : types[0];

    room = widget.data['room']?.toString() ?? '';

    // Fixed fields
    faculty = widget.data['faculty']?.toString() ?? '';
    facultyId = widget.data['facultyId']?.toString() ?? '';
    semester = widget.data['semester']?.toString() ?? '';
    subject = widget.data['subject']?.toString() ?? '';
    subjectCode = widget.data['subjectCode']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        title: const Text("Edit Timetable"),
        backgroundColor: darkBlue2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Editable fields
              DropdownButtonFormField<String>(
                value: day,
                decoration: const InputDecoration(
                  labelText: "Day",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items:
                    weekdays
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (val) => setState(() => day = val ?? weekdays[0]),
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
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (val) => setState(() => time = val ?? timeslots[0]),
              ),
              const SizedBox(height: 10),

              TextFormField(
                initialValue: room,
                decoration: const InputDecoration(
                  labelText: "Room",
                  filled: true,
                  fillColor: Colors.white10,
                ),
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
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (val) => setState(() => type = val ?? types[0]),
              ),
              const SizedBox(height: 20),

              // Fixed fields
              TextFormField(
                initialValue: subject,
                decoration: const InputDecoration(
                  labelText: "Subject",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                enabled: false,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: faculty,
                decoration: const InputDecoration(
                  labelText: "Faculty",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                enabled: false,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: semester,
                decoration: const InputDecoration(
                  labelText: "Semester",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                enabled: false,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _timetableService
                        .updateTimetable(widget.data['id'], {
                          'day': day,
                          'time': time,
                          'room': room,
                          'type': type,
                        })
                        .then((_) => Navigator.pop(context));
                  }
                },
                child: const Text("Update Timetable"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
