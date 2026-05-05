import '../db/app_database.dart';
import '../../../models/event_note.dart';

class EventNoteDao {
  final AppDatabase db;

  EventNoteDao(this.db);

  Future<int> insertNote(EventNote note) async {
    final database = await db.dbClient;
    return await database.insert(AppDatabase.eventNotes, note.toMap());
  }

  Future<List<EventNote>> getNotesForEvent(int eventId) async {
    final database = await db.dbClient;
    final rows = await database.query(
      AppDatabase.eventNotes,
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'created_at DESC',
    );

    final normalized = AppDatabase.normalizeRows(rows);
    return normalized.map(EventNote.fromMap).toList();
  }

  Future<void> deleteNote(int id) async {
    final database = await db.dbClient;
    await database.delete(
      AppDatabase.eventNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
