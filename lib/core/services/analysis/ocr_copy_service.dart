import 'dart:async';

import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/services/observability/index.dart';
import 'package:clip_flow/core/services/storage/index.dart';
import 'package:flutter/services.dart';

/// OCR复制服务
///
/// 提供OCR相关的复制功能，支持：
/// - 复制图片到剪贴板（不生成新记录）
/// - 复制OCR文本到剪贴板（不生成新记录）
/// - 静默复制模式，避免触发剪贴板监听
class OCRCopyService {
  /// 创建OCR复制服务实例
  factory OCRCopyService() => _instance;

  /// 私有构造函数
  OCRCopyService._internal();

  /// 单例实例
  static final OCRCopyService _instance = OCRCopyService._internal();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 检查平台支持
      await Log.d('Initializing OCR Copy Service', tag: 'OCRCopyService');

      _isInitialized = true;
      await Log.i(
        'OCR Copy Service initialized successfully',
        tag: 'OCRCopyService',
      );
    } on Exception catch (e) {
      await Log.e(
        'Failed to initialize OCR Copy Service',
        tag: 'OCRCopyService',
        error: e,
      );
      rethrow;
    }
  }

  /// 复制图片到剪贴板（静默模式）
  ///
  /// [imageItem] 图片剪贴项
  ///
  /// 注意：此操作不会生成新的剪贴板记录
  Future<bool> copyImageSilently(ClipItem imageItem) async {
    if (!_isInitialized) {
      throw StateError('OCR Copy Service not initialized');
    }

    if (imageItem.type != ClipType.image) {
      throw ArgumentError('Item must be of type image');
    }

    try {
      await Log.d(
        'Copying image silently',
        tag: 'OCRCopyService',
        fields: {
          'itemId': imageItem.id,
          'hasFilePath': imageItem.filePath != null,
          'hasThumbnail': imageItem.thumbnail != null,
        },
      );

      var success = false;

      // 优先使用文件路径复制
      if (imageItem.filePath != null && imageItem.filePath!.isNotEmpty) {
        success = await _copyImageFromFile(imageItem.filePath!);
      }
      // 如果没有文件路径，尝试使用缩略图
      else if (imageItem.thumbnail != null && imageItem.thumbnail!.isNotEmpty) {
        success = await _copyImageFromBytes(imageItem.thumbnail!);
      }

      if (success) {
        await Log.i(
          'Image copied silently to clipboard',
          tag: 'OCRCopyService',
          fields: {
            'itemId': imageItem.id,
          },
        );
        return true;
      } else {
        throw Exception('No valid image data available for copying');
      }
    } on Exception catch (e) {
      await Log.e(
        'Failed to copy image silently',
        tag: 'OCRCopyService',
        error: e,
      );
      return false;
    }
  }

  /// 复制OCR文本到剪贴板（静默模式）
  ///
  /// [imageItem] 包含OCR文本的图片剪贴项
  /// [format] OCR文本格式
  ///
  /// 注意：此操作不会生成新的剪贴板记录
  Future<bool> copyOcrTextSilently(
    ClipItem imageItem, {
    OCRTextFormat format = OCRTextFormat.plain,
  }) async {
    if (!_isInitialized) {
      throw StateError('OCR Copy Service not initialized');
    }

    if (imageItem.type != ClipType.image) {
      throw ArgumentError('Item must be of type image');
    }

    if (imageItem.ocrText == null || imageItem.ocrText!.isEmpty) {
      throw StateError('No OCR text available to copy');
    }

    try {
      await Log.d(
        'Copying OCR text silently',
        tag: 'OCRCopyService',
        fields: {
          'itemId': imageItem.id,
          'format': format.name,
          'textLength': imageItem.ocrText!.length,
        },
      );

      // 格式化OCR文本
      final formattedText = formatOcrText(imageItem.ocrText!, format);

      // 静默复制文本到剪贴板
      await Clipboard.setData(ClipboardData(text: formattedText));

      await Log.i(
        'OCR text copied silently to clipboard',
        tag: 'OCRCopyService',
        fields: {
          'itemId': imageItem.id,
          'format': format.name,
          'textLength': formattedText.length,
        },
      );

      return true;
    } on Exception catch (e) {
      await Log.e(
        'Failed to copy OCR text silently',
        tag: 'OCRCopyService',
        error: e,
      );
      return false;
    }
  }

  /// 从文件路径复制图片
  Future<bool> _copyImageFromFile(String filePath) async {
    try {
      const platform = MethodChannel('clipboard_service');

      // 使用PathService将路径转换为绝对路径
      final absolutePath = await PathService.instance.resolveAbsolutePath(
        filePath,
      );

      // 检查文件是否存在
      if (!await PathService.instance.fileExists(filePath)) {
        await Log.e(
          'Image file not found',
          tag: 'OCRCopyService',
          fields: {
            'path': absolutePath,
            'sourcePath': filePath,
          },
        );
        return false;
      }

      // 使用原生方法复制图片文件
      await platform.invokeMethod('setClipboardFile', {
        'filePath': absolutePath,
        'silent': true, // 标记为静默复制，避免触发监听
      });

      return true;
    } on Exception catch (e) {
      await Log.e(
        'Failed to copy image from file',
        tag: 'OCRCopyService',
        error: e,
      );
      return false;
    }
  }

  /// 从字节数据复制图片
  Future<bool> _copyImageFromBytes(List<int> imageBytes) async {
    try {
      const platform = MethodChannel('clipboard_service');

      // 将字节数据转换为Uint8List
      final uint8List = Uint8List.fromList(imageBytes);

      // 使用原生方法复制图片数据
      await platform.invokeMethod('setClipboardImageData', {
        'imageData': uint8List,
        'silent': true, // 标记为静默复制，避免触发监听
      });

      return true;
    } on Exception catch (e) {
      await Log.e(
        'Failed to copy image from bytes',
        tag: 'OCRCopyService',
        error: e,
      );
      return false;
    }
  }

  /// 格式化OCR文本
  String formatOcrText(String text, OCRTextFormat format) {
    switch (format) {
      case OCRTextFormat.plain:
        return text;

      case OCRTextFormat.formatted:
        // 保留换行和空格格式，去除首尾空白
        return text.trim();

      case OCRTextFormat.json:
        return _formatAsJson(text);

      case OCRTextFormat.markdown:
        return _formatAsMarkdown(text);
    }
  }

  /// 格式化为JSON
  String _formatAsJson(String text) {
    final escapedText = escapeJson(text);
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    return '''
{
  "text": "$escapedText",
  "timestamp": "${DateTime.now().toIso8601String()}",
  "source": "OCR",
  "wordCount": $wordCount
}''';
  }

  /// 格式化为Markdown
  String _formatAsMarkdown(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer()
      ..writeln('> **识别文本**')
      ..writeln('> ');

    for (final line in lines) {
      if (line.isNotEmpty) {
        buffer.writeln('> $line');
      } else {
        buffer.writeln('>');
      }
    }

    buffer
      ..writeln('> ')
      ..writeln('> *由 ClipFlow OCR 识别*');

    return buffer.toString();
  }

  /// JSON字符串转义
  String escapeJson(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
  }

  /// 检查图片是否可以复制
  Future<bool> canCopyImage(ClipItem imageItem) async {
    if (imageItem.type != ClipType.image) return false;

    // 检查是否有文件路径且文件存在
    if (imageItem.filePath != null && imageItem.filePath!.isNotEmpty) {
      return PathService.instance.fileExists(imageItem.filePath!);
    }

    // 检查是否有缩略图数据
    if (imageItem.thumbnail != null && imageItem.thumbnail!.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// 检查OCR文本是否可以复制
  bool canCopyOcrText(ClipItem imageItem) {
    return imageItem.type == ClipType.image &&
        imageItem.ocrText != null &&
        imageItem.ocrText!.isNotEmpty;
  }

  /// 获取复制支持状态
  Future<OCRCopySupportStatus> getCopySupportStatus(ClipItem imageItem) async {
    final canCopyImageData = await canCopyImage(imageItem);
    final canCopyOcrTextData = canCopyOcrText(imageItem);

    return OCRCopySupportStatus(
      canCopyImage: canCopyImageData,
      canCopyOcrText: canCopyOcrTextData,
      hasOcrText: canCopyOcrTextData,
      hasImageData: canCopyImageData,
    );
  }
}

/// OCR文本格式枚举
enum OCRTextFormat {
  /// 纯文本
  plain,

  /// 格式化文本（保留换行和空格）
  formatted,

  /// JSON格式
  json,

  /// Markdown格式
  markdown,
}

/// OCR复制支持状态
class OCRCopySupportStatus {
  /// 创建OCR复制支持状态
  const OCRCopySupportStatus({
    required this.canCopyImage,
    required this.canCopyOcrText,
    required this.hasOcrText,
    required this.hasImageData,
  });

  /// 是否可以复制图片
  final bool canCopyImage;

  /// 是否可以复制OCR文本
  final bool canCopyOcrText;

  /// 是否有OCR文本
  final bool hasOcrText;

  /// 是否有图片数据
  final bool hasImageData;

  /// 是否支持任何复制操作
  bool get canCopyAnything => canCopyImage || canCopyOcrText;

  /// 是否支持所有复制操作
  bool get canCopyBoth => canCopyImage && canCopyOcrText;

  @override
  String toString() {
    return 'OCRCopySupportStatus('
        'canCopyImage: $canCopyImage, '
        'canCopyOcrText: $canCopyOcrText, '
        'hasOcrText: $hasOcrText, '
        'hasImageData: $hasImageData)';
  }
}
