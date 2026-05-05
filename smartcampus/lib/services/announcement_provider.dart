import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/local/daos/announcement_dao.dart';
import '../data/local/db/app_database.dart';
import '../data/repositories/announcement_repository.dart';
import '../models/announcement.dart';

class AnnouncementProvider extends ChangeNotifier {
  late final AnnouncementRepository _announcementRepository;

  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedOnce = false;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _announcements.isNotEmpty;

  AnnouncementProvider({AnnouncementRepository? announcementRepository}) {
    _announcementRepository = announcementRepository ??
        AnnouncementRepository(
          httpClient: http.Client(),
          announcementDao: AnnouncementDao(AppDatabase()),
        );
  }

  Future<void> loadAnnouncements({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _hasLoadedOnce && _announcements.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _announcementRepository.fetchAnnouncements(
        forceRefresh: forceRefresh,
      );

      result.fold(
        (failure) {
          _error = _friendlyMessage(failure.toString());
        },
        (items) {
          _announcements = items;
          _hasLoadedOnce = true;
          _error = null;
        },
      );
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

  String _friendlyMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('timeout') || lower.contains('network')) {
      return 'No internet connection. Showing cached announcements if available.';
    }
    return 'Could not load announcements. Check your connection and try again.';
  }
}
