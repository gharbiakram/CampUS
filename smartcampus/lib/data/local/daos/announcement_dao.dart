import 'package:sqflite/sqflite.dart';
import '../../../models/announcement.dart';
import '../db/app_database.dart';

/// Data Access Object for announcements
class AnnouncementDao {
  final AppDatabase db;

  AnnouncementDao(this.db);

  /// Insert or replace announcements
  Future<void> insertAnnouncements(List<Announcement> announcements) async {
    final database = await db.dbClient;
    final now = DateTime.now().toIso8601String();

    for (final announcement in announcements) {
      await database.insert(
        AppDatabase.announcements,
        {
          'id': announcement.id,
          'title': announcement.title,
          'content': announcement.content,
          'author': announcement.author,
          'priority': announcement.priority,
          'created_at': announcement.createdAt.toIso8601String(),
          'synced_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get all announcements from cache
  Future<List<Announcement>> getAllAnnouncements() async {
    final database = await db.dbClient;
    final maps = await database.query(
      AppDatabase.announcements,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Announcement.fromMap(map)).toList();
  }

  /// Get announcement by ID
  Future<Announcement?> getAnnouncementById(int id) async {
    final database = await db.dbClient;
    final maps = await database.query(
      AppDatabase.announcements,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Announcement.fromMap(maps.first);
    }
    return null;
  }

  /// Delete all announcements (for cache clear)
  Future<void> deleteAll() async {
    final database = await db.dbClient;
    await database.delete(AppDatabase.announcements);
  }

  /// Check if cache is stale (older than duration)
  Future<bool> isCacheStale(Duration staleDuration) async {
    final database = await db.dbClient;
    final maps = await database.rawQuery(
      'SELECT MAX(synced_at) as latest FROM ${AppDatabase.announcements}',
    );

    if (maps.isEmpty || maps.first['latest'] == null) {
      return true; // No data, cache is stale
    }

    final latestSync =
        DateTime.parse(maps.first['latest'] as String);
    final now = DateTime.now();
    return now.difference(latestSync) > staleDuration;
  }
}
