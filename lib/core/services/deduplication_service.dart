import 'dart:async';
import 'dart:convert';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/id_generator.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:crypto/crypto.dart';

/// 集中化去重服务
/// 统一处理所有去重逻辑，避免多层检查冲突
class DeduplicationService {
  /// 创建去重服务实例
  factory DeduplicationService() => _instance;

  /// 私有构造函数，用于创建单例实例
  DeduplicationService._internal();

  /// 单例实例
  static final DeduplicationService _instance =
      DeduplicationService._internal();

  /// 获取去重服务实例
  static DeduplicationService get instance => _instance;

  /// 检查并准备剪贴项，确保去重逻辑统一
  Future<ClipItem?> checkAndPrepare(
    String contentHash,
    ClipItem newItem,
  ) async {
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
        RegExp(r'^[a-f0-9]{64}$').hasMatch(id);
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
        seenHashes.add(item.id);
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

  /// 检查并准备OCR文本项目
  ///
  /// [ocrText] OCR识别的文本内容
  /// [parentImageItem] 原图片项目
  ///
  /// 返回处理后的OCR文本项目，可能是现有的也可能是新的
  Future<ClipItem?> checkAndPrepareOcrText(
    String ocrText,
    ClipItem parentImageItem,
  ) async {
    try {
      if (ocrText.isEmpty || parentImageItem.type != ClipType.image) {
        await Log.w(
          'Invalid OCR text or parent image',
          tag: 'DeduplicationService',
          fields: {
            'ocrTextLength': ocrText.length,
            'parentType': parentImageItem.type.name,
          },
        );
        return null;
      }

      await Log.d(
        'Checking OCR text for duplication',
        tag: 'DeduplicationService',
        fields: {
          'parentImageId': parentImageItem.id,
          'ocrTextLength': ocrText.length,
        },
      );

      // 为OCR文本生成独立ID
      final ocrTextId = IdGenerator.generateOcrTextId(ocrText, parentImageItem.id);

      // 检查数据库中是否已存在相同的OCR文本
      final existing = await _checkDatabaseExists(ocrTextId);
      if (existing != null) {
        await Log.i(
          'Found existing OCR text, updating timestamp',
          tag: 'DeduplicationService',
          fields: {
            'existingId': existing.id,
            'parentImageId': parentImageItem.id,
          },
        );

        // 返回更新后的现有OCR文本项目
        return existing.copyWith(
          updatedAt: DateTime.now(),
          // 确保关联关系正确
          parentImageId: parentImageItem.id,
          isOcrExtracted: true,
          // 合并元数据，保留最新的信息
          metadata: {...existing.metadata, ...parentImageItem.metadata},
        );
      }

      // 创建新的OCR文本项目
      final ocrTextItem = ClipItem(
        id: ocrTextId,
        type: ClipType.text,
        content: ocrText,
        ocrText: ocrText,
        ocrTextId: ocrTextId,
        parentImageId: parentImageItem.id,
        isOcrExtracted: true,
        metadata: {
          ...parentImageItem.metadata,
          'source': 'ocr',
          'parentImageId': parentImageItem.id,
          'extractedAt': DateTime.now().toIso8601String(),
        },
      );

      await Log.i(
        'Created new OCR text item',
        tag: 'DeduplicationService',
        fields: {
          'ocrTextId': ocrTextId,
          'parentImageId': parentImageItem.id,
          'contentLength': ocrText.length,
        },
      );

      return ocrTextItem;
    } on Exception catch (e) {
      await Log.e(
        'Error during OCR text deduplication check',
        tag: 'DeduplicationService',
        error: e,
        fields: {
          'parentImageId': parentImageItem.id,
          'ocrTextLength': ocrText.length,
        },
      );
      return null;
    }
  }

  /// 处理图片及其OCR文本的去重
  ///
  /// [imageItem] 图片项目
  /// [ocrText] OCR识别的文本内容（可选）
  ///
  /// 返回处理后的项目列表：图片项目和可能的OCR文本项目
  Future<List<ClipItem>> processImageWithOcr(
    ClipItem imageItem,
    String? ocrText,
  ) async {
    final results = <ClipItem>[];

    try {
      // 处理图片项目的去重
      final processedImage = await checkAndPrepare(imageItem.id, imageItem);
      if (processedImage != null) {
        results.add(processedImage);
      }

      // 如果有OCR文本且启用了OCR，处理OCR文本的去重
      if (ocrText != null && ocrText.isNotEmpty) {
        final processedOcr = await checkAndPrepareOcrText(ocrText, imageItem);
        if (processedOcr != null) {
          results.add(processedOcr);

          // 更新图片项目的OCR状态
          if (processedImage != null) {
            final imageWithOcrStatus = processedImage.copyWith(
              ocrText: ocrText,
              isOcrExtracted: true,
              // 如果图片没有ocrTextId，设置OCR文本的ID
              ocrTextId: processedImage.ocrTextId ?? processedOcr.id,
            );

            // 替换结果中的图片项目
            results.removeWhere((item) => item.type == ClipType.image);
            results.add(imageWithOcrStatus);
          }
        }
      }

      await Log.i(
        'Image with OCR processing completed',
        tag: 'DeduplicationService',
        fields: {
          'imageId': imageItem.id,
          'hasOcrText': ocrText != null && ocrText.isNotEmpty,
          'resultCount': results.length,
        },
      );

      return results;
    } on Exception catch (e) {
      await Log.e(
        'Error during image with OCR processing',
        tag: 'DeduplicationService',
        error: e,
        fields: {
          'imageId': imageItem.id,
          'hasOcrText': ocrText != null && ocrText.isNotEmpty,
        },
      );

      // 发生错误时，至少返回图片项目
      if (results.isEmpty) {
        results.add(imageItem);
      }

      return results;
    }
  }

  /// 查找与指定图片关联的所有OCR文本项目
  ///
  /// [parentImageId] 父图片的ID
  ///
  /// 返回关联的OCR文本项目列表
  Future<List<ClipItem>> findRelatedOcrTexts(String parentImageId) async {
    try {
      await Log.d(
        'Finding OCR texts related to image',
        tag: 'DeduplicationService',
        fields: {
          'parentImageId': parentImageId,
        },
      );

      final databaseService = DatabaseService.instance;

      // 查询所有与该图片关联的OCR文本项目
      // 由于searchClipItems不支持filters参数，我们先搜索所有文本项目
      final allTextItems = await databaseService.searchClipItems(
        '',
        limit: 100,
      );

      // 过滤出与指定图片关联的OCR文本项目
      final relatedItems = allTextItems.where((item) =>
        item.parentImageId == parentImageId &&
        item.type == ClipType.text &&
        item.isOcrExtracted == true
      ).toList();

      await Log.i(
        'Found related OCR texts',
        tag: 'DeduplicationService',
        fields: {
          'parentImageId': parentImageId,
          'count': relatedItems.length,
        },
      );

      return relatedItems;
    } on Exception catch (e) {
      await Log.e(
        'Error finding related OCR texts',
        tag: 'DeduplicationService',
        error: e,
        fields: {
          'parentImageId': parentImageId,
        },
      );
      return [];
    }
  }

  /// 更新图片项目的OCR状态
  ///
  /// [imageId] 图片项目的ID
  /// [ocrText] OCR识别的文本内容
  /// [ocrTextId] OCR文本的独立ID
  ///
  /// 返回更新后的图片项目
  Future<ClipItem?> updateImageOcrStatus(
    String imageId,
    String ocrText,
    String ocrTextId,
  ) async {
    try {
      await Log.d(
        'Updating image OCR status',
        tag: 'DeduplicationService',
        fields: {
          'imageId': imageId,
          'ocrTextId': ocrTextId,
          'ocrTextLength': ocrText.length,
        },
      );

      final databaseService = DatabaseService.instance;
      final existingImage = await databaseService.getClipItemById(imageId);

      if (existingImage != null) {
        final updatedImage = existingImage.copyWith(
          ocrText: ocrText,
          ocrTextId: ocrTextId,
          isOcrExtracted: true,
          updatedAt: DateTime.now(),
        );

        // 保存更新后的图片项目
        await databaseService.updateClipItem(updatedImage);

        await Log.i(
          'Updated image OCR status successfully',
          tag: 'DeduplicationService',
          fields: {
            'imageId': imageId,
            'ocrTextId': ocrTextId,
          },
        );

        return updatedImage;
      } else {
        await Log.w(
          'Image not found for OCR status update',
          tag: 'DeduplicationService',
          fields: {
            'imageId': imageId,
          },
        );
        return null;
      }
    } on Exception catch (e) {
      await Log.e(
        'Error updating image OCR status',
        tag: 'DeduplicationService',
        error: e,
        fields: {
          'imageId': imageId,
          'ocrTextId': ocrTextId,
        },
      );
      return null;
    }
  }
}
