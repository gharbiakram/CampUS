import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/local/daos/event_dao.dart';
import '../data/local/db/app_database.dart';
import '../data/repositories/event_repository.dart';
import '../models/event.dart';
import 'notification_service.dart';

class EventProvider extends ChangeNotifier {
  late final EventRepository _eventRepository;

  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedOnce = false;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _events.isNotEmpty;

  EventProvider({EventRepository? eventRepository}) {
    _eventRepository = eventRepository ??
        EventRepository(
          httpClient: http.Client(),
          eventDao: EventDao(AppDatabase()),
        );
  }

  Future<void> loadEvents({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _hasLoadedOnce && _events.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _eventRepository.fetchEvents(forceRefresh: forceRefresh);

      result.fold((failure) {
        _error = 'Could not load events. ${failure.toString()}';
      }, (items) {
        _events = items;
        _hasLoadedOnce = true;
        _error = null;
      });
    } catch (e) {
      _error = 'Could not load events. Check your connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEvents() async {
    await loadEvents(forceRefresh: true);
  }

  Future<bool> addEvent(Event event) async {
    final result = await _eventRepository.addEvent(event);
    return result.fold(
      (failure) {
        _error = 'Could not add event. ${failure.toString()}';
        notifyListeners();
        return false;
      },
      (item) {
        _events = [item, ..._events];
        _hasLoadedOnce = true;
        _error = null;
        notifyListeners();
        unawaited(
          NotificationService.instance.showEventCreatedNotification(
            id: item.id,
            title: item.title,
          ),
        );
        // Keep the optimistic update visible immediately; background reloads can re-order but should not clear it.
        return true;
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
