import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite database initialization and management
class AppDatabase {
  static const String _dbName = 'smartcampus.db';
  static const int _version = 1;

  static const String announcements = 'announcements';
  static const String events = 'events';
  static const String timetable = 'timetable';
  static const String preferences = 'preferences';

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
      CREATE TABLE $preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implement future migrations here if needed
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
    await db.delete(preferences);
  }
}

class _InMemoryDb {
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  int _autoId = 1;

  Future<int> insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm}) async {
    final t = _tables.putIfAbsent(table, () => []);
    final row = Map<String, dynamic>.from(values);
    if (!row.containsKey('id')) row['id'] = _autoId++;
    final idx = t.indexWhere((r) => r['id'] == row['id']);
    if (idx >= 0) t[idx] = row; else t.add(row);
    return row['id'] as int;
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy, int? limit}) async {
    final list = _tables[table] ?? [];
    Iterable<Map<String, dynamic>> results = list;
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      if (where.contains('id = ?')) {
        final id = whereArgs.first;
        results = results.where((r) => r['id'] == id);
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
    final list = _tables.putIfAbsent(table, () => []);
    if (where == null) {
      final count = list.length;
      _tables[table] = [];
      return count;
    }
    if (where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      final before = list.length;
      list.removeWhere((r) => r['id'] == id);
      return before - list.length;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql) async {
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
