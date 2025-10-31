import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyMaterialService {
  /// Service that reads materials from Supabase and opens file URLs.
  final _supabase = Supabase.instance.client;

  /// Fetches study materials for `subjectId` (newest first).
  Future<List<Map<String, dynamic>>> getMaterials(String subjectId) async {
    final res = await _supabase
        .from('study_materials')
        .select()
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Open an external URL via the platform browser. Throws on failure.
  Future<void> openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw "Cannot open link";
    }
  }
}
