import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/exceptions/app_exception.dart';
import '../../core/result_model.dart';
import '../local/daos/sync_queue_dao.dart';
import '../local/daos/event_dao.dart';
import '../local/db/app_database.dart';
import '../../models/event.dart';
import '../../utils/constants.dart';

/// Repository for events with caching
class EventRepository {
  final http.Client httpClient;
  final EventDao eventDao;
  final SyncQueueDao syncQueueDao;

  EventRepository({
    required this.httpClient,
    required this.eventDao,
    SyncQueueDao? syncQueueDao,
  }) : syncQueueDao = syncQueueDao ?? SyncQueueDao(AppDatabase());

  /// Fetch events from API and cache them
  Future<Result<List<Event>>> fetchEvents({bool forceRefresh = false}) async {
    try {
      // Check cache if not forcing refresh
      if (!forceRefresh) {
        try {
          final cached = await eventDao.getAllEvents();
          if (cached.isNotEmpty) {
            final isStale =
                await eventDao.isCacheStale(const Duration(minutes: 30));
            if (!isStale) {
              return Success(cached);
            }
          }
        } catch (e) {
          // Ignore cache errors
        }
      }

      // Fetch from API
      final response = await httpClient
          .get(
            Uri.parse('$apiBaseUrl/events'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw NetworkException(message: 'Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final eventsList = data['events'] as List<dynamic>?;

        if (eventsList == null) {
          return Failure(NetworkException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          ));
        }

        final events = eventsList
            .map((item) => Event.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the events
        await eventDao.insertEvents(events);

        return Success(events);
      } else {
        return Failure(NetworkException(
          message: 'Failed to fetch events',
          statusCode: response.statusCode,
        ));
      }
    } on NetworkException catch (e) {
      // Try to return cached data if available
      try {
        final cached = await eventDao.getAllEvents();
        if (cached.isNotEmpty) {
          return Success(cached);
        }
      } catch (_) {}
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error fetching events: ${e.toString()}',
      ));
    }
  }

  /// Get upcoming events
  Future<Result<List<Event>>> getUpcomingEvents() async {
    try {
      final events = await eventDao.getUpcomingEvents();
      return Success(events);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error retrieving events: ${e.toString()}',
      ));
    }
  }

  /// Get event by ID
  Future<Result<Event>> getEvent(int id) async {
    try {
      final event = await eventDao.getEventById(id);

      if (event != null) {
        return Success(event);
      }

      return Failure(UnknownException(
        message: 'Event not found',
      ));
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error fetching event: ${e.toString()}',
      ));
    }
  }

  /// Get cached events (no API call)
  Future<Result<List<Event>>> getCachedEvents() async {
    try {
      final events = await eventDao.getAllEvents();
      return Success(events);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error retrieving cached events: ${e.toString()}',
      ));
    }
  }

  /// Clear events cache
  Future<void> clearCache() async {
    await eventDao.deleteAll();
  }

  /// Add a new event locally so it appears immediately offline-first.
  Future<Result<Event>> addEvent(Event event) async {
    try {
      await eventDao.insertEvents([event]);
      await syncQueueDao.enqueue(
        kind: 'event',
        payload: jsonEncode({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'date': event.date.toIso8601String(),
          'start_time': event.startTime,
          'end_time': event.endTime,
          'location': event.location,
        }),
      );
      return Success(event);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error adding event: ${e.toString()}',
      ));
    }
  }
}
