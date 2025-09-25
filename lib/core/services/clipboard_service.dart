import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:clip_flow_pro/core/utils/image_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// 剪贴板服务
///
/// 用于监听剪贴板变化，并将剪贴板内容转换为ClipItem对象。
/// 通过轮询剪贴板内容，将剪贴板内容转换为ClipItem对象，并通过剪贴板变更流（广播）通知订阅者。
class ClipboardService {
  /// 工厂构造：返回剪贴板服务单例
  factory ClipboardService() => _instance;

  /// 私有构造：单例内部初始化
  ClipboardService._internal();

  /// 单例实例
  static final ClipboardService _instance = ClipboardService._internal();

  /// 获取剪贴板服务单例
  static ClipboardService get instance => _instance;

  final StreamController<ClipItem> _clipboardController =
      StreamController<ClipItem>.broadcast();

  /// 剪贴板变更流（广播）
  ///
  /// 订阅该流以获取新的剪贴项事件。
  Stream<ClipItem> get clipboardStream => _clipboardController.stream;

  Timer? _pollingTimer;
  String _lastClipboardContent = '';
  Uint8List? _lastImageContent;
  String? _lastImageHash; // 图片哈希值缓存
  bool _isInitialized = false;

  // 剪贴板变化检测
  int? _lastClipboardSequence; // 剪贴板序列号
  DateTime? _lastClipboardCheckTime; // 上次检查时间

  // 内容缓存机制
  final Map<String, ClipItem> _contentCache = {}; // 内容哈希 -> ClipItem
  final Map<String, DateTime> _cacheTimestamps = {}; // 缓存时间戳
  static const int _maxCacheSize = 100; // 最大缓存数量
  static const Duration _cacheExpiry = Duration(hours: 1); // 缓存过期时间

  // 自适应轮询相关变量
  int _currentPollingInterval = 500; // 当前轮询间隔(毫秒)
  int _consecutiveNoChanges = 0; // 连续无变化次数
  DateTime _lastChangeTime = DateTime.now(); // 上次变化时间

  // 轮询间隔配置
  static const int _minPollingInterval = 200; // 最小间隔(毫秒)
  static const int _maxPollingInterval = 2000; // 最大间隔(毫秒)
  static const int _noChangeThreshold = 10; // 无变化阈值

  static const MethodChannel _platformChannel = MethodChannel(
    'clipboard_service',
  );

  /// 初始化服务并启动轮询监听
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 启动剪贴板监听
    _startPolling();
    _isInitialized = true;
  }

  void _startPolling() {
    _scheduleNextCheck();
  }

  void _scheduleNextCheck() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer(Duration(milliseconds: _currentPollingInterval), () {
      _checkClipboard();
      _scheduleNextCheck(); // 递归调度下次检查
    });
  }

  void _adjustPollingInterval(bool hasChange) {
    if (hasChange) {
      // 检测到变化，重置计数器并降低间隔
      _consecutiveNoChanges = 0;
      _lastChangeTime = DateTime.now();
      _currentPollingInterval = (_currentPollingInterval * 0.8).round().clamp(
        _minPollingInterval,
        _maxPollingInterval,
      );
    } else {
      // 无变化，增加计数器
      _consecutiveNoChanges++;

      // 根据无变化次数和时间间隔调整轮询频率
      if (_consecutiveNoChanges >= _noChangeThreshold) {
        final timeSinceLastChange = DateTime.now().difference(_lastChangeTime);

        if (timeSinceLastChange.inMinutes > 5) {
          // 5分钟无变化，使用最大间隔
          _currentPollingInterval = _maxPollingInterval;
        } else if (timeSinceLastChange.inMinutes > 1) {
          // 1分钟无变化，逐步增加间隔
          _currentPollingInterval = (_currentPollingInterval * 1.2)
              .round()
              .clamp(_minPollingInterval, _maxPollingInterval);
        }
      }
    }
  }

  /// 检查剪贴板是否有变化（快速检测）
  Future<bool> _hasClipboardChanged() async {
    try {
      // 尝试获取剪贴板序列号（平台特定）
      final sequence = await _getClipboardSequence();
      if (sequence != null) {
        if (_lastClipboardSequence == null ||
            sequence != _lastClipboardSequence) {
          _lastClipboardSequence = sequence;
          return true;
        }
        return false;
      }

      // 如果无法获取序列号，使用时间戳检测
      final now = DateTime.now();
      if (_lastClipboardCheckTime == null) {
        _lastClipboardCheckTime = now;
        return true;
      }

      // 每次都检查，但可以通过其他优化减少实际内容获取
      return true;
    } on Exception catch (_) {
      return true; // 出错时假设有变化
    }
  }

  /// 获取剪贴板序列号（平台特定实现）
  Future<int?> _getClipboardSequence() async {
    try {
      final result = await _platformChannel.invokeMethod<int>(
        'getClipboardSequence',
      );
      return result;
    } on Exception catch (_) {
      return null; // 平台不支持时返回null
    }
  }

  Future<void> _checkClipboard() async {
    var hasChange = false;

    try {
      // 快速检测剪贴板是否有变化
      final hasClipboardChanged = await _hasClipboardChanged();
      if (!hasClipboardChanged) {
        _adjustPollingInterval(false);
        return;
      }

      // 1) 先取文本，若是“存在的文件路径且扩展名非图片”，优先当作文件处理
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final currentContent = clipboardData?.text ?? '';

      // 规范化候选路径：取第一条非空行并去除左右尖括号
      String firstNonEmptyLine(String s) {
        for (final line in s.split(RegExp(r'[\r\n]+'))) {
          final t = line.trim();
          if (t.isNotEmpty) return t;
        }
        return s.trim();
      }

      var candidate = firstNonEmptyLine(currentContent);
      if (candidate.startsWith('<') && candidate.endsWith('>')) {
        candidate = candidate.substring(1, candidate.length - 1).trim();
      }

      // 将 file:// URI 解析为本地路径；否则保持原样
      String possibleFilePath;
      if (candidate.startsWith('file://')) {
        try {
          possibleFilePath = Uri.parse(candidate).toFilePath();
        } on Exception catch (_) {
          // 回退方案
          possibleFilePath = candidate.replaceFirst('file://', '');
        }
      } else {
        possibleFilePath = candidate;
      }

      if (candidate.isNotEmpty && _isLikelyFilePath(possibleFilePath)) {
        final file = File(possibleFilePath);
        if (file.existsSync()) {
          // 发现有效文件路径：无论扩展名，统一按“文件”类型处理
          _lastClipboardContent = currentContent;
          await _processClipboardContent(currentContent);
          hasChange = true;
        }
      }

      // 2) 若上述未触发（不是“非图片文件”情形），再检查剪贴板图片
      if (!hasChange) {
        final imageBytes = await _getClipboardImage();
        if (imageBytes != null && imageBytes.isNotEmpty) {
          if (_lastImageContent == null ||
              !(await _areImageBytesEqual(imageBytes, _lastImageContent))) {
            _lastImageContent = imageBytes;
            // 重置哈希缓存，因为图片已更新
            _lastImageHash = null;
            await _processImageContent(imageBytes);
            hasChange = true;
          }
        } else if (_lastImageContent != null) {
          // 剪贴板中没有图片了，清除缓存
          _lastImageContent = null;
          _lastImageHash = null;
        }
      }

      // 3) 若还没有变化，则按普通文本处理
      if (!hasChange &&
          currentContent.isNotEmpty &&
          currentContent != _lastClipboardContent) {
        _lastClipboardContent = currentContent;
        await _processClipboardContent(currentContent);
        hasChange = true;
      }
    } on Exception catch (_) {
      // 忽略剪贴板访问错误
    }

    // 调整轮询间隔
    _adjustPollingInterval(hasChange);
  }

  // 辅助：判断是否看起来像文件路径（存在分隔符或以 file:// 开头）
  bool _isLikelyFilePath(String path) {
    // 兼容 Windows 路径与 URI
    return path.startsWith('file://') ||
        path.contains('/') ||
        path.contains(r'\');
  }

  /// 在 Isolate 中计算内容哈希值
  static String _calculateContentHashInIsolate(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 计算内容哈希值用于缓存（异步）
  Future<String> _calculateContentHash(String content) async {
    // 对于短文本（<10KB），直接在主线程计算
    if (content.length < ClipConstants.bytesInKB * 10) {
      return _calculateContentHashInIsolate(content);
    }

    // 对于长文本，使用 Isolate 计算
    try {
      final result = await Isolate.run(
        () => _calculateContentHashInIsolate(content),
      );
      return result;
    } on Exception catch (_) {
      // Isolate 失败时回退到主线程
      return _calculateContentHashInIsolate(content);
    }
  }

  /// 清理过期缓存
  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _contentCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// 限制缓存大小
  void _limitCacheSize() {
    if (_contentCache.length <= _maxCacheSize) return;

    // 按时间戳排序，移除最旧的条目
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final toRemove = sortedEntries.take(_contentCache.length - _maxCacheSize);
    for (final entry in toRemove) {
      _contentCache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }

  Future<void> _processClipboardContent(String content) async {
    try {
      // 计算内容哈希
      final contentHash = await _calculateContentHash(content);

      // 检查缓存
      if (_contentCache.containsKey(contentHash)) {
        final cachedItem = _contentCache[contentHash]!;
        // 更新时间戳并发送缓存的项目
        final updatedItem = cachedItem.copyWith(updatedAt: DateTime.now());
        _clipboardController.add(updatedItem);
        _cacheTimestamps[contentHash] = DateTime.now();
        return;
      }

      // 检测内容类型
      final clipType = _detectContentType(content);

      // 创建剪贴板项目
      final clipItem = ClipItem(
        type: clipType,
        content: content,
        metadata: await _extractMetadata(content, clipType),
      );

      // 添加到缓存
      _contentCache[contentHash] = clipItem;
      _cacheTimestamps[contentHash] = DateTime.now();

      // 清理过期缓存和限制大小
      _cleanExpiredCache();
      _limitCacheSize();

      // 发送到流
      _clipboardController.add(clipItem);
    } on Exception catch (_) {
      // 处理错误
    }
  }

  ClipType _detectContentType(String content) {
    // 检测颜色值
    if (ColorUtils.isColorValue(content)) {
      return ClipType.color;
    }

    // 检测文件路径
    if (content.startsWith('file://') ||
        content.contains('/') ||
        content.contains(r'\')) {
      final file = File(content.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return ClipType.file;
      }
    }

    // 检测HTML
    if (content.contains('<html>') ||
        content.contains('<div>') ||
        content.contains('<p>')) {
      return ClipType.html;
    }

    // 检测富文本
    if (content.contains(r'\rtf') || content.contains(r'\fonttbl')) {
      return ClipType.rtf;
    }

    // 默认为纯文本
    return ClipType.text;
  }

  Future<Map<String, dynamic>> _extractMetadata(
    String content,
    ClipType type,
  ) async {
    final metadata = <String, dynamic>{
      'sourceApp': await _getSourceApp(),
      'contentLength': content.length,
      'tags': <String>[],
    };

    switch (type) {
      case ClipType.color:
        metadata['colorHex'] = content;
        metadata['colorRgb'] = ColorUtils.hexToRgb(content);
        metadata['colorHsl'] = ColorUtils.hexToHsl(content);
      case ClipType.file:
        final file = File(content.replaceFirst('file://', ''));
        metadata['filePath'] = file.path;
        metadata['fileName'] = file.path.split('/').last;
        metadata['fileSize'] = await file.length();
        metadata['fileExtension'] = file.path.split('.').last.toLowerCase();
      case ClipType.image:
      // 图片处理逻辑（此处主要在 _extractImageMetadata 中完成）
      case ClipType.audio:
        // 音频元数据（当前仅基本信息，可扩展为读取音频时长/码率等）
        final file = File(content.replaceFirst('file://', ''));
        if (file.existsSync()) {
          metadata['filePath'] = file.path;
          metadata['fileName'] = file.path.split('/').last;
          metadata['fileSize'] = await file.length();
          metadata['fileExtension'] = file.path.split('.').last.toLowerCase();
        }
      case ClipType.video:
        // 视频元数据（当前仅基本文件信息）
        final vfile = File(content.replaceFirst('file://', ''));
        if (vfile.existsSync()) {
          metadata['filePath'] = vfile.path;
          metadata['fileName'] = vfile.path.split('/').last;
          metadata['fileSize'] = await vfile.length();
          metadata['fileExtension'] = vfile.path.split('.').last.toLowerCase();
        }
      case ClipType.text:
      case ClipType.html:
      case ClipType.rtf:
        // 文本内容分析
        metadata['wordCount'] = _calculateWordCount(content);
        metadata['lineCount'] = content.split('\n').length;
    }

    return metadata;
  }

  Future<Uint8List?> _getClipboardImage() async {
    try {
      final result = await _platformChannel.invokeMethod<Uint8List>(
        'getClipboardImage',
      );
      return result;
    } on Exception catch (_) {
      return null;
    }
  }

  /// 在 Isolate 中计算图片数据的SHA-256哈希值
  static String _calculateImageHashInIsolate(Uint8List imageBytes) {
    final digest = sha256.convert(imageBytes);
    return digest.toString();
  }

  /// 计算图片数据的SHA-256哈希值（异步）
  Future<String> _calculateImageHash(Uint8List imageBytes) async {
    // 对于小图片（<50KB），直接在主线程计算
    if (imageBytes.length < 51200) {
      return _calculateImageHashInIsolate(imageBytes);
    }

    // 对于大图片，使用 Isolate 计算
    try {
      final result = await Isolate.run(
        () => _calculateImageHashInIsolate(imageBytes),
      );
      return result;
    } on Exception catch (_) {
      // Isolate 失败时回退到主线程
      return _calculateImageHashInIsolate(imageBytes);
    }
  }

  /// 使用哈希值比较图片是否相同（异步）
  Future<bool> _areImageBytesEqual(
    Uint8List newBytes,
    Uint8List? lastBytes,
  ) async {
    // 快速长度检查
    if (lastBytes == null) return false;
    if (newBytes.length != lastBytes.length) return false;

    // 对于小图片（<10KB），直接比较字节
    if (newBytes.length < ClipConstants.thumbnailSize) {
      for (var i = 0; i < newBytes.length; i++) {
        if (newBytes[i] != lastBytes[i]) return false;
      }
      return true;
    }

    // 对于大图片，使用哈希值比较
    final newHash = await _calculateImageHash(newBytes);
    _lastImageHash ??= await _calculateImageHash(lastBytes);
    final isEqual = newHash == _lastImageHash;
    if (!isEqual) {
      _lastImageHash = newHash; // 更新哈希缓存
    }

    return isEqual;
  }

  Future<void> _processImageContent(Uint8List imageBytes) async {
    try {
      // 对于图片，使用已计算的哈希值作为缓存键
      final imageHash = _lastImageHash ?? await _calculateImageHash(imageBytes);

      // 检查缓存
      if (_contentCache.containsKey(imageHash)) {
        final cachedItem = _contentCache[imageHash]!;
        // 更新时间戳并发送缓存的项目
        final updatedItem = cachedItem.copyWith(updatedAt: DateTime.now());
        _clipboardController.add(updatedItem);
        _cacheTimestamps[imageHash] = DateTime.now();
        return;
      }

      // 生成缩略图
      final thumb = await ImageUtils.generateThumbnail(imageBytes);

      // 将原图保存到磁盘并获取相对路径
      final relativePath = await _saveMediaToDisk(
        bytes: imageBytes,
        type: 'image',
        suggestedExt: _inferImageExtension(imageBytes),
      );

      // 创建图片剪贴板项目（content 为空，使用 filePath + thumbnail）
      final clipItem = ClipItem(
        type: ClipType.image,
        filePath: relativePath,
        thumbnail: thumb,
        metadata: await _extractImageMetadata(imageBytes),
      );

      // 添加到缓存
      _contentCache[imageHash] = clipItem;
      _cacheTimestamps[imageHash] = DateTime.now();

      // 清理过期缓存和限制大小
      _cleanExpiredCache();
      _limitCacheSize();

      // 发送到流
      _clipboardController.add(clipItem);
    } on Exception catch (_) {
      // 处理错误
    }
  }

  int _calculateWordCount(String content) {
    if (content.isEmpty) return 0;

    // 移除首尾空白字符
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;

    // 统计中文字符数
    final chineseChars = RegExp(r'[\u4e00-\u9fa5]').allMatches(trimmed).length;

    // 统计英文单词数（按空格分割）
    final englishText = trimmed.replaceAll(RegExp(r'[\u4e00-\u9fa5]'), ' ');
    final englishWords = englishText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    // 返回中文字符数 + 英文单词数
    return chineseChars + englishWords;
  }

  Future<Map<String, dynamic>> _extractImageMetadata(
    Uint8List imageBytes,
  ) async {
    final metadata = <String, dynamic>{
      'sourceApp': await _getSourceApp(),
      'contentLength': imageBytes.length,
      'tags': <String>[],
      'fileSize': imageBytes.length,
    };

    try {
      final imageInfo = ImageUtils.getImageInfo(imageBytes);
      final fmt = imageInfo['format'];
      metadata['imageFormat'] = fmt;
      metadata['format'] = fmt;
      metadata['width'] = imageInfo['width'];
      metadata['height'] = imageInfo['height'];
      metadata['aspectRatio'] = imageInfo['aspectRatio'];
    } on Exception catch (_) {
      // 无法获取图片信息
      metadata['imageFormat'] = 'unknown';
      metadata['width'] = 0;
      metadata['height'] = 0;
    }

    return metadata;
  }

  Future<String?> _getSourceApp() async {
    // 平台特定实现获取源应用
    try {
      const platform = MethodChannel('clipboard_service');
      final result = await platform.invokeMethod<String>('getSourceApp');
      return result;
    } on Exception catch (_) {
      return null;
    }
  }

  /// 将指定剪贴项写入系统剪贴板
  ///
  /// 参数：
  /// - item：要写入的剪贴项（支持图片与文本类型）
  Future<void> setClipboardContent(ClipItem item) async {
    try {
      switch (item.type) {
        case ClipType.image:
          // 优先使用缩略图回写；生产实现应读取原图文件（filePath）回写到剪贴板
          final thumb = item.thumbnail;
          if (thumb != null && thumb.isNotEmpty) {
            await _setClipboardImage(Uint8List.fromList(thumb));
          }
        case ClipType.text:
        case ClipType.rtf:
        case ClipType.html:
        case ClipType.color:
        case ClipType.file:
        case ClipType.audio:
        case ClipType.video:
          // 文本/其他类型：按新模型使用字符串 content
          final text = item.content ?? '';
          await Clipboard.setData(ClipboardData(text: text));
          _lastClipboardContent = text;
      }
    } on Exception catch (_) {
      // 处理错误
    }
  }

  Future<void> _setClipboardImage(Uint8List imageBytes) async {
    try {
      await _platformChannel.invokeMethod('setClipboardImage', {
        'imageData': imageBytes,
      });
    } on Exception catch (_) {
      // 处理错误
    }
  }

  // ==== 媒体落盘相关：tmp -> fsync -> rename，返回相对路径 ====
  Future<String> _saveMediaToDisk({
    required Uint8List bytes,
    required String type, // 'image' | 'audio' | 'video' | 'file'
    String? suggestedExt,
  }) async {
    // 根目录：应用文档目录内的 media
    final dir = await _getMediaDir(type);
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');

    final relDir = 'media/$type/$yyyy/$mm/$dd';
    final absDir = Directory('${dir.path}/$relDir');
    if (!await absDir.exists()) {
      await absDir.create(recursive: true);
    }

    final uuid = DateTime.now().microsecondsSinceEpoch.toString();
    final ext = (suggestedExt ?? 'bin').replaceAll('.', '');
    final relPath = '$relDir/$uuid.$ext';
    final absPath = '${dir.path}/$relPath';

    // 1) 写入 tmp 文件
    final tmpFile = File('$absPath.tmp');
    await tmpFile.writeAsBytes(bytes, flush: true);

    // 2) fsync：Dart 无直接 fsync，flush:true 已尽力；可追加 reopen 并 setLastModified 触发落盘
    try {
      await tmpFile.setLastModified(DateTime.now());
    } on Exception catch (_) {}

    // 3) rename 到最终路径（原子）
    await tmpFile.rename(absPath);

    // 返回相对路径
    return relPath;
  }

  Future<Directory> _getMediaDir(String type) async {
    // 统一到应用文档目录（与 DatabaseService 删除逻辑一致）
    final docs = await getApplicationDocumentsDirectory();
    return Directory(docs.path);
  }

  String _inferImageExtension(Uint8List bytes) {
    // 简单魔数判断
    if (bytes.length >= 4) {
      // PNG
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      // JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';
      // GIF
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'gif';
      }
      // WEBP (RIFF....WEBP)
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return 'webp';
      }
    }
    return 'bin';
  }

  /// 清空系统剪贴板（文本渠道）
  Future<void> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      _lastClipboardContent = '';
    } on Exception catch (_) {
      // 处理错误
    }
  }

  /// 释放资源：停止轮询、关闭流并清理缓存
  void dispose() {
    _pollingTimer?.cancel();
    _clipboardController.close();

    // 清理缓存
    _contentCache.clear();
    _cacheTimestamps.clear();
  }
}

// Riverpod Provider
//// Riverpod Provider

/// 剪贴板服务 Provider（单例）
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  return ClipboardService.instance;
});

/// 剪贴板变更流 Provider
final clipboardStreamProvider = StreamProvider<ClipItem>((ref) {
  final service = ref.watch(clipboardServiceProvider);
  return service.clipboardStream;
});
