import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game_result.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wimbledon.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE match_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playerScore INTEGER NOT NULL,
        aiScore INTEGER NOT NULL,
        result TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        courtName TEXT NOT NULL
      )
    ''');
  }

  // Insert a new game result
  Future<int> insertGameResult(GameResult result) async {
    final db = await database;
    return await db.insert('match_history', result.toMap());
  }

  // Get all match history (most recent first)
  Future<List<GameResult>> getMatchHistory() async {
    final db = await database;
    final maps = await db.query(
      'match_history',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => GameResult.fromMap(map)).toList();
  }

  // Get recent matches (limit)
  Future<List<GameResult>> getRecentMatches(int limit) async {
    final db = await database;
    final maps = await db.query(
      'match_history',
      orderBy: 'createdAt DESC',
      limit: limit,
    );

    return maps.map((map) => GameResult.fromMap(map)).toList();
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
