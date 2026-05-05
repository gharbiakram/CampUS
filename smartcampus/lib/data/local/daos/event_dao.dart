import 'package:sqflite/sqflite.dart';
import '../../../models/event.dart';
import '../db/app_database.dart';

/// Data Access Object for events
class EventDao {
  final AppDatabase db;

  EventDao(this.db);

  /// Insert or replace events
  Future<void> insertEvents(List<Event> events) async {
    final database = await db.database;
    final now = DateTime.now().toIso8601String();

    for (final event in events) {
      await database.insert(
        AppDatabase.events,
        {
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'date': event.date.toIso8601String(),
          'start_time': event.startTime,
          'end_time': event.endTime,
          'location': event.location,
          'synced_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get all events from cache
  Future<List<Event>> getAllEvents() async {
    final database = await db.database;
    final maps = await database.query(
      AppDatabase.events,
      orderBy: 'date ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Get upcoming events
  Future<List<Event>> getUpcomingEvents() async {
    final database = await db.database;
    final now = DateTime.now().toIso8601String();
    final maps = await database.query(
      AppDatabase.events,
      where: 'date >= ?',
      whereArgs: [now],
      orderBy: 'date ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Get event by ID
  Future<Event?> getEventById(int id) async {
    final database = await db.database;
    final maps = await database.query(
      AppDatabase.events,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    }
    return null;
  }

  /// Delete all events
  Future<void> deleteAll() async {
    final database = await db.database;
    await database.delete(AppDatabase.events);
  }

  /// Check if cache is stale
  Future<bool> isCacheStale(Duration staleDuration) async {
    final database = await db.database;
    final maps = await database.rawQuery(
      'SELECT MAX(synced_at) as latest FROM ${AppDatabase.events}',
    );

    if (maps.isEmpty || maps.first['latest'] == null) {
      return true;
    }

    final latestSync = DateTime.parse(maps.first['latest'] as String);
    final now = DateTime.now();
    return now.difference(latestSync) > staleDuration;
  }
}
