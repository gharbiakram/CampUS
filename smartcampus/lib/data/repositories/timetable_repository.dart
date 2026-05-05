import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/exceptions/app_exception.dart';
import '../../core/result_model.dart';
import '../local/daos/timetable_dao.dart';
import '../../models/timetable_item.dart';
import '../../utils/constants.dart';

/// Repository for timetable with caching
class TimetableRepository {
  final http.Client httpClient;
  final TimetableDao timetableDao;

  TimetableRepository({
    required this.httpClient,
    required this.timetableDao,
  });

  /// Fetch timetable from API and cache it
  Future<Result<List<TimetableItem>>> fetchTimetable(
      {bool forceRefresh = false}) async {
    try {
      // Check cache if not forcing refresh
      if (!forceRefresh) {
        try {
          final cached = await timetableDao.getAllTimetableItems();
          if (cached.isNotEmpty) {
            final isStale = await timetableDao
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
            Uri.parse('$apiBaseUrl/timetable'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw NetworkException(message: 'Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final timetableList = data['timetable'] as List<dynamic>?;

        if (timetableList == null) {
          return Failure(NetworkException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          ));
        }

        final timetable = timetableList
            .map((item) => TimetableItem.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the timetable
        await timetableDao.insertTimetableItems(timetable);

        return Success(timetable);
      } else {
        return Failure(NetworkException(
          message: 'Failed to fetch timetable',
          statusCode: response.statusCode,
        ));
      }
    } on NetworkException catch (e) {
      // Try to return cached data if available
      try {
        final cached = await timetableDao.getAllTimetableItems();
        if (cached.isNotEmpty) {
          return Success(cached);
        }
      } catch (_) {}
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error fetching timetable: ${e.toString()}',
      ));
    }
  }

  /// Get timetable items by day
  Future<Result<List<TimetableItem>>> getTimetableByDay(String day) async {
    try {
      final items = await timetableDao.getTimetableByDay(day);
      return Success(items);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error retrieving timetable: ${e.toString()}',
      ));
    }
  }

  /// Get timetable item by ID
  Future<Result<TimetableItem>> getTimetableItem(int id) async {
    try {
      final item = await timetableDao.getTimetableItemById(id);

      if (item != null) {
        return Success(item);
      }

      return Failure(UnknownException(
        message: 'Timetable item not found',
      ));
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error fetching timetable item: ${e.toString()}',
      ));
    }
  }

  /// Get cached timetable (no API call)
  Future<Result<List<TimetableItem>>> getCachedTimetable() async {
    try {
      final items = await timetableDao.getAllTimetableItems();
      return Success(items);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Error retrieving cached timetable: ${e.toString()}',
      ));
    }
  }

  /// Clear timetable cache
  Future<void> clearCache() async {
    await timetableDao.deleteAll();
  }
}
