import 'dart:convert';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();

  static DatabaseService get instance => _instance;

  Database? _database;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, ClipConstants.databaseName);

    _database = await openDatabase(
      path,
      version: ClipConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _isInitialized = true;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${ClipConstants.clipItemsTable} (
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
      CREATE INDEX idx_clip_items_type ON ${ClipConstants.clipItemsTable}(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_created_at ON ${ClipConstants.clipItemsTable}(created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_is_favorite ON ${ClipConstants.clipItemsTable}(is_favorite)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 处理数据库升级
  }

  Future<void> insertClipItem(ClipItem item) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await _database!.insert(ClipConstants.clipItemsTable, {
      'id': item.id,
      'type': item.type.name,
      'content': item.content,
      'thumbnail': item.thumbnail,
      'metadata': jsonEncode(item.metadata),
      'is_favorite': item.isFavorite ? 1 : 0,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateClipItem(ClipItem item) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await _database!.update(
      ClipConstants.clipItemsTable,
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
    if (_database == null) throw Exception('Database not initialized');

    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllClipItems() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await _database!.delete(ClipConstants.clipItemsTable);
  }

  Future<List<ClipItem>> getAllClipItems({int? limit, int? offset}) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final List<Map<String, dynamic>> maps = await _database!.query(
      ClipConstants.clipItemsTable,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map(_mapToClipItem).toList();
  }

  Future<List<ClipItem>> getClipItemsByType(
    ClipType type, {
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final List<Map<String, dynamic>> maps = await _database!.query(
      ClipConstants.clipItemsTable,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map(_mapToClipItem).toList();
  }

  Future<List<ClipItem>> getFavoriteClipItems({int? limit, int? offset}) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final List<Map<String, dynamic>> maps = await _database!.query(
      ClipConstants.clipItemsTable,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map(_mapToClipItem).toList();
  }

  Future<List<ClipItem>> searchClipItems(
    String query, {
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final List<Map<String, dynamic>> maps = await _database!.query(
      ClipConstants.clipItemsTable,
      where: 'metadata LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map(_mapToClipItem).toList();
  }

  Future<ClipItem?> getClipItemById(String id) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final List<Map<String, dynamic>> maps = await _database!.query(
      ClipConstants.clipItemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToClipItem(maps.first);
  }

  Future<void> toggleFavorite(String id) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final item = await getClipItemById(id);
    if (item != null) {
      await updateClipItem(item.copyWith(isFavorite: !item.isFavorite));
    }
  }

  Future<int> getClipItemsCount() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getClipItemsCountByType(ClipType type) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} WHERE type = ?',
      [type.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFavoriteClipItemsCount() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} WHERE is_favorite = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteOldClipItems(int maxAgeInDays) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));

    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  Future<void> deleteClipItemsByType(ClipType type) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'type = ?',
      whereArgs: [type.name],
    );
  }

  ClipItem _mapToClipItem(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final typeName = map['type'] as String?;
    final contentRaw = map['content'];
    final thumbRaw = map['thumbnail'];
    final metadataRaw = map['metadata'];
    final isFavRaw = map['is_favorite'];
    final createdAtRaw = map['created_at'];
    final updatedAtRaw = map['updated_at'];

    Map<String, dynamic> metadata;
    if (metadataRaw is String) {
      final decoded = jsonDecode(metadataRaw);
      metadata = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } else if (metadataRaw is Map<String, dynamic>) {
      metadata = metadataRaw;
    } else if (metadataRaw is Map) {
      metadata = Map<String, dynamic>.from(metadataRaw);
    } else {
      metadata = <String, dynamic>{};
    }

    return ClipItem(
      id: id,
      type: ClipType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => ClipType.text,
      ),
      content: contentRaw is List ? List<int>.from(contentRaw) : <int>[],
      thumbnail: thumbRaw is List ? List<int>.from(thumbRaw) : null,
      metadata: metadata,
      isFavorite: isFavRaw == 1 || isFavRaw == true,
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : (createdAtRaw is DateTime ? createdAtRaw : DateTime.now()),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw) ?? DateTime.now()
          : (updatedAtRaw is DateTime ? updatedAtRaw : DateTime.now()),
    );
  }

  Future<void> close() async {
    await _database?.close();
    _isInitialized = false;
  }
}
