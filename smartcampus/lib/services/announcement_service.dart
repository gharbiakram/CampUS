import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/announcement.dart';
import '../utils/constants.dart';

class AnnouncementService {
  static Future<List<Announcement>> fetchAnnouncements() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/announcements'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load announcements (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = decoded['announcements'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
