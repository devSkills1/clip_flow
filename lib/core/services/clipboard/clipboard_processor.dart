import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard/index.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/core/utils/image_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' as flutter;

/// 剪贴板内容处理器
///
/// 负责处理和转换剪贴板内容，包括：
/// - 内容缓存和去重
/// - 元数据提取
/// - 文件保存和管理
/// - 图片处理和缩略图生成
/// - 富文本内容处理
class ClipboardProcessor {
  static const flutter.MethodChannel _platformChannel = flutter.MethodChannel(
    'clipboard_service',
  );

  final ClipboardDetector _detector = ClipboardDetector();
  final UniversalClipboardDetector _universalDetector =
      UniversalClipboardDetector();

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
      final clipboardData = await _getNativeClipboardData();
      if (clipboardData == null) return null;

      // 检查缓存
      final contentHash = _calculateContentHash(clipboardData);
      if (_isCached(contentHash)) {
        return null; // 内容未变化
      }

      // 使用通用检测器检测内容类型
      final detectionResult = await _universalDetector.detect(clipboardData);

      // 创建 ClipItem
      final item = detectionResult.createClipItem(id: contentHash);

      // 特殊处理某些类型的内容
      ClipItem? processedItem;
      switch (detectionResult.detectedType) {
        case ClipType.image:
          processedItem = await _processImageData(detectionResult, contentHash);
        case ClipType.file:
        case ClipType.audio:
        case ClipType.video:
          processedItem = await _processFileData(detectionResult, contentHash);
        case ClipType.text:
        case ClipType.code:
        case ClipType.color:
        case ClipType.url:
        case ClipType.email:
        case ClipType.json:
        case ClipType.xml:
        case ClipType.html:
        case ClipType.rtf:
          processedItem = item;
      }

      if (processedItem != null) {
        _updateCache(contentHash, processedItem);
      }

      return processedItem;
    } on Exception catch (e) {
      await Log.e(
        'Failed to process clipboard content',
        tag: 'ClipboardProcessor',
        error: e,
      );
      return null;
    }
  }

  /// 获取原生剪贴板数据
  Future<ClipboardData?> _getNativeClipboardData() async {
    try {
      // 初始化通用检测器
      _universalDetector.initialize();

      // 使用新的平台方法获取所有格式的剪贴板数据
      final formatsResult = await _platformChannel
          .invokeMethod<Map<Object?, Object?>>('getClipboardFormats');
      if (formatsResult == null) return null;

      final formatsData = formatsResult.cast<String, dynamic>();

      // 创建 ClipboardData 对象
      final sequence =
          formatsData['sequence'] as int? ??
          DateTime.now().millisecondsSinceEpoch;

      // 处理时间戳 - macOS 返回的是 double 类型（秒数），需要转换为 int（毫秒数）
      int timestamp;
      final timestampValue = formatsData['timestamp'];
      if (timestampValue is num) {
        timestamp = timestampValue is double
            ? (timestampValue * 1000).round()
            : timestampValue.toInt();
      } else {
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }
      final formats = <ClipboardFormat, dynamic>{};

      // 先处理嵌套的 formats 字段（macOS 特有）
      if (formatsData.containsKey('formats') && formatsData['formats'] is Map) {
        final nestedFormats = formatsData['formats'] as Map<Object?, Object?>;

        // 解析嵌套格式中的文件
        if (nestedFormats.containsKey('files') &&
            nestedFormats['files'] != null) {
          final filesData = nestedFormats['files'] as List<dynamic>?;
          if (filesData != null && filesData.isNotEmpty) {
            formats[ClipboardFormat.files] = filesData.cast<String>();
            await Log.i(
              'Found files in nested formats',
              tag: 'ClipboardProcessor',
              fields: {
                'fileCount': filesData.length,
                'files': filesData.take(3).toList(), // 只记录前3个文件路径
              },
            );
          }
        }

        // 解析嵌套格式中的图片
        if (nestedFormats.containsKey('image') &&
            nestedFormats['image'] != null) {
          final imageData = nestedFormats['image'];
          await Log.i(
            'Checking nested image data',
            tag: 'ClipboardProcessor',
            fields: {
              'imageDataType': imageData.runtimeType.toString(),
              'imageDataIsNull': imageData == null,
              'imageDataLength': imageData is List ? imageData.length : 'N/A',
              'isUint8List': imageData is Uint8List,
            },
          );
          if (imageData is Uint8List && imageData.isNotEmpty) {
            formats[ClipboardFormat.image] = imageData;
            await Log.i(
              'Found image in nested formats',
              tag: 'ClipboardProcessor',
              fields: {'imageSize': imageData.length},
            );
          } else if (imageData is List && imageData.isNotEmpty) {
            // 尝试将 List<dynamic> 转换为 Uint8List
            try {
              final uint8List = Uint8List.fromList(imageData.cast<int>());
              formats[ClipboardFormat.image] = uint8List;
              await Log.i(
                'Converted List to Uint8List in nested formats',
                tag: 'ClipboardProcessor',
                fields: {'imageSize': uint8List.length},
              );
            } on Exception catch (e) {
              await Log.e(
                'Failed to convert nested image data',
                tag: 'ClipboardProcessor',
                error: e,
              );
            }
          }
        }

        // 解析嵌套格式中的RTF
        if (nestedFormats.containsKey('rtf') && nestedFormats['rtf'] != null) {
          formats[ClipboardFormat.rtf] = nestedFormats['rtf'];
        }

        // 解析嵌套格式中的HTML
        if (nestedFormats.containsKey('html') &&
            nestedFormats['html'] != null) {
          formats[ClipboardFormat.html] = nestedFormats['html'];
        }

        // 解析嵌套格式中的文本
        if (nestedFormats.containsKey('text') &&
            nestedFormats['text'] != null) {
          formats[ClipboardFormat.text] = nestedFormats['text'];
        }
      }

      // 解析各种格式（直接格式，用于其他平台）
      if (formatsData.containsKey('rtf') && formatsData['rtf'] != null) {
        formats[ClipboardFormat.rtf] = formatsData['rtf'];
      }

      if (formatsData.containsKey('html') && formatsData['html'] != null) {
        formats[ClipboardFormat.html] = formatsData['html'];
      }

      if (formatsData.containsKey('files') && formatsData['files'] != null) {
        final filesData = formatsData['files'] as List<dynamic>?;
        if (filesData != null && filesData.isNotEmpty) {
          formats[ClipboardFormat.files] = filesData.cast<String>();
          await Log.i(
            'Found files in direct format',
            tag: 'ClipboardProcessor',
            fields: {
              'fileCount': filesData.length,
              'files': filesData.take(3).toList(), // 只记录前3个文件路径
            },
          );
        }
      }

      if (formatsData.containsKey('image') && formatsData['image'] != null) {
        final imageData = formatsData['image'];
        await Log.i(
          'Checking direct image data',
          tag: 'ClipboardProcessor',
          fields: {
            'imageDataType': imageData.runtimeType.toString(),
            'imageDataIsNull': imageData == null,
            'imageDataLength': imageData is List ? imageData.length : 'N/A',
            'isUint8List': imageData is Uint8List,
          },
        );

        if (imageData is Uint8List && imageData.isNotEmpty) {
          formats[ClipboardFormat.image] = imageData;
          await Log.i(
            'Found image in direct format',
            tag: 'ClipboardProcessor',
            fields: {'imageSize': imageData.length},
          );
        } else if (imageData is List && imageData.isNotEmpty) {
          // 尝试将 List<dynamic> 转换为 Uint8List
          try {
            final uint8List = Uint8List.fromList(imageData.cast<int>());
            formats[ClipboardFormat.image] = uint8List;
            await Log.i(
              'Converted List to Uint8List in direct format',
              tag: 'ClipboardProcessor',
              fields: {'imageSize': uint8List.length},
            );
          } on Exception catch (e) {
            await Log.e(
              'Failed to convert direct image data',
              tag: 'ClipboardProcessor',
              error: e,
            );
          }
        }
      }

      if (formatsData.containsKey('text') && formatsData['text'] != null) {
        formats[ClipboardFormat.text] = formatsData['text'];
      }

      // 如果没有任何格式，尝试获取基本文本
      if (formats.isEmpty) {
        final clipboardData = await flutter.Clipboard.getData(
          flutter.Clipboard.kTextPlain,
        );
        if (clipboardData?.text != null) {
          formats[ClipboardFormat.text] = clipboardData!.text;
        }
      }

      if (formats.isEmpty) return null;

      return ClipboardData(
        sequence: sequence,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        formats: formats,
      );
    } on Exception catch (e) {
      await Log.e(
        'Failed to get native clipboard data',
        tag: 'ClipboardProcessor',
        error: e,
      );
      return null;
    }
  }

  /// 处理图片数据（新版本）
  Future<ClipItem?> _processImageData(
    ClipboardDetectionResult detectionResult,
    String contentHash,
  ) async {
    try {
      final imageData = detectionResult.originalData?.getFormat<Uint8List>(
        ClipboardFormat.image,
      );
      if (imageData == null || imageData.isEmpty) return null;

      // 限制图片大小
      if (imageData.length > _maxContentLength) {
        return null;
      }

      // 保存图片到磁盘
      final extension = _inferImageExtension(imageData);
      final relativePath = await _saveMediaToDisk(
        bytes: imageData,
        type: 'image',
        suggestedExt: extension,
      );

      if (relativePath.isEmpty) return null;

      // 提取元数据
      final metadata = await _extractImageMetadata(imageData);

      // OCR文字识别
      String? ocrText;
      await Log.i(
        'Starting OCR processing for image',
        tag: 'ClipboardProcessor',
        fields: {
          'imageSize': imageData.length,
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
            imageData,
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
            'imageSize': imageData.length,
          },
        );
      }

      // 直接创建ClipItem，确保使用保存后的文件路径
      return ClipItem(
        id: contentHash,
        type: detectionResult.detectedType,
        content: '', // 图片类型内容为空
        filePath: relativePath, // 使用保存后的相对路径
        thumbnail: await _generateFileThumbnail(
          File(
            '${(await PathService.instance.getDocumentsDirectory()).path}/$relativePath',
          ),
        ),
        metadata: metadata,
        ocrText: ocrText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on Exception catch (e) {
      await Log.e(
        'Failed to process image data',
        tag: 'ClipboardProcessor',
        error: e,
      );
      return null;
    }
  }

  /// 处理文件数据（新版本）
  Future<ClipItem?> _processFileData(
    ClipboardDetectionResult detectionResult,
    String contentHash,
  ) async {
    try {
      final files = detectionResult.originalData?.getFormat<List<String>>(
        ClipboardFormat.files,
      );
      if (files == null || files.isEmpty) return null;

      final filePath = files.first;

      if (!await PathService.instance.fileExists(filePath)) return null;

      final file = File(filePath);

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
      } on Exception catch (e) {
        await Log.e(
          'Failed to save file data',
          tag: 'ClipboardProcessor',
          error: e,
        );
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
            final documentsDirectory = await PathService.instance
                .getDocumentsDirectory();
            final savedFilePath = '${documentsDirectory.path}/$relativePath';
            if (await PathService.instance.fileExists(savedFilePath)) {
              thumbnail = await _generateFileThumbnail(File(savedFilePath));
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
    } on Exception catch (e) {
      await Log.e(
        'Failed to process file data',
        tag: 'ClipboardProcessor',
        error: e,
      );
      return null;
    }
  }

  /// 计算内容哈希
  String _calculateContentHash(ClipboardData data) {
    // 创建基于内容的哈希（不包含sequence，确保相同内容产生相同哈希）
    final contentMap = <String, dynamic>{};

    // 按固定顺序添加格式数据，确保哈希一致性
    final sortedFormats = data.formats.keys.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final format in sortedFormats) {
      final content = data.formats[format];
      if (content != null) {
        // 对于图片数据，计算内容哈希而不是直接序列化
        if (format == ClipboardFormat.image && content is Uint8List) {
          final imageHash = sha256.convert(content).toString();
          contentMap[format.value] = 'image_hash:$imageHash';
        } else {
          // 对于其他数据，转换为字符串并计算哈希
          final contentStr = content.toString();
          final contentHash = sha256
              .convert(utf8.encode(contentStr))
              .toString();
          contentMap[format.value] = 'hash:$contentHash';
        }
      }
    }

    final content = json.encode(contentMap);
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
      final dir = await PathService.instance.getDocumentsDirectory();
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

  /// 获取源应用
  Future<String?> _getSourceApp() async {
    try {
      return await _platformChannel.invokeMethod<String>('getSourceApp');
    } on Exception catch (_) {
      return null;
    }
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
