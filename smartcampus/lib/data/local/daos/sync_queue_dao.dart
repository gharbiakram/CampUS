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
    return database.query(
      AppDatabase.syncQueue,
      orderBy: 'created_at ASC',
    );
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
