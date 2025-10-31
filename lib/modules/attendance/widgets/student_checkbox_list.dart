import 'package:flutter/material.dart';

/// Renders the list of students with checkboxes and a select-all button.
class StudentCheckboxList extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final Set<String> presentEmails;
  final Function(String, bool) onToggle;
  final VoidCallback onToggleAll;

  const StudentCheckboxList({
    super.key,
    required this.students,
    required this.presentEmails,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    // Render nothing if there are no students loaded yet.
    if (students.isEmpty) return const SizedBox();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onToggleAll,
            icon: Icon(
              presentEmails.length == students.length
                  ? Icons.remove_done
                  : Icons.done_all,
              color: Colors.white70,
            ),
            label: Text(
              presentEmails.length == students.length
                  ? "Deselect All"
                  : "Select All",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (_, i) {
            final st = students[i];
            final email = st['email'] as String;
            final name = st['name'] as String;
            final isPresent = presentEmails.contains(email);
            return CheckboxListTile(
              value: isPresent,
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                email,
                style: const TextStyle(color: Colors.white70),
              ),
              onChanged: (val) => onToggle(email, val ?? false),
            );
          },
        ),
      ],
    );
  }
}
