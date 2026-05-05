import 'package:flutter/material.dart';

import '../data/local/daos/event_note_dao.dart';
import '../data/local/db/app_database.dart';
import '../models/event_note.dart';

class EventNotesProvider extends ChangeNotifier {
  final EventNoteDao _dao;

  EventNotesProvider({EventNoteDao? dao}) : _dao = dao ?? EventNoteDao(AppDatabase());

  final List<EventNote> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<EventNote> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotes(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _dao.getNotesForEvent(eventId);
      _notes
        ..clear()
        ..addAll(result);
    } catch (e) {
      _error = 'Could not load event notes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addNote({
    required int eventId,
    required String note,
    String? imageData,
  }) async {
    try {
      final eventNote = EventNote(
        id: DateTime.now().millisecondsSinceEpoch,
        eventId: eventId,
        note: note,
        imageData: imageData,
        createdAt: DateTime.now(),
      );

      await _dao.insertNote(eventNote);
      _notes.insert(0, eventNote);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Could not save note.';
      notifyListeners();
      return false;
    }
  }
}
