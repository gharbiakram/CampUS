import '../db/app_database.dart';

class SyncQueueDao {
  final AppDatabase db;

  SyncQueueDao(this.db);

  Future<void> enqueue({required String kind, required String payload}) async {
    final database = await db.dbClient;
    await database.insert(AppDatabase.syncQueue, {
      'kind': kind,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllPending() async {
    final database = await db.dbClient;
    final rows = await database.query(
      AppDatabase.syncQueue,
      orderBy: 'created_at ASC',
    );
    final raw = List.from(rows as List);
    final out = <Map<String, dynamic>>[];
    for (final r in raw) {
      if (r is Map) {
        out.add(Map<String, dynamic>.from(Map.castFrom(r)));
      }
    }
    return out;
  }

  Future<void> deleteById(int id) async {
    final database = await db.dbClient;
    await database.delete(
      AppDatabase.syncQueue,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clear() async {
    final database = await db.dbClient;
    await database.delete(AppDatabase.syncQueue);
  }
}
