import 'dart:async';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

      final insertedId = await _dao.insertNote(eventNote);
      if (insertedId <= 0) {
        throw Exception('Note insert returned invalid id');
      }

      // Show immediately in the current list and keep it there even if a refresh fails.
      _notes.insert(0, eventNote);
      _error = null;
      notifyListeners();
      // Refresh in the background, but only adopt the result if it actually returns data.
      unawaited(() async {
        try {
          final refreshed = await _dao.getNotesForEvent(eventId);
          if (refreshed.isNotEmpty) {
            _notes
              ..clear()
              ..addAll(refreshed);
            notifyListeners();
          }
        } catch (_) {}
      }());
      // ignore: avoid_print
      print('EventNotesProvider.addNote saved id: $insertedId');
      return true;
    } catch (e) {
      final msg = 'Could not save note: ${e.toString()}';
      _error = msg;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('smartcampus_last_error', msg);
        await prefs.setString('smartcampus_last_error_payload', jsonEncode({
          'eventId': eventId,
          'note': note,
          'hasImage': imageData != null,
        }));
      } catch (_) {}
      // Ensure error is visible in console for quick debugging
      // ignore: avoid_print
      print('EventNotesProvider.addNote error: $msg');
      return false;
    }
  }
}
