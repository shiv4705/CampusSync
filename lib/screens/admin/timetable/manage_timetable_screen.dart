import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_timetable_screen.dart';
import 'edit_timetable_screen.dart';

class ManageTimetableScreen extends StatefulWidget {
  const ManageTimetableScreen({super.key});

  @override
  State<ManageTimetableScreen> createState() => _ManageTimetableScreenState();
}

class _ManageTimetableScreenState extends State<ManageTimetableScreen> {
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  String? _selectedTime;
  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 04:00 PM',
  ];

  int _timeToInt(String time) {
    switch (time) {
      case '09:00 AM - 10:00 AM':
        return 1;
      case '10:00 AM - 11:00 AM':
        return 2;
      case '11:00 AM - 12:00 PM':
        return 3;
      case '12:00 PM - 01:00 PM':
        return 4;
      case '02:00 PM - 04:00 PM':
        return 5;
      default:
        return 99;
    }
  }

  Widget _buildDayContent(String day) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('timetable')
              .where('day', isEqualTo: day)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error loading timetable.",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No timetable entries found for this day.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        final sortedDocs = List.from(docs)..sort((a, b) {
          final at = _timeToInt((a['time'] ?? '').toString());
          final bt = _timeToInt((b['time'] ?? '').toString());
          return at.compareTo(bt);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            // ✅ Support both old & new format
            final subject =
                data.containsKey('subject')
                    ? data['subject']
                    : (data.containsKey('subjectName') &&
                            data.containsKey('subjectCode')
                        ? "${data['subjectCode']} - ${data['subjectName']}"
                        : 'Unknown Subject');

            final faculty =
                data.containsKey('faculty')
                    ? data['faculty']
                    : (data.containsKey('facultyName')
                        ? data['facultyName']
                        : 'Unknown Faculty');
            final type = data['type'] ?? 'Lecture';
            final time = data['time'] ?? 'N/A';
            final semester = data['semester'] ?? '-';
            final room = data['room'] ?? '-';

            final validTime = _timeSlots.contains(time) ? time : null;

            return Card(
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.calendar_today, color: Colors.white),
                ),
                title: Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Faculty: $faculty",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Type: $type | Time: ${validTime ?? 'Invalid'}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Semester: $semester | Room: $room",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditTimetableScreen(
                              docId: doc.id, // Pass the document ID
                              initialData: data, // Pass the timetable data
                            ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue1 = Color(0xFF091227);
    const Color darkBlue2 = Color(0xFF0D1D50);

    return Scaffold(
      backgroundColor: darkBlue2,
      appBar: AppBar(
        backgroundColor: darkBlue2,
        elevation: 0,
        title: const Text(
          "Manage Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTimetableScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Custom TabBar
          Container(
            color: darkBlue2,
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedIndex;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isSelected
                                  ? Colors.blueAccent
                                  : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      _days[index],
                      style: TextStyle(
                        fontSize: isSelected ? 16 : 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ PageView for swipe support
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBlue1, darkBlue2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _days.length,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                itemBuilder: (context, index) {
                  return _buildDayContent(_days[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
