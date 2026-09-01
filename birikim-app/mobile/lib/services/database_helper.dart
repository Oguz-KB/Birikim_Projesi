import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('birikim.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE cached_categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          is_guilty_pleasure INTEGER NOT NULL,
          penalty_multiplier TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL,
        raw_amount TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_guilty_pleasure INTEGER NOT NULL,
        penalty_multiplier TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertQueue(String categoryId, String rawAmount) async {
    final db = await instance.database;
    return await db.insert('offline_queue', {
      'category_id': categoryId,
      'raw_amount': rawAmount,
    });
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final db = await instance.database;
    return await db.query('offline_queue');
  }

  Future<void> deleteQueue(int id) async {
    final db = await instance.database;
    await db.delete('offline_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    final db = await instance.database;
    Batch batch = db.batch();
    batch.delete('cached_categories');
    for (var cat in categories) {
      batch.insert('cached_categories', cat);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCachedCategories() async {
    final db = await instance.database;
    return await db.query('cached_categories');
  }
}
