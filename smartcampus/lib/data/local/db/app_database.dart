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

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  /// Get database instance, initializing if needed
  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
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
