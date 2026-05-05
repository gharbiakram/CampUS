import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/daos/timetable_dao.dart';
import '../data/local/db/app_database.dart';
import '../data/repositories/timetable_repository.dart';
import '../models/timetable_item.dart';

class TimetableProvider extends ChangeNotifier {
  late final TimetableRepository _repo;

  List<TimetableItem> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedOnce = false;

  List<TimetableItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _items.isNotEmpty;

  TimetableProvider({TimetableRepository? repository}) {
    _repo = repository ?? TimetableRepository(httpClient: http.Client(), timetableDao: TimetableDao(AppDatabase()));
  }

  Future<void> loadTimetable({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _hasLoadedOnce && _items.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.fetchTimetable(forceRefresh: forceRefresh);
      result.fold((failure) {
        _error = failure.toString();
      }, (list) {
        _items = list;
        _hasLoadedOnce = true;
        _error = null;
      });
    } catch (e) {
      _error = 'Could not load timetable.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadTimetable(forceRefresh: true);
  }

  Future<bool> addItem(TimetableItem item) async {
    final result = await _repo.addTimetableItem(item);
    return result.fold(
      (failure) {
        final msg = 'Could not add timetable entry. ${failure.toString()}';
        _error = msg;
        notifyListeners();
        // store debug info asynchronously (non-blocking)
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('smartcampus_last_error', msg);
        }).catchError((_) {});
        // ignore: avoid_print
        print('TimetableProvider.addItem error: ${failure.toString()}');
        return false;
      },
      (value) {
        _items = [value, ..._items];
        _hasLoadedOnce = true;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }
}
