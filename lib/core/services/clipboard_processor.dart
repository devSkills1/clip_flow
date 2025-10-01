import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard_detector.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:clip_flow_pro/core/services/ocr_service.dart';
import 'package:clip_flow_pro/core/services/preferences_service.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:clip_flow_pro/core/utils/image_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 剪贴板内容处理器
///
/// 负责处理和转换剪贴板内容，包括：
/// - 内容缓存和去重
/// - 元数据提取
/// - 文件保存和管理
/// - 图片处理和缩略图生成
/// - 富文本内容处理
class ClipboardProcessor {
  static const MethodChannel _platformChannel = MethodChannel(
    'clipboard_service',
  );

  final ClipboardDetector _detector = ClipboardDetector();

  // 缓存配置
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxContentLength = 1024 * 1024; // 1MB
  static const int _maxMemoryUsage = 50 * 1024 * 1024; // 50MB

  // 内容缓存
  final Map<String, _CacheEntry> _contentCache = {};
  final Map<String, DateTime> _hashTimestamps = {};

  // 性能监控
  int _currentMemoryUsage = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  DateTime? _lastCleanup;

  /// 处理剪贴板内容并创建 ClipItem
  Future<ClipItem?> processClipboardContent() async {
    try {
      // 获取原生剪贴板数据
      final nativeData = await _getNativeClipboardData();
      if (nativeData == null) return null;

      // 检查缓存
      final contentHash = _calculateContentHash(nativeData);
      if (_isCached(contentHash)) {
        return null; // 内容未变化
      }

      // 处理不同类型的内容
      ClipItem? item;

      if (nativeData.containsKey('image')) {
        item = await _processImageContent(nativeData, contentHash);
      } else if (nativeData.containsKey('files')) {
        item = await _processFileContent(nativeData, contentHash);
      } else if (nativeData.containsKey('rtf')) {
        item = await _processRichTextContent(nativeData, contentHash);
      } else if (nativeData.containsKey('html')) {
        item = await _processHtmlContent(nativeData, contentHash);
      } else if (nativeData.containsKey('text')) {
        item = await _processTextContent(nativeData, contentHash);
      }

      if (item != null) {
        _updateCache(contentHash, item);
      }

      return item;
    } on Exception catch (_) {
      return null;
    }
  }

  /// 获取原生剪贴板数据
  Future<Map<String, dynamic>?> _getNativeClipboardData() async {
    try {
      // 使用现有的平台方法获取剪贴板类型和数据
      final typeResult = await _platformChannel
          .invokeMethod<Map<Object?, Object?>>('getClipboardType');
      if (typeResult == null) return null;

      final typeData = typeResult.cast<String, dynamic>();
      final clipboardType = typeData['type'] as String?;

      if (clipboardType == null) return null;

      // 根据类型获取相应的数据
      final result = <String, dynamic>{'type': clipboardType};

      switch (clipboardType) {
        case 'image':
          final imageData = await _platformChannel.invokeMethod<Uint8List>(
            'getClipboardImageData',
          );
          if (imageData != null) {
            result['image'] = imageData;
          }

        case 'file':
          final filePaths = await _platformChannel.invokeMethod<List<dynamic>>(
            'getClipboardFilePaths',
          );
          if (filePaths != null && filePaths.isNotEmpty) {
            result['files'] = filePaths;
          }

        case 'rtf':
          final rtfData = await _platformChannel
              .invokeMethod<Map<Object?, Object?>>('getRichTextData');
          if (rtfData != null) {
            final rtfMap = rtfData.cast<String, dynamic>();
            result['rtf'] = rtfMap['rtf'];
            if (rtfMap.containsKey('text')) {
              result['text'] = rtfMap['text'];
            }
          }

        case 'html':
          // HTML 内容通过 typeData 中的 content 字段获取
          if (typeData.containsKey('content')) {
            result['html'] = typeData['content'];
          }

        default:
          // 对于文本类型，使用 Flutter 的 Clipboard API
          final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
          if (clipboardData?.text != null) {
            result['text'] = clipboardData!.text;
          }
      }

      return result;
    } on Exception catch (_) {
      return null;
    }
  }

  /// 处理图片内容
  Future<ClipItem?> _processImageContent(
    Map<String, dynamic> data,
    String contentHash,
  ) async {
    try {
      final imageBytes = data['image'] as Uint8List?;
      if (imageBytes == null || imageBytes.isEmpty) return null;

      // 限制图片大小
      if (imageBytes.length > _maxContentLength) {
        return null;
      }

      // 保存图片到磁盘
      final extension = _inferImageExtension(imageBytes);
      final relativePath = await _saveMediaToDisk(
        bytes: imageBytes,
        type: 'image',
        suggestedExt: extension,
      );

      if (relativePath.isEmpty) return null;

      // 生成缩略图
      final thumbnail = await _generateThumbnail(imageBytes);

      // 提取元数据
      final metadata = await _extractImageMetadata(imageBytes);

      // OCR文字识别
      String? ocrText;
      await Log.i(
        'Starting OCR processing for image',
        tag: 'ClipboardProcessor',
        fields: {
          'imageSize': imageBytes.length,
          'contentHash': contentHash,
        },
      );

      try {
        // 加载用户偏好以获取 OCR 语言与置信度阈值
        final prefs = await PreferencesService().loadPreferences();

        // 如果未启用OCR，跳过识别
        if (!prefs.enableOCR) {
          await Log.d(
            'OCR disabled by user preferences',
            tag: 'ClipboardProcessor',
          );
        } else {
          final ocrService = OcrServiceFactory.getInstance();
          final ocrResult = await ocrService.recognizeText(
            imageBytes,
            language: prefs.ocrLanguage,
            minConfidence: prefs.ocrMinConfidence,
          );

          if (ocrResult != null && ocrResult.text.isNotEmpty) {
            ocrText = ocrResult.text;
            // 将OCR置信度添加到元数据中
            metadata['ocrConfidence'] = ocrResult.confidence;

            await Log.i(
              'OCR processing completed successfully',
              tag: 'ClipboardProcessor',
              fields: {
                'textLength': ocrText.length,
                'confidence': ocrResult.confidence,
                'contentHash': contentHash,
              },
            );
          } else {
            await Log.w(
              'OCR processing returned no text',
              tag: 'ClipboardProcessor',
              fields: {
                'contentHash': contentHash,
                'resultNull': ocrResult == null,
                'textEmpty': ocrResult?.text.isEmpty ?? true,
              },
            );
          }
        }
      } on Exception catch (e) {
        // OCR失败不影响图片保存
        metadata['ocrError'] = e.toString();

        await Log.e(
          'OCR processing failed',
          tag: 'ClipboardProcessor',
          error: e,
          fields: {
            'contentHash': contentHash,
            'imageSize': imageBytes.length,
          },
        );
      }

      return ClipItem(
        type: ClipType.image,
        content: '', // 图片内容为空
        filePath: relativePath,
        thumbnail: thumbnail,
        metadata: metadata,
        ocrText: ocrText,
        id: contentHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 处理文件内容
  Future<ClipItem?> _processFileContent(
    Map<String, dynamic> data,
    String contentHash,
  ) async {
    try {
      final files = data['files'] as List<dynamic>?;
      if (files == null || files.isEmpty) return null;

      final filePath = files.first as String;
      final file = File(filePath);

      if (!file.existsSync()) return null;

      // 检测文件类型
      final fileType = _detector.detectFileType(filePath);

      // 保存到应用沙盒（统一管理文件），并保留原始扩展名与原始文件名
      String? relativePath;
      try {
        final bytes = await file.readAsBytes();
        final ext = file.path.split('.').length > 1
            ? file.path.split('.').last.toLowerCase()
            : null;

        // 获取原始文件名（不包含路径）
        final originalFileName = file.path.split('/').last;

        relativePath = await _saveMediaToDisk(
          bytes: bytes,
          type: 'file',
          suggestedExt: ext,
          // 传入原始文件名，保留原始名称
          originalName: originalFileName,
          keepOriginalName: true,
        );
      } on Exception catch (_) {
        // 如果保存失败，继续使用原始路径，但这可能导致沙盒不可见
      }

      // 提取元数据（补充文件名与原始路径）
      final metadata = await _extractFileMetadata(file, fileType);
      final fileName = file.path.split('/').last;
      metadata['fileName'] = fileName;
      metadata['originalPath'] = file.path;

      // 处理图片文件的缩略图
      List<int>? thumbnail;
      if (fileType == ClipType.image) {
        // 优先使用保存后的文件生成缩略图
        try {
          if (relativePath != null && relativePath.isNotEmpty) {
            final documentsDirectory = await getApplicationDocumentsDirectory();
            final savedFile = File('${documentsDirectory.path}/$relativePath');
            if (savedFile.existsSync()) {
              thumbnail = await _generateFileThumbnail(savedFile);
            } else {
              thumbnail = await _generateFileThumbnail(file);
            }
          } else {
            thumbnail = await _generateFileThumbnail(file);
          }
        } on Exception catch (_) {
          // 缩略图生成失败不影响创建条目
        }
      }

      return ClipItem(
        type: fileType,
        content: '',
        filePath: (relativePath != null && relativePath.isNotEmpty)
            ? relativePath
            : filePath,
        thumbnail: thumbnail,
        metadata: metadata,
        id: contentHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 处理富文本内容
  Future<ClipItem?> _processRichTextContent(
    Map<String, dynamic> data,
    String contentHash,
  ) async {
    try {
      final rtfContent = data['rtf'] as String?;
      final plainText = data['text'] as String?;

      if (rtfContent == null || rtfContent.isEmpty) return null;

      // 检查是否为代码内容
      if (plainText != null &&
          _detector.detectContentType(plainText) == ClipType.code) {
        return _processCodeContent(plainText, contentHash);
      }

      // 提取元数据
      final metadata = await _extractTextMetadata(rtfContent, ClipType.rtf);

      return ClipItem(
        type: ClipType.rtf,
        content: rtfContent,
        metadata: metadata,
        id: contentHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 处理 HTML 内容
  Future<ClipItem?> _processHtmlContent(
    Map<String, dynamic> data,
    String contentHash,
  ) async {
    try {
      final htmlContent = data['html'] as String?;
      final plainText = data['text'] as String?;

      if (htmlContent == null || htmlContent.isEmpty) return null;

      // 检查是否为代码内容
      if (plainText != null &&
          _detector.detectContentType(plainText) == ClipType.code) {
        return _processCodeContent(plainText, contentHash);
      }

      // 提取元数据
      final metadata = await _extractTextMetadata(htmlContent, ClipType.html);

      return ClipItem(
        type: ClipType.html,
        content: htmlContent,
        metadata: metadata,
        id: contentHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 处理文本内容
  Future<ClipItem?> _processTextContent(
    Map<String, dynamic> data,
    String contentHash,
  ) async {
    try {
      final textContent = data['text'] as String?;
      if (textContent == null || textContent.isEmpty) return null;

      // 限制文本长度
      if (textContent.length > _maxContentLength) {
        return null;
      }

      // 检测内容类型
      final contentType = _detector.detectContentType(textContent);

      // 根据类型处理
      switch (contentType) {
        case ClipType.code:
          return _processCodeContent(textContent, contentHash);
        case ClipType.color:
        case ClipType.url:
        case ClipType.email:
        case ClipType.json:
        case ClipType.xml:
          return _processSpecialTextContent(
            textContent,
            contentType,
            contentHash,
          );
        case ClipType.text:
        case ClipType.rtf:
        case ClipType.html:
        case ClipType.image:
        case ClipType.file:
        case ClipType.audio:
        case ClipType.video:
          return _processPlainTextContent(textContent, contentHash);
      }
    } on Exception catch (_) {
      return null;
    }
  }

  /// 处理代码内容
  Future<ClipItem> _processCodeContent(
    String content,
    String contentHash,
  ) async {
    final language = _detector.estimateLanguage(content);
    final metadata = await _extractTextMetadata(content, ClipType.code);
    metadata['language'] = language;

    return ClipItem(
      type: ClipType.code,
      content: content,
      metadata: metadata,
      id: contentHash,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 处理特殊文本内容（颜色、URL等）
  Future<ClipItem> _processSpecialTextContent(
    String content,
    ClipType type,
    String contentHash,
  ) async {
    final metadata = await _extractTextMetadata(content, type);

    // 为颜色类型添加特殊元数据
    if (type == ClipType.color) {
      metadata.addAll(_extractColorMetadata(content));
    }

    return ClipItem(
      type: type,
      content: content,
      metadata: metadata,
      id: contentHash,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 处理纯文本内容
  Future<ClipItem> _processPlainTextContent(
    String content,
    String contentHash,
  ) async {
    final metadata = await _extractTextMetadata(content, ClipType.text);

    return ClipItem(
      type: ClipType.text,
      content: content,
      metadata: metadata,
      id: contentHash,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 计算内容哈希
  String _calculateContentHash(Map<String, dynamic> data) {
    final content = json.encode(data);
    return sha256.convert(utf8.encode(content)).toString().substring(0, 16);
  }

  /// 检查是否已缓存（优化版本）
  bool _isCached(String contentHash) {
    final entry = _contentCache[contentHash];
    if (entry == null) {
      _cacheMisses++;
      return false;
    }

    // 检查是否过期
    final now = DateTime.now();
    if (now.difference(entry.timestamp) > _cacheExpiry) {
      _contentCache.remove(contentHash);
      _hashTimestamps.remove(contentHash);
      _updateMemoryUsage();
      _cacheMisses++;
      return false;
    }

    _cacheHits++;
    return true;
  }

  /// 更新缓存（优化版本）
  void _updateCache(String contentHash, ClipItem item) {
    final now = DateTime.now();

    // 检查内存使用情况
    if (_currentMemoryUsage > _maxMemoryUsage) {
      _performSmartCleanup();
    }

    // 如果缓存已满，移除最旧的条目
    if (_contentCache.length >= _maxCacheSize) {
      _removeOldestEntry();
    }

    final entry = _CacheEntry(item, now);
    _contentCache[contentHash] = entry;
    _hashTimestamps[contentHash] = now;
    _updateMemoryUsage();
  }

  /// 智能缓存清理
  void _performSmartCleanup() {
    final now = DateTime.now();

    // 按访问时间和大小排序，优先清理大文件和旧文件
    final entries = _contentCache.entries.toList()
      ..sort((a, b) {
        final ageA = now.difference(a.value.timestamp).inMinutes;
        final ageB = now.difference(b.value.timestamp).inMinutes;
        final sizeA = _estimateItemSize(a.value.item);
        final sizeB = _estimateItemSize(b.value.item);

        // 综合考虑年龄和大小
        final scoreA = ageA * 0.7 + sizeA * 0.3;
        final scoreB = ageB * 0.7 + sizeB * 0.3;

        return scoreB.compareTo(scoreA);
      });

    // 清理一半的缓存
    final toRemove = entries.take(entries.length ~/ 2);
    for (final entry in toRemove) {
      _contentCache.remove(entry.key);
      _hashTimestamps.remove(entry.key);
    }

    _updateMemoryUsage();
    _lastCleanup = now;
  }

  /// 移除最旧的缓存条目
  void _removeOldestEntry() {
    if (_contentCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _hashTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _contentCache.remove(oldestKey);
      _hashTimestamps.remove(oldestKey);
      _updateMemoryUsage();
    }
  }

  /// 估算条目大小
  int _estimateItemSize(ClipItem item) {
    var size = 0;

    // 内容大小
    if (item.content != null) {
      size += item.content!.length * 2; // UTF-16 编码
    }

    // 缩略图大小
    if (item.thumbnail != null) {
      size += item.thumbnail!.length;
    }

    // 元数据大小
    return size + item.metadata.toString().length * 2;
  }

  /// 更新内存使用统计
  void _updateMemoryUsage() {
    _currentMemoryUsage = 0;
    for (final entry in _contentCache.values) {
      _currentMemoryUsage += _estimateItemSize(entry.item);
    }
  }

  /// 生成缩略图
  Future<List<int>?> _generateThumbnail(Uint8List imageBytes) async {
    try {
      return await ImageUtils.generateThumbnail(
        imageBytes,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 生成文件缩略图
  Future<List<int>?> _generateFileThumbnail(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await ImageUtils.generateThumbnail(
        bytes,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 推断图片扩展名
  String _inferImageExtension(Uint8List imageBytes) {
    try {
      final info = ImageUtils.getImageInfo(imageBytes);
      final format = (info['format'] as String?)?.toLowerCase() ?? 'unknown';
      switch (format) {
        case 'jpeg':
          return 'jpg';
        case 'png':
          return 'png';
        case 'gif':
          return 'gif';
        case 'bmp':
          return 'bmp';
        case 'webp':
          return 'webp';
        default:
          return 'png';
      }
    } on Exception catch (_) {
      return 'png';
    }
  }

  /// 保存媒体文件到磁盘
  Future<String> _saveMediaToDisk({
    required Uint8List bytes,
    required String type,
    String? suggestedExt,
    String? originalName,
    bool keepOriginalName = false,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // 计算扩展名：优先使用建议扩展名，其次取原始文件名的扩展名
      String ext;
      if (suggestedExt != null && suggestedExt.isNotEmpty) {
        ext = suggestedExt.toLowerCase();
      } else if (originalName != null && originalName.contains('.')) {
        ext = originalName.split('.').last.toLowerCase();
      } else {
        ext = 'bin';
      }

      // 计算文件名哈希（用于去重/避免冲突）
      final hash = sha256.convert(bytes).toString().substring(0, 8);

      // 原始名称清理：去除非法字符，限制长度，支持中文文件名
      String sanitizedBase(String name) {
        // 去除路径分隔符，仅保留文件名部分
        final base = name.split('/').last.split(r'\').last;
        // 去掉扩展名
        final dotIndex = base.lastIndexOf('.');
        final withoutExt = dotIndex > 0 ? base.substring(0, dotIndex) : base;

        // 保留中文字符、字母数字、空格、横杠和下划线，其它替换为下划线
        // 支持中文字符范围：\u4e00-\u9fff
        final replaced = withoutExt.replaceAll(
          RegExp('[^A-Za-z0-9\u4e00-\u9fff _.-]'),
          '_',
        );

        // 将连续空格和下划线压缩
        final compact = replaced
            .replaceAll(RegExp(r'\s+'), '_') // 空格转下划线
            .replaceAll(RegExp('_+'), '_') // 连续下划线压缩
            .replaceAll(RegExp(r'^_+|_+$'), ''); // 去除首尾下划线

        // 如果清理后为空，使用默认名称
        if (compact.isEmpty) {
          return 'file';
        }

        // 限制长度，避免超长文件名，优先保留前面的字符
        return compact.length > 60 ? compact.substring(0, 60) : compact;
      }

      String fileName;
      if (keepOriginalName && originalName != null && originalName.isNotEmpty) {
        final base = sanitizedBase(originalName);
        // 使用更简洁的格式：原始名_哈希.扩展名
        // 哈希已经足够唯一，无需时间戳
        fileName = '${base}_$hash.$ext';
      } else {
        // 保持原有命名策略：type_时间戳_哈希.扩展名
        fileName = '${type}_${ts}_$hash.$ext';
      }

      final relativeDir = type == 'image' ? 'media/images' : 'media/files';
      final absoluteDir = '${dir.path}/$relativeDir';
      final absolutePath = '$absoluteDir/$fileName';
      final relativePath = '$relativeDir/$fileName';

      final d = Directory(absoluteDir);
      if (!d.existsSync()) {
        await d.create(recursive: true);
      }

      final f = File(absolutePath);
      await f.writeAsBytes(bytes, flush: true);

      return relativePath;
    } on Exception catch (_) {
      return '';
    }
  }

  /// 提取图片元数据
  Future<Map<String, dynamic>> _extractImageMetadata(
    Uint8List imageBytes,
  ) async {
    final metadata = <String, dynamic>{
      'contentLength': imageBytes.length,
      'sourceApp': await _getSourceApp(),
    };

    try {
      final imageInfo = ImageUtils.getImageInfo(imageBytes);
      metadata.addAll(imageInfo);
    } on Exception catch (_) {
      metadata['imageFormat'] = 'unknown';
      metadata['width'] = 0;
      metadata['height'] = 0;
    }

    return metadata;
  }

  /// 提取文件元数据
  Future<Map<String, dynamic>> _extractFileMetadata(
    File file,
    ClipType type,
  ) async {
    final stat = file.statSync();

    return {
      'contentLength': stat.size,
      'sourceApp': await _getSourceApp(),
      'fileSize': stat.size,
      'lastModified': stat.modified.toIso8601String(),
      'fileType': type.toString(),
    };
  }

  /// 提取文本元数据
  Future<Map<String, dynamic>> _extractTextMetadata(
    String content,
    ClipType type,
  ) async {
    return {
      'contentLength': content.length,
      'sourceApp': await _getSourceApp(),
      'wordCount': _calculateWordCount(content),
      'lineCount': content.split('\n').length,
    };
  }

  /// 提取颜色元数据
  Map<String, dynamic> _extractColorMetadata(String colorValue) {
    final metadata = <String, dynamic>{};

    final trimmed = colorValue.trim();

    // Hex 颜色：统一规范到 #RRGGBB
    if (trimmed.startsWith('#')) {
      metadata['colorFormat'] = 'hex';
      metadata['colorValue'] = trimmed;

      try {
        final rgb = ColorUtils.hexToRgb(trimmed);
        metadata['colorHex'] = ColorUtils.rgbToHex(
          rgb['r']!,
          rgb['g']!,
          rgb['b']!,
        );
      } on Exception catch (_) {
        // 无法解析则不写入 colorHex
      }
    }
    // RGB 或 RGBA：解析数值并转换为 #RRGGBB（忽略透明度）
    else if (trimmed.startsWith('rgb')) {
      final isRgba = trimmed.startsWith('rgba');
      metadata['colorFormat'] = isRgba ? 'rgba' : 'rgb';
      metadata['colorValue'] = trimmed;

      final match = RegExp(
        r'rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*([\d.]+))?\s*\)',
      ).firstMatch(trimmed);
      if (match != null) {
        final r = int.parse(match.group(1)!).clamp(0, 255);
        final g = int.parse(match.group(2)!).clamp(0, 255);
        final b = int.parse(match.group(3)!).clamp(0, 255);
        metadata['colorHex'] = ColorUtils.rgbToHex(r, g, b);
      }
    }
    // HSL 或 HSLA：解析数值并转换为 #RRGGBB（忽略透明度）
    else if (trimmed.startsWith('hsl')) {
      final isHsla = trimmed.startsWith('hsla');
      metadata['colorFormat'] = isHsla ? 'hsla' : 'hsl';
      metadata['colorValue'] = trimmed;

      final match = RegExp(
        r'hsla?\(\s*(\d{1,3})\s*,\s*(\d{1,3})%\s*,\s*(\d{1,3})%(?:\s*,\s*([\d.]+))?\s*\)',
      ).firstMatch(trimmed);
      if (match != null) {
        final h = double.parse(match.group(1)!);
        final s = double.parse(match.group(2)!);
        final l = double.parse(match.group(3)!);
        try {
          final rgb = ColorUtils.hslToRgb(h, s, l);
          metadata['colorHex'] = ColorUtils.rgbToHex(
            rgb['r']!,
            rgb['g']!,
            rgb['b']!,
          );
        } on Exception catch (_) {
          // 解析失败则不写入 colorHex
        }
      }
    }

    return metadata;
  }

  /// 获取源应用
  Future<String?> _getSourceApp() async {
    try {
      return await _platformChannel.invokeMethod<String>('getSourceApp');
    } on Exception catch (_) {
      return null;
    }
  }

  /// 计算单词数
  int _calculateWordCount(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// 清理缓存
  void clearCache() {
    _contentCache.clear();
    _hashTimestamps.clear();
    _currentMemoryUsage = 0;
    _cacheHits = 0;
    _cacheMisses = 0;
    _lastCleanup = null;
  }

  /// 获取缓存统计（增强版本）
  Map<String, dynamic> getCacheStats() {
    final hitRate = _cacheHits + _cacheMisses > 0
        ? _cacheHits / (_cacheHits + _cacheMisses)
        : 0.0;

    return {
      'cacheSize': _contentCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheExpiry': _cacheExpiry.inHours,
      'memoryUsage': _currentMemoryUsage,
      'maxMemoryUsage': _maxMemoryUsage,
      'memoryUsagePercent': (_currentMemoryUsage / _maxMemoryUsage * 100)
          .toStringAsFixed(1),
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': (hitRate * 100).toStringAsFixed(1),
      'lastCleanup': _lastCleanup?.toIso8601String(),
    };
  }

  /// 获取性能指标
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cacheEfficiency': getCacheStats(),
      'memoryOptimization': {
        'smartCleanupEnabled': true,
        'adaptiveCaching': true,
        'memoryThreshold': _maxMemoryUsage,
      },
    };
  }
}

/// 缓存条目
class _CacheEntry {
  _CacheEntry(this.item, this.timestamp);
  final ClipItem item;
  final DateTime timestamp;
}
