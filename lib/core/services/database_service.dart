import 'dart:convert';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 数据库服务类
///
/// 提供对数据库的增删改查操作
class DatabaseService {
  /// 工厂构造：返回数据库服务单例
  factory DatabaseService() => _instance;

  /// 私有构造：单例内部初始化
  DatabaseService._internal();

  /// 单例实例
  static final DatabaseService _instance = DatabaseService._internal();

  /// 获取数据库服务单例
  static DatabaseService get instance => _instance;

  /// 底层数据库连接
  Database? _database;

  /// 是否已完成初始化
  bool _isInitialized = false;

  /// 初始化数据库
  ///
  /// - 计算数据库路径并打开/创建数据库
  /// - 设置版本及 onCreate/onUpgrade 回调
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

  /// 新增或替换一条剪贴项记录
  ///
  /// 参数：
  /// - item：要插入的剪贴项（若主键重复则替换）
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

  /// 更新一条剪贴项记录
  ///
  /// 参数：
  /// - item：包含最新数据的剪贴项（依据 id 定位）
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

  /// 删除指定 id 的剪贴项
  ///
  /// 参数：
  /// - id：剪贴项主键
  Future<void> deleteClipItem(String id) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有剪贴项
  Future<void> clearAllClipItems() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await _database!.delete(ClipConstants.clipItemsTable);
  }

  /// 获取所有剪贴项（按创建时间倒序）
  ///
  /// 参数：
  /// - limit：返回数量上限
  /// - offset：偏移量（用于分页）
  ///
  /// 返回：剪贴项列表
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

  /// 按类型获取剪贴项（倒序）
  ///
  /// 参数：
  /// - type：剪贴类型
  /// - limit/offset：分页参数
  ///
  /// 返回：剪贴项列表
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

  /// 获取收藏的剪贴项（倒序）
  ///
  /// 参数：
  /// - limit/offset：分页参数
  ///
  /// 返回：剪贴项列表
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

  /// 搜索剪贴项（在 metadata JSON 文本中模糊匹配）
  ///
  /// 参数：
  /// - query：关键字
  /// - limit/offset：分页参数
  ///
  /// 返回：匹配的剪贴项列表
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

  /// 通过 id 获取剪贴项
  ///
  /// 参数：
  /// - id：剪贴项主键
  ///
  /// 返回：存在则为 ClipItem，否则为 null
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

  /// 切换指定剪贴项的收藏状态
  ///
  /// 参数：
  /// - id：剪贴项主键
  Future<void> toggleFavorite(String id) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final item = await getClipItemById(id);
    if (item != null) {
      await updateClipItem(item.copyWith(isFavorite: !item.isFavorite));
    }
  }

  /// 获取所有剪贴项数量
  ///
  /// 返回：计数
  Future<int> getClipItemsCount() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取指定类型的剪贴项数量
  ///
  /// 参数：
  /// - type：剪贴类型
  ///
  /// 返回：计数
  Future<int> getClipItemsCountByType(ClipType type) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} WHERE type = ?',
      [type.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取收藏的剪贴项数量
  ///
  /// 返回：计数
  Future<int> getFavoriteClipItemsCount() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} WHERE is_favorite = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 删除早于指定天数的历史剪贴项
  ///
  /// 参数：
  /// - maxAgeInDays：最大保留天数
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

  /// 删除指定类型的剪贴项
  ///
  /// 参数：
  /// - type：剪贴类型
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

  /// 关闭数据库连接并重置初始化状态
  Future<void> close() async {
    await _database?.close();
    _isInitialized = false;
  }
}
