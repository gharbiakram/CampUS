import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SQLite database initialization and management
class AppDatabase {
  static const String _dbName = 'smartcampus.db';
  static const int _version = 3;

  static const String announcements = 'announcements';
  static const String events = 'events';
  static const String timetable = 'timetable';
  static const String eventNotes = 'event_notes';
  static const String preferences = 'preferences';
  static const String syncQueue = 'sync_queue';

  static final AppDatabase _instance = AppDatabase._internal();

  Database? _database;
  _InMemoryDb? _inMemory;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  /// Get database instance, initializing if needed
  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  /// Platform-aware DB client: returns an in-memory implementation on web
  /// because `sqflite` is unavailable there.
  Future<dynamic> get dbClient async {
    if (kIsWeb) {
      _inMemory ??= _InMemoryDb();
      return _inMemory!;
    }
    return await database;
  }

  /// Initialize database and create tables
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $announcements (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        author TEXT NOT NULL,
        priority TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $events (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        location TEXT NOT NULL,
        synced_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $timetable (
        id INTEGER PRIMARY KEY,
        subject TEXT NOT NULL,
        instructor TEXT NOT NULL,
        day TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        room TEXT NOT NULL,
        synced_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $eventNotes (
        id INTEGER PRIMARY KEY,
        event_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        image_data TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $syncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $syncQueue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kind TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $eventNotes (
          id INTEGER PRIMARY KEY,
          event_id INTEGER NOT NULL,
          note TEXT NOT NULL,
          image_data TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  /// Close database
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  /// Clear all data (for testing/logout)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(announcements);
    await db.delete(events);
    await db.delete(timetable);
    await db.delete(eventNotes);
    await db.delete(preferences);
    await db.delete(syncQueue);
  }

  static List<Map<String, dynamic>> normalizeRows(dynamic rows) {
    final raw = List.from(rows as List);
    final normalized = <Map<String, dynamic>>[];
    for (final row in raw) {
      if (row is Map) {
        normalized.add(Map<String, dynamic>.from(Map.castFrom(row)));
      }
    }
    return normalized;
  }
}

class _InMemoryDb {
  static const String _storageKey = 'smartcampus_web_db_v1';

  final Map<String, List<Map<String, dynamic>>> _tables = {};
  int _autoId = 1;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final tables = decoded['tables'] as Map<String, dynamic>?;
      if (tables != null) {
        _tables.clear();
        for (final entry in tables.entries) {
          final rows = entry.value as List<dynamic>?;
          _tables[entry.key] = rows == null ? [] : AppDatabase.normalizeRows(rows);
        }
      }
      _autoId = (decoded['autoId'] as int?) ?? _autoId;
    }

    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'tables': _tables,
        'autoId': _autoId,
      }),
    );
  }

  void _validateRow(Map<String, dynamic> row) {
    if (!row.containsKey('id')) {
      throw StateError('Row is missing id');
    }
  }

  Future<int> insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm}) async {
    await _ensureLoaded();
    final t = _tables.putIfAbsent(table, () => []);
    final row = Map<String, dynamic>.from(values);
    if (!row.containsKey('id')) row['id'] = _autoId++;
    _validateRow(row);
    final idx = t.indexWhere((r) => r['id'] == row['id']);
    if (idx >= 0) {
      t[idx] = row;
    } else {
      t.add(row);
    }
    await _persist();
    return row['id'] as int;
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy, int? limit}) async {
    await _ensureLoaded();
    final list = _tables[table] ?? [];
    Iterable<Map<String, dynamic>> results = list;
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      if (where.contains('id = ?')) {
        final id = whereArgs.first;
        results = results.where((r) => r['id'] == id);
      } else if (where.contains('event_id = ?')) {
        final eventId = whereArgs.first;
        results = results.where((r) => r['event_id'] == eventId);
      } else if (where.contains('day = ?')) {
        final day = whereArgs.first;
        results = results.where((r) => r['day'] == day);
      } else if (where.contains('date >= ?')) {
        final threshold = whereArgs.first as String;
        results = results.where((r) {
          final v = r['date'];
          return v is String && v.compareTo(threshold) >= 0;
        });
      }
    }
    if (orderBy != null && orderBy.isNotEmpty) {
      final parts = orderBy.split(',').map((p) => p.trim()).toList();
      final sorted = results.toList();
      sorted.sort((a, b) {
        for (final part in parts) {
          final tokens = part.split(RegExp(r'\s+'));
          final field = tokens[0];
          final desc = tokens.length > 1 && tokens[1].toUpperCase() == 'DESC';
          final va = (a[field] ?? '').toString();
          final vb = (b[field] ?? '').toString();
          final cmp = va.compareTo(vb);
          if (cmp != 0) return desc ? -cmp : cmp;
        }
        return 0;
      });
      results = sorted;
    }
    if (limit != null) results = results.take(limit);
    return results.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    await _ensureLoaded();
    final list = _tables.putIfAbsent(table, () => []);
    if (where == null) {
      final count = list.length;
      _tables[table] = [];
      await _persist();
      return count;
    }
    if (where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      final before = list.length;
      list.removeWhere((r) => r['id'] == id);
      await _persist();
      return before - list.length;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql) async {
    await _ensureLoaded();
    final m = RegExp(r'FROM\s+([a-zA-Z0-9_]+)', caseSensitive: false).firstMatch(sql);
    if (m != null) {
      final table = m.group(1)!;
      final list = _tables[table] ?? [];
      String? latest;
      for (final row in list) {
        final val = row['synced_at'] as String?;
        if (val != null) {
          if (latest == null || val.compareTo(latest) > 0) latest = val;
        }
      }
      return [ {'latest': latest} ];
    }
    return [];
  }

  Future<void> close() async {}
}
