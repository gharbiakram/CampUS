import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/daos/announcement_dao.dart';
import '../data/local/daos/event_dao.dart';
import '../data/local/daos/sync_queue_dao.dart';
import '../data/local/daos/timetable_dao.dart';
import '../data/local/db/app_database.dart';
import '../data/repositories/announcement_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/timetable_repository.dart';
import '../models/announcement.dart';
import '../models/event.dart';
import '../utils/constants.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';

class CampusSyncService {
  CampusSyncService._();

  static final CampusSyncService instance = CampusSyncService._();

  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncQueueDao _syncQueueDao = SyncQueueDao(AppDatabase());
  final http.Client _httpClient = http.Client();

  late final AnnouncementRepository _announcementRepository = AnnouncementRepository(
    httpClient: _httpClient,
    announcementDao: AnnouncementDao(AppDatabase()),
  );
  late final EventRepository _eventRepository = EventRepository(
    httpClient: _httpClient,
    eventDao: EventDao(AppDatabase()),
  );
  late final TimetableRepository _timetableRepository = TimetableRepository(
    httpClient: _httpClient,
    timetableDao: TimetableDao(AppDatabase()),
  );

  Timer? _pollTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _started = false;
  bool _running = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await NotificationService.instance.initialize();
    await syncNow();

    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncNow();
      }
    });

    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncNow();
    });
  }

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;

    try {
      if (!await _connectivityService.isConnected()) {
        return;
      }

      await _flushQueue();
      await _checkForNewContent();
    } finally {
      _running = false;
    }
  }

  Future<void> _flushQueue() async {
    final pending = await _syncQueueDao.getAllPending();
    for (final item in pending) {
      final id = item['id'] as int;
      final kind = item['kind'] as String;
      final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

      final uri = Uri.parse('$apiBaseUrl/$kind');
      final response = await _httpClient.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _syncQueueDao.deleteById(id);
      }
    }
  }

  Future<void> _checkForNewContent() async {
    final prefs = await SharedPreferences.getInstance();

    final announcementResult = await _announcementRepository.fetchAnnouncements(forceRefresh: true);
    final announcementItems = announcementResult.getOrNull();
    if (announcementItems != null) {
      await _processNewItems(
        prefs: prefs,
        prefsKey: 'last_announcements_seen_id',
        items: announcementItems,
        itemLabel: 'announcement',
        notificationTitle: 'New announcements',
      );
    }

    final eventResult = await _eventRepository.fetchEvents(forceRefresh: true);
    final eventItems = eventResult.getOrNull();
    if (eventItems != null) {
      await _processNewItems(
        prefs: prefs,
        prefsKey: 'last_events_seen_id',
        items: eventItems,
        itemLabel: 'event',
        notificationTitle: 'New events',
      );
    }

    await _timetableRepository.fetchTimetable(forceRefresh: true);
  }

  Future<void> _processNewItems<T>({
    required SharedPreferences prefs,
    required String prefsKey,
    required List<T> items,
    required String itemLabel,
    required String notificationTitle,
  }) async {
    if (items.isEmpty) return;

    final latestId = items
        .map((item) => item is Announcement ? item.id : (item as Event).id)
        .reduce((a, b) => a > b ? a : b);
    final previous = prefs.getInt(prefsKey);

    if (previous == null) {
      await prefs.setInt(prefsKey, latestId);
      return;
    }

    if (latestId > previous) {
      final newCount = latestId - previous;
      await NotificationService.instance.showUpdateNotification(
        id: itemLabel == 'announcement' ? 101 : 102,
        title: notificationTitle,
        body: '$newCount new $itemLabel${newCount == 1 ? '' : 's'} available.',
      );
      await prefs.setInt(prefsKey, latestId);
    }
  }

  Future<void> stop() async {
    await _connectivitySubscription?.cancel();
    _pollTimer?.cancel();
    _httpClient.close();
    _started = false;
  }
}