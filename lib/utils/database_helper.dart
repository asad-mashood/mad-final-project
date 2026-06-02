// utils/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game_result.dart';
import '../models/player_profile.dart';

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        courtName TEXT NOT NULL,
        playerName TEXT DEFAULT 'Player',
        difficulty TEXT DEFAULT 'Medium'
      )
    ''');

    await db.execute('''
      CREATE TABLE player_profile (
        id INTEGER PRIMARY KEY,
        playerName TEXT NOT NULL,
        age INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        racket TEXT NOT NULL,
        shoes TEXT NOT NULL,
        shirtStyle TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE match_history ADD COLUMN playerName TEXT DEFAULT "Player"',
      );
      await db.execute(
        'ALTER TABLE match_history ADD COLUMN difficulty TEXT DEFAULT "Medium"',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE player_profile (
          id INTEGER PRIMARY KEY,
          playerName TEXT NOT NULL,
          age INTEGER NOT NULL,
          difficulty TEXT NOT NULL,
          racket TEXT NOT NULL,
          shoes TEXT NOT NULL,
          shirtStyle TEXT NOT NULL
        )
      ''');
    }
  }

  // Insert a new game result
  Future<int> insertGameResult(GameResult result) async {
    final db = await database;
    return await db.insert('match_history', result.toMap());
  }

  // Get all match history (most recent first)
  Future<List<GameResult>> getMatchHistory() async {
    final db = await database;
    final maps = await db.query('match_history', orderBy: 'createdAt DESC');

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

  // Save or update the player profile.
  Future<int> savePlayerProfile(PlayerProfile profile) async {
    final db = await database;
    return await db.insert(
      'player_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get the player profile, if one exists.
  Future<PlayerProfile?> getPlayerProfile() async {
    final db = await database;
    final maps = await db.query(
      'player_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PlayerProfile.fromMap(maps.first);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
