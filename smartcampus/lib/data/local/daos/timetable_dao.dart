import 'package:sqflite/sqflite.dart';
import '../../../models/timetable_item.dart';
import '../db/app_database.dart';

/// Data Access Object for timetable items
class TimetableDao {
  final AppDatabase db;

  TimetableDao(this.db);

  /// Insert or replace timetable items
  Future<void> insertItems(List<TimetableItem> items) async {
    final database = await db.dbClient;
    final now = DateTime.now().toIso8601String();

    for (final item in items) {
      await database.insert(
        AppDatabase.timetable,
        {
          'id': item.id,
          'subject': item.subject,
          'instructor': item.instructor,
          'day': item.day,
          'start_time': item.startTime,
          'end_time': item.endTime,
          'room': item.room,
          'synced_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<int> insertItem(TimetableItem item) async {
    final database = await db.dbClient;
    final now = DateTime.now().toIso8601String();
    return await database.insert(
      AppDatabase.timetable,
      {
        'id': item.id,
        'subject': item.subject,
        'instructor': item.instructor,
        'day': item.day,
        'start_time': item.startTime,
        'end_time': item.endTime,
        'room': item.room,
        'synced_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all timetable items
  Future<List<TimetableItem>> getAllItems() async {
    final database = await db.dbClient;
    final maps = await database.query(
      AppDatabase.timetable,
      orderBy: 'day ASC, start_time ASC',
    );

    return AppDatabase.normalizeRows(maps).map(TimetableItem.fromMap).toList();
  }

  /// Get timetable items by day
  Future<List<TimetableItem>> getByDay(String day) async {
    final database = await db.dbClient;
    final maps = await database.query(
      AppDatabase.timetable,
      where: 'day = ?',
      whereArgs: [day],
      orderBy: 'start_time ASC',
    );

    return AppDatabase.normalizeRows(maps).map(TimetableItem.fromMap).toList();
  }

  /// Delete all timetable items
  Future<void> deleteAll() async {
    final database = await db.dbClient;
    await database.delete(AppDatabase.timetable);
  }

  /// Check if cache is stale
  Future<bool> isCacheStale(Duration staleDuration) async {
    final database = await db.dbClient;
    final maps = await database.rawQuery(
      'SELECT MAX(synced_at) as latest FROM ${AppDatabase.timetable}',
    );

    if (maps.isEmpty || maps.first['latest'] == null) return true;
    final latestSync = DateTime.parse(maps.first['latest'] as String);
    return DateTime.now().difference(latestSync) > staleDuration;
  }
}
