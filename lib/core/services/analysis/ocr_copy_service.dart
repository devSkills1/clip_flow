import 'dart:async';
import 'dart:collection';

import 'package:clip_flow_pro/core/models/ocr_enhanced_clip_item.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_ports.dart';
import 'package:clip_flow_pro/core/services/clipboard/clipboard_ports.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:uuid/uuid.dart';

/// OCR复制服务实现
/// 负责OCR相关的复制功能和历史记录管理
class OCRCopyService implements OCRCopyServicePort {
  /// 单例实例
  static final OCRCopyService _instance = OCRCopyService._internal();
  factory OCRCopyService() => _instance;
  OCRCopyService._internal();

  /// 剪贴板服务
  late ClipboardServicePort _clipboardService;

  /// 复制历史记录
  final Queue<OCRCopyRecord> _copyHistory = Queue();

  /// 历史记录最大数量
  static const int _maxHistorySize = 100;

  /// 是否已初始化
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _clipboardService = ClipboardService();

      // 加载历史记录
      await _loadHistory();

      _isInitialized = true;
      await Log.i('OCR Copy Service initialized');
    } on Exception catch (e) {
      await Log.e('Failed to initialize OCR Copy Service', error: e);
      rethrow;
    }
  }

  @override
  Future<void> copyImage(OCREnhancedClipItem item) async {
    if (!_isInitialized) {
      throw StateError('OCR Copy Service not initialized');
    }

    try {
      await Log.d('Copying image', tag: 'OCRCopyService', fields: {
        'itemId': item.imageItem.id,
      });

      // 从文件或缩略图复制图片
      if (item.imageItem.filePath != null) {
        await _clipboardService.copyImageFromFile(item.imageItem.filePath!);
      } else if (item.imageItem.thumbnail != null) {
        await _clipboardService.copyImageData(item.imageItem.thumbnail!);
      } else {
        throw Exception('No image data available to copy');
      }

      // 记录复制历史
      _addToHistory(
        OCRCopyRecord(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          copyType: OCRCopyType.image,
          sourceItemId: item.imageItem.id,
          contentSummary: 'Image (${item.imageItem.type.name})',
        ),
      );

      await Log.i('Image copied successfully', tag: 'OCRCopyService');
    } on Exception catch (e) {
      await Log.e('Failed to copy image', tag: 'OCRCopyService', error: e);

      // 记录失败
      _addToHistory(
        OCRCopyRecord(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          copyType: OCRCopyType.image,
          sourceItemId: item.imageItem.id,
          contentSummary: 'Image copy failed',
          success: false,
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  @override
  Future<void> copyOCRText(
    OCREnhancedClipItem item, {
    OCRTextFormat format = OCRTextFormat.plain,
  }) async {
    if (!_isInitialized) {
      throw StateError('OCR Copy Service not initialized');
    }

    if (!item.hasOCR) {
      throw StateError('No OCR text available to copy');
    }

    try {
      await Log.d('Copying OCR text', tag: 'OCRCopyService', fields: {
        'itemId': item.imageItem.id,
        'format': format.name,
      });

      // 格式化文本
      final formattedText = _formatOCRText(item.ocrText!, format);

      // 复制到剪贴板
      await _clipboardService.copyText(formattedText);

      // 记录复制历史
      _addToHistory(
        OCRCopyRecord(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          copyType: OCRCopyType.text,
          sourceItemId: item.imageItem.id,
          contentSummary: _generateTextSummary(formattedText),
        ),
      );

      await Log.i('OCR text copied successfully', tag: 'OCRCopyService', fields: {
        'textLength': formattedText.length,
        'format': format.name,
      });
    } on Exception catch (e) {
      await Log.e('Failed to copy OCR text', tag: 'OCRCopyService', error: e);

      // 记录失败
      _addToHistory(
        OCRCopyRecord(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          copyType: OCRCopyType.text,
          sourceItemId: item.imageItem.id,
          contentSummary: 'OCR text copy failed',
          success: false,
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  @override
  Future<void> smartCopy(
    OCREnhancedClipItem item, {
    OCRCopyType type = OCRCopyType.both,
  }) async {
    switch (type) {
      case OCRCopyType.image:
        await copyImage(item);
        break;

      case OCRCopyType.text:
        await copyOCRText(item);
        break;

      case OCRCopyType.both:
        try {
          // 先复制图片
          await copyImage(item);

          // 延迟一秒后复制文本
          Timer(const Duration(seconds: 1), () async {
            try {
              await copyOCRText(item);
            } on Exception catch (e) {
              await Log.e('Failed to copy OCR text in smart copy', error: e);
            }
          });

          await Log.i('Smart copy initiated (image + text)');
        } on Exception catch (e) {
          await Log.e('Failed to copy image in smart copy', error: e);
          // 尝试只复制文本
          if (item.hasOCR) {
            await copyOCRText(item);
          }
        }
        break;
    }
  }

  @override
  Future<List<OCRCopyRecord>> getCopyHistory({int limit = 10}) async {
    final history = _copyHistory.toList();
    return history.take(limit).toList();
  }

  @override
  Future<void> clearCopyHistory() async {
    _copyHistory.clear();
    await Log.i('Copy history cleared');
  }

  /// 私有方法

  /// 格式化OCR文本
  String _formatOCRText(String text, OCRTextFormat format) {
    switch (format) {
      case OCRTextFormat.plain:
        return text;

      case OCRTextFormat.formatted:
        // 保留换行和空格格式
        return text.trim();

      case OCRTextFormat.json:
        return _formatAsJSON(text);

      case OCRTextFormat.markdown:
        return _formatAsMarkdown(text);
    }
  }

  /// 格式化为JSON
  String _formatAsJSON(String text) {
    return '''
{
  "text": ${_escapeJson(text)},
  "timestamp": "${DateTime.now().toIso8601String()}",
  "source": "OCR",
  "wordCount": ${text.split(RegExp(r'\s+')).length}
}''';
  }

  /// 格式化为Markdown
  String _formatAsMarkdown(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();

    buffer.writeln('> **识别文本**');
    buffer.writeln('> ');

    for (final line in lines) {
      if (line.isNotEmpty) {
        buffer.writeln('> $line');
      } else {
        buffer.writeln('>');
      }
    }

    buffer.writeln('> ');
    buffer.writeln('> *由 ClipFlow Pro OCR 识别*');

    return buffer.toString();
  }

  /// JSON转义
  String _escapeJson(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// 生成文本摘要
  String _generateTextSummary(String text) {
    final words = text.split(RegExp(r'\s+'));
    final summary = words.take(5).join(' ');

    if (words.length > 5) {
      return '$summary... (${words.length} words)';
    }

    return summary;
  }

  /// 添加到历史记录
  void _addToHistory(OCRCopyRecord record) {
    _copyHistory.addFirst(record);

    // 限制历史记录大小
    while (_copyHistory.length > _maxHistorySize) {
      _copyHistory.removeLast();
    }

    // 保存到持久化存储（可选）
    _saveHistory();
  }

  /// 加载历史记录
  Future<void> _loadHistory() async {
    // TODO: 从持久化存储加载历史记录
    // 这里可以使用SharedPreferences或数据库
  }

  /// 保存历史记录
  Future<void> _saveHistory() async {
    // TODO: 保存历史记录到持久化存储
  }
}