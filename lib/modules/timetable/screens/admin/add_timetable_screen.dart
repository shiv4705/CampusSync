import 'package:flutter/material.dart';
import '../../services/timetable_service.dart';

class AddTimetableScreen extends StatefulWidget {
  const AddTimetableScreen({super.key});

  @override
  State<AddTimetableScreen> createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timetableService = TimetableService();

  String day = 'Monday';
  String time = '09:00 AM - 10:00 AM';
  String subjectCode = '';
  String subjectName = '';
  String faculty = '';
  String room = '';
  String type = 'Lecture';
  String semester = '7';

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
              DropdownButtonFormField(
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
                onChanged: (val) => setState(() => day = val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
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
                onChanged: (val) => setState(() => time = val!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Subject Code",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                onSaved: (v) => subjectCode = v!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Subject Name",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                onSaved: (v) => subjectName = v ?? '',
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Faculty",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                onSaved: (v) => faculty = v!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Room",
                  filled: true,
                  fillColor: Colors.white10,
                ),
                onSaved: (v) => room = v ?? '',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
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
                onChanged: (val) => setState(() => type = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _timetableService
                        .addTimetable({
                          'day': day,
                          'time': time,
                          'subjectCode': subjectCode,
                          'subjectName': subjectName,
                          'facultyName': faculty,
                          'room': room,
                          'type': type,
                          'semester': semester,
                        })
                        .then((_) {
                          Navigator.pop(context);
                        });
                  }
                },
                child: const Text("Add Timetable"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
