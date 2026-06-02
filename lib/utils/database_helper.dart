// utils/database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game_result.dart';
import '../models/player_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory database fallback for Web or unsupported platforms
  final List<GameResult> _inMemoryHistory = [];
  PlayerProfile? _inMemoryProfile;
  bool _databaseError = kIsWeb;

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
    if (_databaseError) {
      _inMemoryHistory.insert(0, result);
      return _inMemoryHistory.length;
    }
    try {
      final db = await database;
      return await db.insert('match_history', result.toMap());
    } catch (e) {
      debugPrint('Error inserting game result: $e');
      _databaseError = true;
      _inMemoryHistory.insert(0, result);
      return _inMemoryHistory.length;
    }
  }

  // Get all match history (most recent first)
  Future<List<GameResult>> getMatchHistory() async {
    if (_databaseError) {
      return List.from(_inMemoryHistory);
    }
    try {
      final db = await database;
      final maps = await db.query('match_history', orderBy: 'createdAt DESC');
      return maps.map((map) => GameResult.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting match history: $e');
      _databaseError = true;
      return List.from(_inMemoryHistory);
    }
  }

  // Get recent matches (limit)
  Future<List<GameResult>> getRecentMatches(int limit) async {
    if (_databaseError) {
      return _inMemoryHistory.take(limit).toList();
    }
    try {
      final db = await database;
      final maps = await db.query(
        'match_history',
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      return maps.map((map) => GameResult.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting recent matches: $e');
      _databaseError = true;
      return _inMemoryHistory.take(limit).toList();
    }
  }

  // Save or update the player profile.
  Future<int> savePlayerProfile(PlayerProfile profile) async {
    if (_databaseError) {
      _inMemoryProfile = profile;
      return 1;
    }
    try {
      final db = await database;
      return await db.insert(
        'player_profile',
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving player profile: $e');
      _databaseError = true;
      _inMemoryProfile = profile;
      return 1;
    }
  }

  // Get the player profile, if one exists.
  Future<PlayerProfile?> getPlayerProfile() async {
    if (_databaseError) {
      return _inMemoryProfile;
    }
    try {
      final db = await database;
      final maps = await db.query(
        'player_profile',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return PlayerProfile.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting player profile: $e');
      _databaseError = true;
      return _inMemoryProfile;
    }
  }

  // Close database
  Future<void> close() async {
    if (_databaseError) return;
    try {
      final db = await database;
      await db.close();
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }
}
