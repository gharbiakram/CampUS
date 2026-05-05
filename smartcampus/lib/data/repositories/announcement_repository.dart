import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/exceptions/app_exception.dart';
import '../../core/result_model.dart';
import '../local/daos/sync_queue_dao.dart';
import '../local/daos/announcement_dao.dart';
import '../local/db/app_database.dart';
import '../../models/announcement.dart';
import '../../utils/constants.dart';

/// Repository for announcements with caching
class AnnouncementRepository {
  final http.Client httpClient;
  final AnnouncementDao announcementDao;
  final SyncQueueDao syncQueueDao;

  AnnouncementRepository({
    required this.httpClient,
    required this.announcementDao,
    SyncQueueDao? syncQueueDao,
  }) : syncQueueDao = syncQueueDao ?? SyncQueueDao(AppDatabase());

  /// Fetch announcements from API and cache them
  Future<Result<List<Announcement>>> fetchAnnouncements({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache if not forcing refresh
      if (!forceRefresh) {
        try {
          final cached = await announcementDao.getAllAnnouncements();
          if (cached.isNotEmpty) {
            final isStale = await announcementDao
                .isCacheStale(const Duration(minutes: 30));
            if (!isStale) {
              return Success(cached);
            }
          }
        } catch (e) {
          // Ignore cache errors, continue to fetch from API
        }
      }

      // Fetch from API
      final response = await httpClient
          .get(
            Uri.parse('$apiBaseUrl/announcements'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw NetworkException(message: 'Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final announcementsList =
            data['announcements'] as List<dynamic>?;

        if (announcementsList == null) {
          return Failure(NetworkException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          ));
        }

        final announcements = announcementsList
            .map((item) =>
                Announcement.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the announcements
        await announcementDao.insertAnnouncements(announcements);

        return Success(announcements);
      } else {
        return Failure(NetworkException(
          message: 'Failed to fetch announcements',
          statusCode: response.statusCode,
        ));
      }
    } on NetworkException catch (e) {
      // Try to return cached data if available
      try {
        final cached = await announcementDao.getAllAnnouncements();
        if (cached.isNotEmpty) {
          return Success(cached);
        }
      } catch (_) {}
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error fetching announcements: ${e.toString()}',
      ));
    }
  }

  /// Get announcement by ID (from cache first)
  Future<Result<Announcement>> getAnnouncement(int id) async {
    try {
      final announcement = await announcementDao.getAnnouncementById(id);
      
      if (announcement != null) {
        return Success(announcement);
      }

      // Try to fetch from API if not in cache
      try {
        final response = await httpClient
            .get(
              Uri.parse('$apiBaseUrl/announcements/$id'),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final announcement = Announcement.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
          await announcementDao.insertAnnouncement(announcement);
          return Success(announcement);
        }
      } catch (_) {}

      return Failure(UnknownException(
        message: 'Announcement not found',
      ));
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error fetching announcement: ${e.toString()}',
      ));
    }
  }

  /// Get cached announcements (no API call)
  Future<Result<List<Announcement>>> getCachedAnnouncements() async {
    try {
      final announcements = await announcementDao.getAllAnnouncements();
      return Success(announcements);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error retrieving cached announcements: ${e.toString()}',
      ));
    }
  }

  /// Clear announcements cache
  Future<void> clearCache() async {
    await announcementDao.deleteAll();
  }

  /// Add a new announcement locally so it appears immediately offline-first.
  Future<Result<Announcement>> addAnnouncement(Announcement announcement) async {
    try {
      final insertedId = await announcementDao.insertAnnouncement(announcement);
      if (insertedId <= 0) {
        throw StateError('Announcement insert returned invalid id');
      }
      await syncQueueDao.enqueue(
        kind: 'announcement',
        payload: jsonEncode({
          'id': announcement.id,
          'title': announcement.title,
          'content': announcement.content,
          'author': announcement.author,
          'priority': announcement.priority,
          'created_at': announcement.createdAt.toIso8601String(),
        }),
      );
      // ignore: avoid_print
      print('AnnouncementRepository.addAnnouncement saved id: $insertedId');
      return Success(announcement);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error adding announcement: ${e.toString()}',
      ));
    }
  }
}
