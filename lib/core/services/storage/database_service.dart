import 'dart:convert';
import 'dart:io';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:path/path.dart';
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

    final path = await PathService.instance.getDatabasePath(
      ClipConstants.databaseName,
    );

    _database = await openDatabase(
      path,
      version: ClipConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // 在线迁移：确保历史库补齐新列（不清库、不中断）
    await _ensureColumnsExist(_database!);

    _isInitialized = true;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${ClipConstants.clipItemsTable} (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        content TEXT,
        file_path TEXT,
        thumbnail BLOB,
        metadata TEXT NOT NULL DEFAULT '{}',
        ocr_text TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        schema_version INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_created_at ON ${ClipConstants.clipItemsTable}(created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_is_favorite ON ${ClipConstants.clipItemsTable}(is_favorite)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_type ON ${ClipConstants.clipItemsTable}(type)
    ''');

    // OCR相关索引
    await db.execute('''
      CREATE INDEX idx_clip_items_ocr_text_id ON ${ClipConstants.clipItemsTable}(ocr_text_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_parent_image_id ON ${ClipConstants.clipItemsTable}(parent_image_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_clip_items_is_ocr_extracted ON ${ClipConstants.clipItemsTable}(is_ocr_extracted)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 处理数据库升级（版本迁移），并兜底在线检查列
    await _ensureColumnsExist(db);

    // 创建OCR相关索引（如果不存在）
    await _ensureIndexExists(db, 'idx_clip_items_ocr_text_id', ClipConstants.clipItemsTable, 'ocr_text_id');
    await _ensureIndexExists(db, 'idx_clip_items_parent_image_id', ClipConstants.clipItemsTable, 'parent_image_id');
    await _ensureIndexExists(db, 'idx_clip_items_is_ocr_extracted', ClipConstants.clipItemsTable, 'is_ocr_extracted');
  }

  /// 新增或替换一条剪贴项记录
  ///
  /// 参数：
  /// - item：要插入的剪贴项（若主键重复则替换）
  Future<void> insertClipItem(ClipItem item) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    // 在插入前检查是否已存在相同ID的记录
    final existingItem = await getClipItemById(item.id);
    if (existingItem != null) {
      await Log.d(
        'Clip item already exists, updating existing record',
        tag: 'DatabaseService',
        fields: {
          'id': item.id,
          'type': item.type.name,
          'existingCreatedAt': existingItem.createdAt.toIso8601String(),
          'newCreatedAt': item.createdAt.toIso8601String(),
        },
      );

      // 如果记录已存在，使用更新操作而不是插入
      await updateClipItem(item);
      return;
    }

    await Log.i(
      'Inserting clip item with OCR data',
      tag: 'DatabaseService',
      fields: {
        'id': item.id,
        'type': item.type.name,
        'hasOcrText': item.ocrText != null && item.ocrText!.isNotEmpty,
        'ocrTextLength': item.ocrText?.length ?? 0,
        'hasOcrConfidence': item.metadata.containsKey('ocrConfidence'),
        'ocrConfidence': item.metadata['ocrConfidence'],
      },
    );

    await _database!.insert(ClipConstants.clipItemsTable, {
      'id': item.id,
      'type': item.type.name,
      'content': item.content is String
          ? item.content
          : (item.content?.toString() ?? ''),
      'file_path': item.filePath,
      'thumbnail': item.thumbnail,
      'metadata': jsonEncode(item.metadata),
      'ocr_text': item.ocrText,
      'ocr_text_id': item.ocrTextId,
      'parent_image_id': item.parentImageId,
      'is_ocr_extracted': item.isOcrExtracted ? 1 : 0,
      'origin_width': item.originWidth,
      'origin_height': item.originHeight,
      'is_favorite': item.isFavorite ? 1 : 0,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
      'schema_version': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore); // 改为 ignore，避免重复插入

    await Log.d(
      'Clip item inserted successfully',
      tag: 'DatabaseService',
      fields: {
        'id': item.id,
        'type': item.type.name,
      },
    );
  }

  /// 批量插入剪贴项记录
  ///
  /// 参数：
  /// - items：要插入的剪贴项列表
  /// - useTransaction：是否使用事务（默认true）
  Future<void> batchInsertClipItems(
    List<ClipItem> items, {
    bool useTransaction = true,
  }) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');
    if (items.isEmpty) return;

    final stopwatch = Stopwatch()..start();

    await Log.i(
      'Starting batch insert with duplicate checking',
      tag: 'DatabaseService',
      fields: {
        'count': items.length,
        'useTransaction': useTransaction,
      },
    );

    try {
      // 预先过滤掉已存在的项目，避免重复
      final uniqueItems = <ClipItem>[];
      final duplicateCount = <String, int>{};

      for (final item in items) {
        final existingItem = await getClipItemById(item.id);
        if (existingItem == null) {
          uniqueItems.add(item);
        } else {
          duplicateCount[item.type.name] =
              (duplicateCount[item.type.name] ?? 0) + 1;
        }
      }

      if (duplicateCount.isNotEmpty) {
        await Log.i(
          'Filtered out duplicate items in batch insert',
          tag: 'DatabaseService',
          fields: {
            'originalCount': items.length,
            'uniqueCount': uniqueItems.length,
            'duplicateCount': duplicateCount,
          },
        );
      }

      if (uniqueItems.isEmpty) {
        await Log.d(
          'All items were duplicates, skipping batch insert',
          tag: 'DatabaseService',
        );
        return;
      }

      if (useTransaction) {
        await _database!.transaction((txn) async {
          final batch = txn.batch();

          for (final item in uniqueItems) {
            batch.insert(
              ClipConstants.clipItemsTable,
              {
                'id': item.id,
                'type': item.type.name,
                'content': item.content is String
                    ? item.content
                    : (item.content?.toString() ?? ''),
                'file_path': item.filePath,
                'thumbnail': item.thumbnail,
                'metadata': jsonEncode(item.metadata),
                'ocr_text': item.ocrText,
                'is_favorite': item.isFavorite ? 1 : 0,
                'created_at': item.createdAt.toIso8601String(),
                'updated_at': item.updatedAt.toIso8601String(),
                'schema_version': 1,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore, // 改为 ignore
            );
          }

          await batch.commit();
        });
      } else {
        // 不使用事务，单独插入
        for (final item in uniqueItems) {
          await insertClipItem(item);
        }
      }

      stopwatch.stop();

      await Log.i(
        'Batch insert completed successfully',
        tag: 'DatabaseService',
        fields: {
          'originalCount': items.length,
          'uniqueCount': uniqueItems.length,
          'duplicateCount': duplicateCount,
          'duration': stopwatch.elapsedMilliseconds,
          'avgTimePerItem': stopwatch.elapsedMilliseconds / uniqueItems.length,
          'useTransaction': useTransaction,
        },
      );
    } on Exception catch (e) {
      stopwatch.stop();

      await Log.e(
        'Batch insert failed',
        tag: 'DatabaseService',
        error: e,
        fields: {
          'count': items.length,
          'duration': stopwatch.elapsedMilliseconds,
          'useTransaction': useTransaction,
        },
      );

      rethrow;
    }
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
        'content': item.content is String
            ? item.content
            : (item.content?.toString() ?? ''),
        'file_path': item.filePath,
        'thumbnail': item.thumbnail,
        'metadata': jsonEncode(item.metadata),
        'ocr_text': item.ocrText,
        'is_favorite': item.isFavorite ? 1 : 0,
        'updated_at': item.updatedAt.toIso8601String(),
        'schema_version': 1,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 更新剪贴板项目的收藏状态
  ///
  /// 参数：
  /// - id：剪贴项主键
  /// - isFavorite：收藏状态
  Future<void> updateFavoriteStatus({required String id, required bool isFavorite}) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await _database!.update(
      ClipConstants.clipItemsTable,
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
        'schema_version': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除指定 id 的剪贴项
  ///
  /// 参数：
  /// - id：剪贴项主键
  Future<void> deleteClipItem(String id) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    // 先查询 file_path 用于删除磁盘文件
    final item = await getClipItemById(id);
    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    // 尝试删除媒体文件
    if (item?.filePath != null && item!.filePath!.isNotEmpty) {
      await _deleteMediaFileSafe(item.filePath!);
    }
  }

  /// 清空所有剪贴项（保留收藏的项目）
  Future<void> clearAllClipItemsExceptFavorites() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    // 只删除非收藏的项目
    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'is_favorite = ?',
      whereArgs: [0],
    );

    // 清理媒体文件（只删除非收藏项目的文件）
    await _cleanupMediaFilesExceptFavorites();
  }

  /// 清空所有剪贴项（包括收藏的项目）
  Future<void> clearAllClipItems() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    // 清空数据库
    await _database!.delete(ClipConstants.clipItemsTable);

    // 直接删除整个媒体目录（更高效）
    await _deleteMediaDirectorySafe();
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

  /// 搜索剪贴项（在 content、metadata 和 OCR 文本中模糊匹配）
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

    await Log.i(
      'Searching clip items with OCR text support',
      tag: 'DatabaseService',
      fields: {
        'query': query,
        'limit': limit,
        'offset': offset,
      },
    );

    // 搜索内容、元数据和OCR文本
    final List<Map<String, dynamic>> maps = await _database!.query(
      ClipConstants.clipItemsTable,
      where: '''
        content LIKE ? OR 
        metadata LIKE ? OR 
        ocr_text LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final results = maps.map(_mapToClipItem).toList();

    await Log.i(
      'Search completed with OCR text support',
      tag: 'DatabaseService',
      fields: {
        'query': query,
        'resultCount': results.length,
        'hasOcrMatches': results.any(
          (item) =>
              item.ocrText?.toLowerCase().contains(query.toLowerCase()) ??
              false,
        ),
      },
    );

    return results;
  }

  /// 搜索指定类型的剪贴项（支持OCR文本搜索）
  ///
  /// 参数：
  /// - query：搜索关键字
  /// - type：剪贴项类型（可选）
  /// - limit/offset：分页参数
  ///
  /// 返回：匹配的剪贴项列表
  Future<List<ClipItem>> searchClipItemsByType(
    String query, {
    ClipType? type,
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await Log.i(
      'Searching clip items by type with OCR text support',
      tag: 'DatabaseService',
      fields: {
        'query': query,
        'type': type?.name,
        'limit': limit,
        'offset': offset,
      },
    );

    var whereClause = '''
      content LIKE ? OR 
      metadata LIKE ? OR 
      ocr_text LIKE ?
    ''';
    final whereArgs = ['%$query%', '%$query%', '%$query%'];

    // 如果指定了类型，添加类型过滤
    if (type != null) {
      whereClause = '($whereClause) AND type = ?';
      whereArgs.add(type.name);
    }

    final List<Map<String, dynamic>> maps = await _database!.query(
      ClipConstants.clipItemsTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final results = maps.map(_mapToClipItem).toList();

    await Log.i(
      'Type-specific search completed with OCR text support',
      tag: 'DatabaseService',
      fields: {
        'query': query,
        'type': type?.name,
        'resultCount': results.length,
        'hasOcrMatches': results.any(
          (item) =>
              item.ocrText?.toLowerCase().contains(query.toLowerCase()) ??
              false,
        ),
      },
    );

    return results;
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
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} '
      'WHERE type = ?',
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
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} '
      'WHERE is_favorite = 1',
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

    // 先找出要删的 id 与 file_path
    final stale = await _database!.query(
      ClipConstants.clipItemsTable,
      columns: ['id', 'file_path'],
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    for (final row in stale) {
      final path = row['file_path'] as String?;
      if (path != null && path.isNotEmpty) {
        await _deleteMediaFileSafe(path);
      }
    }
  }

  /// 删除指定类型的剪贴项
  ///
  /// 参数：
  /// - type：剪贴类型
  Future<void> deleteClipItemsByType(ClipType type) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    // 取出将被删除的 file_path
    final rows = await _database!.query(
      ClipConstants.clipItemsTable,
      columns: ['file_path'],
      where: 'type = ?',
      whereArgs: [type.name],
    );

    await _database!.delete(
      ClipConstants.clipItemsTable,
      where: 'type = ?',
      whereArgs: [type.name],
    );

    for (final r in rows) {
      final p = r['file_path'] as String?;
      if (p != null && p.isNotEmpty) {
        await _deleteMediaFileSafe(p);
      }
    }
  }

  ClipItem _mapToClipItem(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final typeName = map['type'] as String?;
    final contentRaw = map['content'];
    final filePathRaw = map['file_path'];
    final thumbRaw = map['thumbnail'];
    final metadataRaw = map['metadata'];
    final ocrTextRaw = map['ocr_text'];
    final ocrTextIdRaw = map['ocr_text_id'];
    final parentImageIdRaw = map['parent_image_id'];
    final isOcrExtractedRaw = map['is_ocr_extracted'];
    final originWidthRaw = map['origin_width'];
    final originHeightRaw = map['origin_height'];
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
      content: contentRaw is String
          ? contentRaw
          : (contentRaw?.toString() ?? ''),
      filePath: filePathRaw is String ? filePathRaw : null,
      thumbnail: thumbRaw is List ? List<int>.from(thumbRaw) : null,
      metadata: metadata,
      ocrText: ocrTextRaw is String ? ocrTextRaw : null,
      ocrTextId: ocrTextIdRaw is String ? ocrTextIdRaw : null,
      parentImageId: parentImageIdRaw is String ? parentImageIdRaw : null,
      isOcrExtracted: isOcrExtractedRaw == 1 || isOcrExtractedRaw == true,
      originWidth: originWidthRaw is num ? originWidthRaw.toInt() : null,
      originHeight: originHeightRaw is num ? originHeightRaw.toInt() : null,
      isFavorite: isFavRaw == 1 || isFavRaw == true,
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : (createdAtRaw is DateTime ? createdAtRaw : DateTime.now()),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw) ?? DateTime.now()
          : (updatedAtRaw is DateTime ? updatedAtRaw : DateTime.now()),
    );
  }

  /// 安全删除指定的媒体文件
  ///
  /// 参数：
  /// - relativePath：相对路径，如 'media/image.jpg'
  Future<void> _deleteMediaFileSafe(String relativePath) async {
    try {
      final absPath = await _resolveAbsoluteMediaPath(relativePath);
      final file = File(absPath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on FileSystemException catch (_) {}
  }

  /// 解析相对媒体路径为绝对路径
  ///
  /// 参数：
  /// - relativePath：相对路径，如 'media/image.jpg'
  Future<String> _resolveAbsoluteMediaPath(String relativePath) async {
    final documentsDirectory = await PathService.instance
        .getDocumentsDirectory();
    return join(documentsDirectory.path, relativePath);
  }

  /// 安全删除整个媒体目录
  Future<void> _deleteMediaDirectorySafe() async {
    try {
      final documentsDirectory = await PathService.instance
          .getDocumentsDirectory();
      final mediaDirectory = Directory(join(documentsDirectory.path, 'media'));
      if (mediaDirectory.existsSync()) {
        await mediaDirectory.delete(recursive: true);
      }
    } on FileSystemException catch (_) {
      // 忽略文件系统异常，避免阻塞清空操作
    }
  }

  /// 清理媒体文件（只删除非收藏项目的文件）
  Future<void> _cleanupMediaFilesExceptFavorites() async {
    try {
      // 获取所有非收藏项目的文件路径
      final List<Map<String, dynamic>> nonFavoriteItems = await _database!.query(
        ClipConstants.clipItemsTable,
        columns: ['file_path', 'thumbnail'],
        where: 'is_favorite = ? AND (file_path IS NOT NULL OR thumbnail IS NOT NULL)',
        whereArgs: [0],
      );

      final documentsDirectory = await PathService.instance.getDocumentsDirectory();
      final mediaDirectory = Directory(join(documentsDirectory.path, 'media'));

      if (mediaDirectory.existsSync()) {
        // 删除非收藏项目的文件
        for (final item in nonFavoriteItems) {
          final filePath = item['file_path'] as String?;

          // 删除主文件
          if (filePath != null && filePath.isNotEmpty) {
            await _deleteMediaFileSafe(filePath);
          }

          // 注意：缩略图存储为二进制数据在数据库中，不需要单独删除文件
        }
      }
    } on FileSystemException catch (_) {
      // 忽略文件系统异常，避免阻塞操作
    } on Exception catch (e) {
      // 记录其他异常但不抛出
      await Log.w('Error cleaning media files except favorites',
            tag: 'DatabaseService', error: e);
    }
  }

  /// 扫描媒体目录，删除未在 DB 引用的"孤儿文件"
  /// retainDays: 保留最近 N 天内的文件，避免误删
  Future<int> cleanOrphanMediaFiles({int retainDays = 3}) async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final documentsDirectory = await PathService.instance
        .getDocumentsDirectory();
    final mediaRoot = Directory(join(documentsDirectory.path, 'media'));
    if (!mediaRoot.existsSync()) return 0;

    // 读取数据库中所有 file_path 引用
    final rows = await _database!.query(
      ClipConstants.clipItemsTable,
      columns: ['file_path'],
      where: 'file_path IS NOT NULL AND file_path != ""',
    );
    final referenced = rows
        .map((r) => r['file_path'] as String?)
        .where((p) => p != null && p.isNotEmpty)
        .map((p) => join(documentsDirectory.path, p))
        .toSet();

    final cutoff = DateTime.now().subtract(Duration(days: retainDays));
    var deleted = 0;

    await for (final entity in mediaRoot.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final path = entity.path;

      if (path.endsWith('.tmp')) continue;

      final stat = entity.statSync();
      if (stat.modified.isAfter(cutoff)) continue;

      if (!referenced.contains(path)) {
        try {
          await entity.delete();
          deleted++;
        } on FileSystemException catch (_) {}
      }
    }
    return deleted;
  }

  /// 关闭数据库连接并重置初始化状态
  Future<void> close() async {
    await _database?.close();
    _isInitialized = false;
  }

  // === 在线迁移辅助：确保缺失列被补齐（安全、幂等） ===
  Future<void> _ensureColumnsExist(Database db) async {
    // clip_items: file_path TEXT
    final hasFilePath = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'file_path',
    );
    if (!hasFilePath) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} ADD COLUMN file_path TEXT',
      );
    }

    // clip_items: thumbnail BLOB
    final hasThumbnail = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'thumbnail',
    );
    if (!hasThumbnail) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} ADD COLUMN thumbnail BLOB',
      );
    }

    // clip_items: schema_version INTEGER NOT NULL DEFAULT 1
    final hasSchemaVersion = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'schema_version',
    );
    if (!hasSchemaVersion) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} '
        'ADD COLUMN schema_version INTEGER NOT NULL DEFAULT 1',
      );
    }

    // clip_items: ocr_text TEXT
    final hasOcrText = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'ocr_text',
    );
    if (!hasOcrText) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} ADD COLUMN ocr_text TEXT',
      );
    }

    // clip_items: ocr_text_id TEXT (OCR文本的独立ID)
    final hasOcrTextId = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'ocr_text_id',
    );
    if (!hasOcrTextId) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} ADD COLUMN ocr_text_id TEXT',
      );
    }

    // clip_items: parent_image_id TEXT (OCR文本的父图片ID)
    final hasParentImageId = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'parent_image_id',
    );
    if (!hasParentImageId) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} ADD COLUMN parent_image_id TEXT',
      );
    }

    // clip_items: is_ocr_extracted INTEGER NOT NULL DEFAULT 0 (是否已提取OCR)
    final hasIsOcrExtracted = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'is_ocr_extracted',
    );
    if (!hasIsOcrExtracted) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} '
        'ADD COLUMN is_ocr_extracted INTEGER NOT NULL DEFAULT 0',
      );
    }

    // clip_items: origin_width INTEGER (图片原始宽度)
    final hasOriginWidth = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'origin_width',
    );
    if (!hasOriginWidth) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} ADD COLUMN origin_width INTEGER',
      );
    }

    // clip_items: origin_height INTEGER (图片原始高度)
    final hasOriginHeight = await _columnExists(
      db,
      ClipConstants.clipItemsTable,
      'origin_height',
    );
    if (!hasOriginHeight) {
      await db.execute(
        'ALTER TABLE ${ClipConstants.clipItemsTable} ADD COLUMN origin_height INTEGER',
      );
    }

    // 预留：如未来新增列，可在此继续检测并 ALTER
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final rows = await db.rawQuery("PRAGMA table_info('$table')");
    for (final row in rows) {
      final name = row['name'];
      if (name == column) return true;
    }
    return false;
  }

  /// 检查索引是否存在，不存在则创建
  Future<void> _ensureIndexExists(Database db, String indexName, String table, String column) async {
    try {
      // 尝试创建索引，如果已存在会抛出异常
      await db.execute('CREATE INDEX IF NOT EXISTS $indexName ON $table($column)');
    } catch (e) {
      // 忽略索引已存在的错误
      await Log.d('Index $indexName already exists or creation failed: $e', tag: 'DatabaseService');
    }
  }

  /// 清理空内容的文本类型数据
  ///
  /// 删除 type 为 'text' 但 content 为空或只包含空白字符的记录
  /// 返回删除的记录数量
  Future<int> cleanEmptyTextItems() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final deletedCount = await _database!.delete(
      ClipConstants.clipItemsTable,
      where: "type = 'text' AND (content IS NULL OR TRIM(content) = '')",
    );

    await Log.i('Cleaned $deletedCount empty text items from database');
    return deletedCount;
  }

  /// 获取空内容的文本数据统计
  ///
  /// 返回 type 为 'text' 但 content 为空的记录数量
  Future<int> countEmptyTextItems() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} '
      "WHERE type = 'text' AND (content IS NULL OR TRIM(content) = '')",
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// 验证并修复数据完整性
  ///
  /// 执行多项数据完整性检查和修复：
  /// - 清理空内容的文本数据
  /// - 清理孤儿媒体文件
  /// - 清理重复记录（基于ID）
  /// 返回修复统计信息
  Future<Map<String, int>> validateAndRepairData() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    final stats = <String, int>{};

    // 清理空文本内容
    stats['emptyTextItemsDeleted'] = await cleanEmptyTextItems();

    // 清理重复记录
    stats['duplicateItemsDeleted'] = await cleanDuplicateItems();

    // 清理孤儿媒体文件
    stats['orphanFilesDeleted'] = await cleanOrphanMediaFiles();

    // 统计当前数据
    final totalItems = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable}',
    );
    stats['totalItemsRemaining'] = (totalItems.first['count'] as int?) ?? 0;

    await Log.i('Database validation completed: $stats');
    return stats;
  }

  /// 清理重复记录（基于ID）
  ///
  /// 删除具有相同ID的重复记录，保留最新的一个
  /// 返回删除的记录数量
  Future<int> cleanDuplicateItems() async {
    if (!_isInitialized) await initialize();
    if (_database == null) throw Exception('Database not initialized');

    await Log.i('Starting to clean duplicate items', tag: 'DatabaseService');

    // 查找重复记录
    final duplicates = await _database!.rawQuery('''
      SELECT id, COUNT(*) as count
      FROM ${ClipConstants.clipItemsTable}
      GROUP BY id
      HAVING COUNT(*) > 1
    ''');

    if (duplicates.isEmpty) {
      await Log.d('No duplicate items found', tag: 'DatabaseService');
      return 0;
    }

    var totalDeleted = 0;

    for (final duplicate in duplicates) {
      final id = duplicate['id'] as String?;

      // 跳过 id 为 null 的记录
      if (id == null) {
        await Log.w(
          'Found duplicate item with null id, skipping',
          tag: 'DatabaseService',
        );
        continue;
      }

      // 删除重复记录，保留最新的一个（基于created_at）
      final deleted = await _database!.rawQuery(
        '''
        DELETE FROM ${ClipConstants.clipItemsTable}
        WHERE id = ? AND rowid NOT IN (
          SELECT rowid FROM ${ClipConstants.clipItemsTable}
          WHERE id = ?
          ORDER BY created_at DESC, rowid DESC
          LIMIT 1
        )
      ''',
        [id, id],
      );

      final deletedCount = Sqflite.firstIntValue(deleted) ?? 0;
      totalDeleted += deletedCount;

      await Log.d(
        'Cleaned duplicates for item',
        tag: 'DatabaseService',
        fields: {
          'id': id,
          'deletedCount': deletedCount,
        },
      );
    }

    await Log.i(
      'Cleaned duplicate items successfully',
      tag: 'DatabaseService',
      fields: {'totalDeleted': totalDeleted},
    );

    return totalDeleted;
  }
}
