import 'package:flutter/material.dart';

import '../models/announcement.dart';
import 'announcement_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _announcements.isNotEmpty;

  Future<void> loadAnnouncements({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _announcements.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _announcements = await AnnouncementService.fetchAnnouncements();
    } catch (e) {
      _error = 'Could not load announcements. Check your connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAnnouncements() async {
    await loadAnnouncements(forceRefresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
