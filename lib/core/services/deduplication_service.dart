import 'dart:async';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';

/// 集中化去重服务
/// 统一处理所有去重逻辑，避免多层检查冲突
class DeduplicationService {
  DeduplicationService._();

  static final DeduplicationService _instance = DeduplicationService._internal();
  static DeduplicationService get instance => _instance;

  factory DeduplicationService() => _instance;

  DeduplicationService._internal();

  /// 检查并准备剪贴项，确保去重逻辑统一
  Future<ClipItem?> checkAndPrepare(String contentHash, ClipItem newItem) async {
    try {
      await Log.d(
        'Checking for duplicate content',
        tag: 'DeduplicationService',
        fields: {
          'contentHash': contentHash,
          'itemType': newItem.type.name,
          'hasContent': newItem.content?.isNotEmpty ?? false,
          'hasFilePath': newItem.filePath?.isNotEmpty ?? false,
        },
      );

      // 单一数据库检查
      final existing = await _checkDatabaseExists(contentHash);
      if (existing != null) {
        await Log.i(
          'Found existing item, updating timestamp',
          tag: 'DeduplicationService',
          fields: {
            'existingId': existing.id,
            'newId': newItem.id,
            'existingCreatedAt': existing.createdAt.toIso8601String(),
            'newCreatedAt': newItem.createdAt.toIso8601String(),
          },
        );

        // 返回更新后的现有项目
        return existing.copyWith(
          updatedAt: DateTime.now(),
          // 如果新项目有更好的缩略图或OCR，也更新这些字段
          thumbnail: newItem.thumbnail ?? existing.thumbnail,
          ocrText: newItem.ocrText ?? existing.ocrText,
          // 合并元数据，保留最新的信息
          metadata: {...existing.metadata, ...newItem.metadata},
        );
      }

      await Log.i(
        'No existing item found, creating new',
        tag: 'DeduplicationService',
        fields: {
          'itemId': newItem.id,
          'itemType': newItem.type.name,
        },
      );

      // 没有找到重复，返回新项目
      return newItem;
    } on Exception catch (e) {
      await Log.e(
        'Error during deduplication check',
        tag: 'DeduplicationService',
        error: e,
        fields: {
          'contentHash': contentHash,
          'itemType': newItem.type.name,
        },
      );
      // 发生错误时，允许创建新项目，避免数据丢失
      return newItem;
    }
  }

  /// 检查数据库中是否已存在相同内容的项目
  Future<ClipItem?> _checkDatabaseExists(String contentHash) async {
    try {
      // 这里可以使用contentHash作为主键来查询
      // 如果数据库支持contentHash字段，可以直接查询
      // 否则需要根据内容类型和内容进行查询

      final databaseService = DatabaseService.instance;

      // 查询逻辑：根据ID查找（ID就是contentHash）
      final existing = await databaseService.getClipItemById(contentHash);

      if (existing != null) {
        return existing;
      }

      // 如果没有找到，返回null
      return null;
    } on Exception catch (e) {
      await Log.e(
        'Error checking database for existing item',
        tag: 'DeduplicationService',
        error: e,
        fields: {
          'contentHash': contentHash,
        },
      );
      return null;
    }
  }

  /// 验证ID格式是否有效
  bool isValidId(String? id) {
    return id != null &&
           id.isNotEmpty &&
           id.length == 64 && // SHA256 哈希的固定长度
           RegExp(r'^[a-f0-9]{64}$').hasMatch(id!);
  }

  /// 生成内容哈希（如果需要重新生成）
  String generateContentHash(Map<String, dynamic> content) {
    // 将内容转换为字符串并生成哈希
    final contentString = content.toString();
    final bytes = utf8.encode(contentString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 批量去重检查
  Future<List<ClipItem>> batchDeduplicate(List<ClipItem> items) async {
    final uniqueItems = <ClipItem>[];
    final seenHashes = <String>{};

    for (final item in items) {
      // 如果有contentHash且未见过，添加到结果中
      if (isValidId(item.id) && !seenHashes.contains(item.id)) {
        uniqueItems.add(item);
        seenHashes.add(item.id!);
      } else if (!isValidId(item.id)) {
        // 无效ID的项目，也添加（避免数据丢失）
        uniqueItems.add(item);
      }
    }

    await Log.i(
      'Batch deduplication completed',
      tag: 'DeduplicationService',
      fields: {
        'inputCount': items.length,
        'outputCount': uniqueItems.length,
        'removedCount': items.length - uniqueItems.length,
      },
    );

    return uniqueItems;
  }
}