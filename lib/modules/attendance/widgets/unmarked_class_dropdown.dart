import 'package:flutter/material.dart';

/// Dropdown that lists unmarked classes for selection by the faculty.
/// The `value` is validated against available keys to avoid stale selections.
class UnmarkedClassDropdown extends StatelessWidget {
  final String? selectedKey;
  final List<Map<String, dynamic>> unmarkedClasses;
  final Function(String?) onChanged;
  final Color dropdownColor;

  const UnmarkedClassDropdown({
    super.key,
    required this.selectedKey,
    required this.unmarkedClasses,
    required this.onChanged,
    required this.dropdownColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      dropdownColor: dropdownColor,
      style: const TextStyle(color: Colors.white),
      isExpanded: true,
      value:
          selectedKey != null &&
                  unmarkedClasses.any((e) => e['key'] == selectedKey)
              ? selectedKey
              : null,
      items:
          unmarkedClasses.map((data) {
            final key = data['key'] as String;
            final subjectCode = (data['subject'] as String).split(" - ").first;
            final label = "$subjectCode | ${data['date']} | ${data['time']}";
            return DropdownMenuItem<String>(
              value: key,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: dropdownColor,
        labelText: "Select Class",
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
      ),
    );
  }
}
