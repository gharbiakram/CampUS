import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/exceptions/app_exception.dart';
import '../../core/result_model.dart';
import '../local/daos/sync_queue_dao.dart';
import '../local/daos/timetable_dao.dart';
import '../local/db/app_database.dart';
import '../../models/timetable_item.dart';
import '../../utils/constants.dart';

/// Repository for timetable with caching
class TimetableRepository {
  final http.Client httpClient;
  final TimetableDao timetableDao;
  final SyncQueueDao syncQueueDao;

    TimetableRepository({required this.httpClient, required this.timetableDao, SyncQueueDao? syncQueueDao})
      : syncQueueDao = syncQueueDao ?? SyncQueueDao(AppDatabase());

  Future<Result<List<TimetableItem>>> fetchTimetable({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        try {
          final cached = await timetableDao.getAllItems();
          if (cached.isNotEmpty) {
            final isStale = await timetableDao.isCacheStale(const Duration(minutes: 30));
            if (!isStale) return Success(cached);
          }
        } catch (_) {}
      }

      final response = await httpClient.get(Uri.parse('$apiBaseUrl/timetable')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['timetable'] as List<dynamic>?;
        if (list == null) return Failure(NetworkException(message: 'Invalid response', statusCode: response.statusCode));

        final items = list.map((e) => TimetableItem.fromJson(e as Map<String, dynamic>)).toList();
        await timetableDao.insertItems(items);
        return Success(items);
      }

      return Failure(NetworkException(message: 'Failed to fetch timetable', statusCode: response.statusCode));
    } on NetworkException catch (e) {
      try {
        final cached = await timetableDao.getAllItems();
        if (cached.isNotEmpty) return Success(cached);
      } catch (_) {}
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(message: 'Error fetching timetable: ${e.toString()}'));
    }
  }

  Future<Result<List<TimetableItem>>> getCachedTimetable() async {
    try {
      final items = await timetableDao.getAllItems();
      return Success(items);
    } catch (e) {
      return Failure(UnknownException(message: 'Error retrieving cached timetable: ${e.toString()}'));
    }
  }

  /// Add a new timetable item locally so it appears immediately offline-first.
  Future<Result<TimetableItem>> addTimetableItem(TimetableItem item) async {
    try {
      await timetableDao.insertItems([item]);
      await syncQueueDao.enqueue(
        kind: 'timetable',
        payload: jsonEncode({
          'id': item.id,
          'subject': item.subject,
          'instructor': item.instructor,
          'day': item.day,
          'start_time': item.startTime,
          'end_time': item.endTime,
          'room': item.room,
        }),
      );
      return Success(item);
    } catch (e) {
      return Failure(UnknownException(message: 'Error adding timetable item: ${e.toString()}'));
    }
  }
}
