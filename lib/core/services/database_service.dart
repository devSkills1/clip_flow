import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/clip_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  Database? _database;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'clipflow_pro.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _isInitialized = true;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clip_items (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        content BLOB NOT NULL,
        thumbnail BLOB,
        metadata TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_type ON clip_items(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_created_at ON clip_items(created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_is_favorite ON clip_items(is_favorite)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 处理数据库升级
  }

  Future<void> insertClipItem(ClipItem item) async {
    if (!_isInitialized) await initialize();

    await _database!.insert(
      'clip_items',
      {
        'id': item.id,
        'type': item.type.name,
        'content': item.content,
        'thumbnail': item.thumbnail,
        'metadata': jsonEncode(item.metadata),
        'is_favorite': item.isFavorite ? 1 : 0,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateClipItem(ClipItem item) async {
    if (!_isInitialized) await initialize();

    await _database!.update(
      'clip_items',
      {
        'type': item.type.name,
        'content': item.content,
        'thumbnail': item.thumbnail,
        'metadata': jsonEncode(item.metadata),
        'is_favorite': item.isFavorite ? 1 : 0,
        'updated_at': item.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteClipItem(String id) async {
    if (!_isInitialized) await initialize();

    await _database!.delete(
      'clip_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllClipItems() async {
    if (!_isInitialized) await initialize();

    await _database!.delete('clip_items');
  }

  Future<List<ClipItem>> getAllClipItems({int? limit, int? offset}) async {
    if (!_isInitialized) await initialize();

    final List<Map<String, dynamic>> maps = await _database!.query(
      'clip_items',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _mapToClipItem(map)).toList();
  }

  Future<List<ClipItem>> getClipItemsByType(ClipType type, {int? limit, int? offset}) async {
    if (!_isInitialized) await initialize();

    final List<Map<String, dynamic>> maps = await _database!.query(
      'clip_items',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _mapToClipItem(map)).toList();
  }

  Future<List<ClipItem>> getFavoriteClipItems({int? limit, int? offset}) async {
    if (!_isInitialized) await initialize();

    final List<Map<String, dynamic>> maps = await _database!.query(
      'clip_items',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _mapToClipItem(map)).toList();
  }

  Future<List<ClipItem>> searchClipItems(String query, {int? limit, int? offset}) async {
    if (!_isInitialized) await initialize();

    final List<Map<String, dynamic>> maps = await _database!.query(
      'clip_items',
      where: 'metadata LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _mapToClipItem(map)).toList();
  }

  Future<ClipItem?> getClipItemById(String id) async {
    if (!_isInitialized) await initialize();

    final List<Map<String, dynamic>> maps = await _database!.query(
      'clip_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToClipItem(maps.first);
  }

  Future<void> toggleFavorite(String id) async {
    if (!_isInitialized) await initialize();

    final item = await getClipItemById(id);
    if (item != null) {
      await updateClipItem(item.copyWith(isFavorite: !item.isFavorite));
    }
  }

  Future<int> getClipItemsCount() async {
    if (!_isInitialized) await initialize();

    final result = await _database!.rawQuery('SELECT COUNT(*) as count FROM clip_items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getClipItemsCountByType(ClipType type) async {
    if (!_isInitialized) await initialize();

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM clip_items WHERE type = ?',
      [type.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFavoriteClipItemsCount() async {
    if (!_isInitialized) await initialize();

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM clip_items WHERE is_favorite = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteOldClipItems(int maxAgeInDays) async {
    if (!_isInitialized) await initialize();

    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
    
    await _database!.delete(
      'clip_items',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  Future<void> deleteClipItemsByType(ClipType type) async {
    if (!_isInitialized) await initialize();

    await _database!.delete(
      'clip_items',
      where: 'type = ?',
      whereArgs: [type.name],
    );
  }

  ClipItem _mapToClipItem(Map<String, dynamic> map) {
    return ClipItem(
      id: map['id'],
      type: ClipType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ClipType.text,
      ),
      content: map['content'] as List<int>,
      thumbnail: map['thumbnail'] as List<int>?,
      metadata: jsonDecode(map['metadata']),
      isFavorite: map['is_favorite'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Future<void> close() async {
    await _database?.close();
    _isInitialized = false;
  }
}
