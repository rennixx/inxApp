import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inx.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE manga (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT,
        cover_path TEXT,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        current_page INTEGER DEFAULT 0,
        total_pages INTEGER DEFAULT 0,
        last_read INTEGER,
        is_favorited INTEGER DEFAULT 0,
        tags TEXT,
        reading_progress REAL DEFAULT 0.0,
        file_size INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_title ON manga(title)
    ''');

    await db.execute('''
      CREATE INDEX idx_favorited ON manga(is_favorited)
    ''');

    await db.execute('''
      CREATE INDEX idx_last_read ON manga(last_read)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database upgrades
    AppLogger.info('Upgrading database from $oldVersion to $newVersion');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
