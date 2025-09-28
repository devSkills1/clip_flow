import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:clip_flow_pro/core/utils/image_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
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

      // 首先检查平台剪贴板类型
      final clipboardInfo = await _getClipboardType();
      if (clipboardInfo != null && clipboardInfo['type'] == 'file') {
        unawaited(
          Log.d(
            'Detected file type from platform: ${clipboardInfo['subType']}',
            tag: 'clipboard',
          ),
        );
        await _processFileClipboard(clipboardInfo);
        hasChange = true;
        _adjustPollingInterval(hasChange);
        return;
      }

      // 检查RTF和HTML剪贴板内容
      final richTextResult = await _checkRichTextClipboard();
      if (richTextResult) {
        hasChange = true;
        _adjustPollingInterval(hasChange);
        return;
      }

      // 1) 先取文本，若是"存在的文件路径且扩展名非图片"，优先当作文件处理
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
          // 检查是否为图片文件
          if (_isImageFile(possibleFilePath)) {
            // 图片文件：读取文件内容并按图片处理
            try {
              final imageBytes = await file.readAsBytes();
              if (_lastImageContent == null ||
                  !(await _areImageBytesEqual(imageBytes, _lastImageContent))) {
                _lastImageContent = imageBytes;
                _lastImageHash = null;
                await _processImageContent(imageBytes);
                hasChange = true;
              }
            } on Exception catch (_) {
              // 读取失败时按文件处理
              _lastClipboardContent = currentContent;
              await _processClipboardContent(currentContent);
              hasChange = true;
            }
          } else {
            // 非图片文件：按文件类型处理
            _lastClipboardContent = currentContent;
            await _processClipboardContent(currentContent);
            hasChange = true;
          }
        }
      }

      // 2) 若上述未触发（不是"非图片文件"情形），再检查剪贴板图片
      if (!hasChange) {
        unawaited(Log.d('Checking for clipboard image...', tag: 'clipboard'));
        final imageBytes = await _getClipboardImage();
        unawaited(
          Log.d(
            'Image bytes received: ${imageBytes?.length ?? 0} bytes',
            tag: 'clipboard',
          ),
        );
        if (imageBytes != null && imageBytes.isNotEmpty) {
          if (_lastImageContent == null ||
              !(await _areImageBytesEqual(imageBytes, _lastImageContent))) {
            unawaited(Log.d('Processing new image content', tag: 'clipboard'));
            _lastImageContent = imageBytes;
            // 重置哈希缓存，因为图片已更新
            _lastImageHash = null;
            await _processImageContent(imageBytes);
            hasChange = true;
          } else {
            unawaited(Log.d('Image content unchanged', tag: 'clipboard'));
          }
        } else if (_lastImageContent != null) {
          // 剪贴板中没有图片了，清除缓存
          unawaited(Log.d('Clearing image cache', tag: 'clipboard'));
          _lastImageContent = null;
          _lastImageHash = null;
        }
      }

      // 3) 若还没有变化，则按普通文本处理
      if (!hasChange &&
          currentContent.isNotEmpty &&
          currentContent.trim().isNotEmpty &&
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
      // 验证内容是否有效（非空且不只白字符）
      if (content.trim().isEmpty) {
        unawaited(Log.d('Skipping empty content', tag: 'clipboard'));
        return;
      }

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

      // 创建剪贴板项目（保持内容为原始纯文本）
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
      unawaited(
        Log.d(
          'Rich text clip item created: ${clipItem.type.name}',
          tag: 'clipboard',
        ),
      );
    } on Exception catch (_) {
      // 处理错误
    }
  }

  /// 测试用：根据内容检测剪贴板类型（不缓存）
  ClipType detectContentTypeForTesting(String content) {
    // Public wrapper for unit tests
    return _detectContentType(content);
  }

  ClipType _detectContentType(String content) {
    unawaited(
      Log.d(
        'Detecting content type for: '
        '${content.length > 50 ? "${content.substring(0, 50)}..." : content}',
        tag: 'clipboard',
      ),
    );

    final trimmed = content.trim();

    // 空内容检查
    if (trimmed.isEmpty) {
      Log.d('Detected as empty text', tag: 'clipboard');
      return ClipType.text;
    }

    // 1. 检测颜色值 - 最高优先级（精确匹配）
    if (_isColorValue(trimmed)) {
      Log.d('Detected as color: $content', tag: 'clipboard');
      return ClipType.color;
    }

    // 2. 检测富文本（RTF）- 第二优先级
    if (_isRtfContent(trimmed)) {
      Log.d('Detected as RTF content', tag: 'clipboard');
      return ClipType.rtf;
    }

    // 3. 检测代码 - 第三优先级（在HTML之前检测，避免代码被误识别为HTML）
    if (_isCodeContent(trimmed)) {
      Log.d('Detected as code content', tag: 'clipboard');
      return ClipType.code;
    }

    // 4. 检测HTML - 第四优先级（更严格的检测）
    if (_isHtmlContent(trimmed)) {
      Log.d('Detected as HTML content', tag: 'clipboard');
      return ClipType.html;
    }

    // 5. 检测文件路径 - 第五优先级
    if (_isFilePath(trimmed)) {
      final fileType = _detectFileTypeFromPath(trimmed);
      Log.d('Detected as $fileType file path: $trimmed', tag: 'clipboard');
      return fileType;
    }

    // 6. 检测URL - 第六优先级
    if (_isUrl(trimmed)) {
      Log.d('Detected as URL: $trimmed', tag: 'clipboard');
      return ClipType.url;
    }

    // 7. 检测邮箱 - 第七优先级
    if (_isEmail(trimmed)) {
      Log.d('Detected as email: $trimmed', tag: 'clipboard');
      return ClipType.email;
    }

    // 8. 检测JSON - 第八优先级
    if (_isJsonContent(trimmed)) {
      Log.d('Detected as JSON content', tag: 'clipboard');
      return ClipType.json;
    }

    // 9. 检测XML - 第九优先级
    if (_isXmlContent(trimmed)) {
      Log.d('Detected as XML content', tag: 'clipboard');
      return ClipType.xml;
    }

    // 默认为纯文本
    Log.d('Detected as plain text', tag: 'clipboard');
    return ClipType.text;
  }

  /// 检测是否为HTML内容
  bool _isHtmlContent(String content) {
    final trimmed = content.trim().toLowerCase();

    // 首先检查是否为完整的HTML文档
    if (trimmed.startsWith('<!doctype html') ||
        trimmed.startsWith('<html') ||
        (trimmed.contains('<head>') && trimmed.contains('<body>'))) {
      return true;
    }

    // 检查HTML实体（强烈表明是HTML内容）
    if (content.contains('&lt;') ||
        content.contains('&gt;') ||
        content.contains('&amp;') ||
        content.contains('&quot;') ||
        content.contains('&#')) {
      return true;
    }

    // 检查是否为HTML片段，但需要更严格的条件
    final htmlTagCount = _countHtmlTags(trimmed);
    final codeIndicators = _countCodeIndicators(content);

    // 如果HTML标签数量多且代码特征少，才认为是HTML
    return htmlTagCount >= 3 && codeIndicators < 2;
  }

  /// 计算HTML标签数量
  int _countHtmlTags(String content) {
    final htmlTags = [
      '<div',
      '<p>',
      '<span',
      '<a href',
      '<img',
      '<h1',
      '<h2',
      '<h3',
      '<ul>',
      '<li>',
      '<table',
      '<tr>',
      '<td>',
      '<form',
      '<input',
      '<button',
      '<script',
      '<style',
      '<link',
      '<meta',
    ];

    var count = 0;
    for (final tag in htmlTags) {
      if (content.contains(tag)) {
        count++;
      }
    }
    return count;
  }

  /// 计算代码特征数量
  int _countCodeIndicators(String content) {
    final codeIndicators = [
      RegExp(r'(function|def|func|fn)\s+\w+\s*\('),
      RegExp(r'(class|struct|interface)\s+\w+'),
      RegExp(r'(import|include|require|use)\s+'),
      RegExp(r'(var|let|const|final|int|String|double|bool)\s+\w+'),
      RegExp(r'(if|for|while|switch|try|catch)\s*\('),
      RegExp(r'//.*$', multiLine: true),
      RegExp(r'/\*.*?\*/', dotAll: true),
      RegExp(r';\s*$', multiLine: true),
    ];

    var count = 0;
    for (final indicator in codeIndicators) {
      if (indicator.hasMatch(content)) {
        count++;
      }
    }
    return count;
  }

  /// 检测是否为RTF内容
  bool _isRtfContent(String content) {
    final trimmed = content.trim();

    // 检查RTF标识符
    if (trimmed.startsWith(r'{\rtf') ||
        content.contains(r'\fonttbl') ||
        content.contains(r'\colortbl') ||
        content.contains(r'\viewkind') ||
        content.contains(r'\uc1\pard')) {
      return true;
    }

    return false;
  }

  /// 检测是否为颜色值
  bool _isColorValue(String content) {
    return ColorUtils.isColorValue(content);
  }

  /// 检测是否为文件路径
  bool _isFilePath(String content) {
    final trimmed = content.trim();

    // 基本路径检查
    if (!trimmed.contains('/') && !trimmed.contains(r'\')) {
      return false;
    }

    // 检查是否以file://开头
    if (trimmed.startsWith('file://')) {
      return true;
    }

    // 检查是否包含文件扩展名
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot == -1 || lastDot == trimmed.length - 1) {
      return false;
    }

    final extension = trimmed.substring(lastDot + 1).toLowerCase();

    // 检查是否为常见文件扩展名
    const commonExtensions = [
      // 图片
      'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'svg', 'ico', 'tiff', 'tif',
      // 音频
      'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma', 'aiff', 'au',
      // 视频
      'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv', 'm4v', '3gp', 'ts',
      // 文档
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf',
      // 代码
      'dart', 'js', 'ts', 'html', 'css', 'json', 'xml', 'yaml', 'yml',
      'py', 'java', 'cpp', 'c', 'h', 'swift', 'kt', 'go', 'rs', 'php',
      // 压缩
      'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz',
    ];

    return commonExtensions.contains(extension);
  }

  /// 根据文件路径检测文件类型
  ClipType _detectFileTypeFromPath(String path) {
    final trimmed = path.trim().toLowerCase();
    final lastDot = trimmed.lastIndexOf('.');

    if (lastDot == -1) {
      return ClipType.file;
    }

    final extension = trimmed.substring(lastDot + 1);

    // 图片文件
    const imageExtensions = [
      'png',
      'jpg',
      'jpeg',
      'gif',
      'bmp',
      'webp',
      'svg',
      'ico',
      'tiff',
      'tif',
      'heic',
      'heif',
    ];
    if (imageExtensions.contains(extension)) {
      return ClipType.image;
    }

    // 音频文件
    const audioExtensions = [
      'mp3',
      'wav',
      'aac',
      'flac',
      'ogg',
      'm4a',
      'wma',
      'aiff',
      'au',
    ];
    if (audioExtensions.contains(extension)) {
      return ClipType.audio;
    }

    // 视频文件
    const videoExtensions = [
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
      'mkv',
      'm4v',
      '3gp',
      'ts',
      'mts',
      'm2ts',
    ];
    if (videoExtensions.contains(extension)) {
      return ClipType.video;
    }

    // 默认为文件
    return ClipType.file;
  }

  /// 检测是否为URL
  bool _isUrl(String content) {
    final urlRegex = RegExp(ClipConstants.urlPattern, caseSensitive: false);
    return urlRegex.hasMatch(content.trim());
  }

  /// 检测是否为邮箱
  bool _isEmail(String content) {
    final emailRegex = RegExp(ClipConstants.emailPattern, caseSensitive: false);
    return emailRegex.hasMatch(content.trim());
  }

  /// 检测是否为JSON内容
  bool _isJsonContent(String content) {
    final trimmed = content.trim();

    // 基本格式检查
    if ((!trimmed.startsWith('{') || !trimmed.endsWith('}')) &&
        (!trimmed.startsWith('[') || !trimmed.endsWith(']'))) {
      return false;
    }

    // 尝试解析JSON
    try {
      json.decode(trimmed);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// 检测是否为XML内容
  bool _isXmlContent(String content) {
    final trimmed = content.trim().toLowerCase();

    // 检查XML声明
    if (trimmed.startsWith('<?xml')) {
      return true;
    }

    // 检查基本XML标签结构，但要更严格
    if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
      // 检查是否包含XML命名空间或多个嵌套标签
      final hasNamespace = RegExp(r'<\w+:\w+').hasMatch(trimmed);
      final hasMultipleTags = RegExp(
        r'<\w+[^>]*>.*<\w+[^>]*>',
      ).hasMatch(trimmed);
      final hasXmlAttributes = RegExp(r'xmlns\s*=').hasMatch(trimmed);

      // 只有当内容具有明显的XML特征时才识别为XML
      if (hasNamespace ||
          hasXmlAttributes ||
          (hasMultipleTags && trimmed.length > 100)) {
        final tagPattern = RegExp(
          r'<\s*([a-zA-Z][a-zA-Z0-9]*)\s*[^>]*>.*</\s*\1\s*>',
          dotAll: true,
        );
        return tagPattern.hasMatch(trimmed);
      }
    }

    return false;
  }

  /// 检测是否为代码内容
  bool _isCodeContent(String content) {
    final trimmed = content.trim();

    // 检查代码特征
    final codePatterns = [
      // 函数定义
      RegExp(r'(function|def|func|fn)\s+\w+\s*\('),
      // 类定义
      RegExp(r'(class|struct|interface)\s+\w+'),
      // 导入语句
      RegExp(r'(import|include|require|use)\s+'),
      // 变量声明
      RegExp(r'(var|let|const|final|int|String|double|bool)\s+\w+'),
      // 控制结构
      RegExp(r'(if|for|while|switch|try|catch)\s*\('),
      // 注释
      RegExp(r'(//|/\*|\*|#|<!--)'),
      // 分号结尾
      RegExp(r';\s*$', multiLine: true),
      // 大括号结构
      RegExp(r'\{\s*\n.*\n\s*\}', dotAll: true),
    ];

    var matches = 0;
    for (final pattern in codePatterns) {
      if (pattern.hasMatch(trimmed)) {
        matches++;
      }
    }

    // 如果匹配多个代码特征，认为是代码
    return matches >= 2;
  }

  /// 估算代码语言（基于启发式规则）
  String _estimateLanguage(String content) {
    final text = content.trim();

    // 已有 Markdown 代码块语言标记
    final fenceLang = RegExp(r'^```\s*([a-zA-Z0-9_+#.-]+)', multiLine: true);
    final fenceMatch = fenceLang.firstMatch(text);
    if (fenceMatch != null) {
      final lang = fenceMatch.group(1)?.toLowerCase() ?? 'unknown';
      if (lang.isNotEmpty) return lang;
    }

    // Shebang 检测
    if (text.startsWith('#!')) {
      if (text.contains('python')) return 'python';
      if (text.contains('bash') || text.contains('sh')) return 'shell';
      if (text.contains('node')) return 'javascript';
    }

    // Dart
    if (RegExp(r'void\s+main\s*\(').hasMatch(text) ||
        RegExp(r'class\s+\w+\s+extends\s+\w+').hasMatch(text) ||
        text.contains("import 'package:") ||
        text.contains('@override')) {
      return 'dart';
    }

    // TypeScript
    if (text.contains('interface ') ||
        RegExp(r'\benum\b').hasMatch(text) ||
        RegExp(r'\btype\s+\w+\s*=').hasMatch(text) ||
        RegExp(r'\bexport\s+(class|function|const|type)').hasMatch(text) &&
            text.contains(':')) {
      return 'typescript';
    }

    // JavaScript
    if (text.contains('console.log') ||
        text.contains('export default') ||
        text.contains('import React from') ||
        RegExp(r'function\s+\w+\s*\(').hasMatch(text) ||
        RegExp(r'=>\s*\{?').hasMatch(text)) {
      return 'javascript';
    }

    // Python
    if (RegExp(r'^def\s+\w+\s*\(', multiLine: true).hasMatch(text) ||
        RegExp(r'^class\s+\w+:', multiLine: true).hasMatch(text) ||
        text.contains('if __name__ == "__main__"') ||
        RegExp(r'^import\s+\w+', multiLine: true).hasMatch(text)) {
      return 'python';
    }

    // Java
    if (text.contains('public static void main') ||
        text.contains('System.out.println') ||
        RegExp(r'^package\s+\w+(\.\w+)*;').hasMatch(text) ||
        RegExp(r'^import\s+\w+(\.\w+)*;').hasMatch(text)) {
      return 'java';
    }

    // Kotlin
    if (RegExp(r'^fun\s+\w+\s*\(', multiLine: true).hasMatch(text) ||
        text.contains('data class ') ||
        RegExp(r'\bval\b').hasMatch(text) ||
        RegExp(r'\bvar\b').hasMatch(text)) {
      return 'kotlin';
    }

    // Swift
    if (text.contains('import SwiftUI') ||
        RegExp(r'^func\s+\w+\s*\(', multiLine: true).hasMatch(text) ||
        RegExp(r'\blet\b').hasMatch(text) ||
        text.contains('@UIApplicationMain')) {
      return 'swift';
    }

    // C
    if (text.contains('#include <stdio.h>') ||
        RegExp(r'int\s+main\s*\(').hasMatch(text) && !text.contains('std::')) {
      return 'c';
    }

    // C++
    if (text.contains('#include <iostream>') ||
        text.contains('std::') ||
        RegExp('template<').hasMatch(text)) {
      return 'cpp';
    }

    // C#
    if (text.contains('using System;') ||
        text.contains('namespace ') ||
        text.contains('Console.WriteLine')) {
      return 'csharp';
    }

    // Go
    if (text.contains('package main') ||
        RegExp(r'^func\s+\w+\s*\(', multiLine: true).hasMatch(text) ||
        text.contains('fmt.')) {
      return 'go';
    }

    // Rust
    if (text.contains('fn main()') ||
        text.contains('println!') ||
        text.contains('let mut ') ||
        text.contains('pub ') ||
        text.contains('use ')) {
      return 'rust';
    }

    // PHP
    if (text.contains('<?php') ||
        RegExp(r'\$\w+\s*=').hasMatch(text) ||
        text.contains('echo ')) {
      return 'php';
    }

    // Ruby
    if (RegExp(r'^def\s+\w+', multiLine: true).hasMatch(text) ||
        RegExp(r'^class\s+\w+', multiLine: true).hasMatch(text) ||
        RegExp(r'^end\s*$', multiLine: true).hasMatch(text) ||
        text.contains('puts ')) {
      return 'ruby';
    }

    // Shell
    if (RegExp('^#!/bin/(bash|sh|zsh)', multiLine: true).hasMatch(text) ||
        RegExp(r'\bif\s+\[.*\]\s*;?\s*then').hasMatch(text) ||
        RegExp(r'\becho\b').hasMatch(text)) {
      return 'shell';
    }

    // SQL
    if (RegExp(
      r'\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bCREATE\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return 'sql';
    }

    // CSS
    if (RegExp(r'\.[a-zA-Z0-9_-]+\s*\{').hasMatch(text) ||
        RegExp(r'[a-zA-Z-]+\s*:\s*[^;]+;').hasMatch(text)) {
      return 'css';
    }

    // HTML（若被识别为代码片段而非完整 HTML 文档）
    if (RegExp(r'<\w+[^>]*>').hasMatch(text) &&
        RegExp(r'</\w+>').hasMatch(text)) {
      return 'html';
    }

    // YAML
    if (RegExp(r'^\w[\w-]*:\s+.+', multiLine: true).hasMatch(text) ||
        RegExp(r'^-\s+\w', multiLine: true).hasMatch(text)) {
      return 'yaml';
    }

    // 默认
    return 'plain';
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
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
        // 文本内容分析
        try {
          final wordCount = _calculateWordCount(content);
          final lineCount = content.split('\n').length;
          metadata['wordCount'] = wordCount;
          metadata['lineCount'] = lineCount;

          // 为特定类型添加额外元数据
          switch (type) {
            case ClipType.url:
              metadata['domain'] = Uri.tryParse(content)?.host ?? '';
              metadata['scheme'] = Uri.tryParse(content)?.scheme ?? '';
            case ClipType.email:
              final parts = content.split('@');
              if (parts.length == 2) {
                metadata['username'] = parts[0];
                metadata['domain'] = parts[1];
              }
            case ClipType.json:
              metadata['isValidJson'] = true;
            case ClipType.xml:
              metadata['isValidXml'] = true;
            case ClipType.code:
              final lang = _estimateLanguage(content);
              metadata['estimatedLanguage'] = lang;
              // 生成 Markdown 代码块（不用于 UI 高亮，仅用于导出/记录）
              final trimmed = content.trim();
              final hasFence =
                  trimmed.startsWith('```') && trimmed.endsWith('```');
              metadata['markdownContent'] = hasFence
                  ? content
                  : '```${lang == 'plain' ? '' : lang}\n$content\n```';
            default:
              break;
          }

          unawaited(
            Log.d(
              'Text metadata: wordCount=$wordCount, lineCount=$lineCount',
              tag: 'clipboard',
            ),
          );
        } on Exception catch (e) {
          unawaited(
            Log.e(
              'Error extracting text metadata',
              tag: 'clipboard',
              error: e,
            ),
          );
          metadata['wordCount'] = 0;
          metadata['lineCount'] = 1;
        }
    }

    return metadata;
  }

  Future<Uint8List?> _getClipboardImage() async {
    try {
      unawaited(
        Log.d(
          'Calling platform method getClipboardImage',
          tag: 'clipboard',
        ),
      );
      final result = await _platformChannel.invokeMethod<Uint8List>(
        'getClipboardImage',
      );
      unawaited(
        Log.d(
          'Platform method returned: ${result?.length ?? 0} bytes',
          tag: 'clipboard',
        ),
      );
      return result;
    } on Exception catch (e) {
      unawaited(
        Log.e('Error getting clipboard image', tag: 'clipboard', error: e),
      );
      return null;
    }
  }

  /// 获取剪贴板类型信息
  Future<Map<String, dynamic>?> _getClipboardType() async {
    try {
      final result = await _platformChannel.invokeMethod<Map<Object?, Object?>>(
        'getClipboardType',
      );
      if (result != null) {
        // 将Map<Object?, Object?>转换为Map<String, dynamic>
        final converted = result.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        unawaited(
          Log.d(
            'Native clipboard type result: $converted',
            tag: 'clipboard',
          ),
        );
        return converted;
      }
      unawaited(Log.d('No clipboard type data from native', tag: 'clipboard'));
      return null;
    } on Exception catch (e) {
      unawaited(
        Log.e('Error getting clipboard type', tag: 'clipboard', error: e),
      );
      return null;
    }
  }

  /// 处理文件类型剪贴板
  Future<void> _processFileClipboard(Map<String, dynamic> clipboardInfo) async {
    try {
      final content = clipboardInfo['content'];
      final primaryPath = clipboardInfo['primaryPath'];
      final subType = clipboardInfo['subType'] ?? 'file';

      unawaited(
        Log.d(
          'Processing file clipboard: type=$subType, path=$primaryPath',
          tag: 'clipboard',
        ),
      );

      if (content is List && content.isNotEmpty) {
        final filePaths = content.cast<String>();
        final firstPath = filePaths.first;

        // 验证文件是否存在
        final file = File(firstPath);
        if (!file.existsSync()) {
          unawaited(Log.w('File does not exist: $firstPath', tag: 'clipboard'));
          return;
        }

        // 计算内容哈希（使用文件路径和修改时间）
        final stat = file.statSync();
        final contentKey =
            '$firstPath:${stat.modified.millisecondsSinceEpoch}:${stat.size}';
        final contentHash = await _calculateContentHash(contentKey);

        // 检查缓存
        if (_contentCache.containsKey(contentHash)) {
          unawaited(Log.d('Found cached file item', tag: 'clipboard'));
          final cachedItem = _contentCache[contentHash]!;
          final updatedItem = cachedItem.copyWith(updatedAt: DateTime.now());
          _clipboardController.add(updatedItem);
          _cacheTimestamps[contentHash] = DateTime.now();
          return;
        }

        unawaited(Log.d('Creating new file item', tag: 'clipboard'));

        // 确定剪贴板项目类型
        final ClipType clipType;
        switch (subType) {
          case 'image':
            clipType = ClipType.image;
          case 'video':
            clipType = ClipType.video;
          case 'audio':
            clipType = ClipType.audio;
          case 'document':
          case 'code':
          case 'archive':
          default:
            clipType = ClipType.file;
        }

        // 生成缩略图（仅对图片）
        Uint8List? thumbnail;
        if (subType == 'image') {
          try {
            final imageBytes = await file.readAsBytes();
            thumbnail = await ImageUtils.generateThumbnail(imageBytes);
          } on Exception catch (e) {
            unawaited(
              Log.w(
                'Failed to generate thumbnail for image file',
                tag: 'clipboard',
                error: e,
              ),
            );
          }
        }

        // 创建剪贴板项目
        final clipItem = ClipItem(
          type: clipType,
          content: firstPath,
          filePath: firstPath,
          thumbnail: thumbnail,
          metadata: <String, dynamic>{
            'fileType': subType,
            'fileName': file.uri.pathSegments.last,
            'fileSize': stat.size,
            'fileCount': filePaths.length,
            if (filePaths.length > 1) 'allPaths': filePaths,
          },
        );

        // 添加到缓存
        _contentCache[contentHash] = clipItem;
        _cacheTimestamps[contentHash] = DateTime.now();

        // 清理过期缓存
        _cleanExpiredCache();
        _limitCacheSize();

        // 发送到流
        _clipboardController.add(clipItem);
        unawaited(
          Log.d('File clip item created and sent to stream', tag: 'clipboard'),
        );
      } else {
        unawaited(Log.w('Invalid file clipboard content', tag: 'clipboard'));
      }
    } on Exception catch (e) {
      unawaited(
        Log.e('Error processing file clipboard', tag: 'clipboard', error: e),
      );
    }
  }

  /// 检查富文本剪贴板内容（RTF、HTML）
  Future<bool> _checkRichTextClipboard() async {
    try {
      // 当存在富文本时，优先尝试获取纯文本并判断是否为代码
      // 这样可以避免把 IDE/网页复制的带高亮 RTF/HTML 当作富文本存储
      final plainData = await Clipboard.getData(Clipboard.kTextPlain);
      final plainText = plainData?.text?.trim() ?? '';
      if (plainText.isNotEmpty && _isCodeContent(plainText)) {
        unawaited(
          Log.d(
            'Plain text looks like code, prefer text/code over RTF/HTML',
            tag: 'clipboard',
          ),
        );
        await _processClipboardContent(plainText);
        return true;
      }
      // 检查RTF剪贴板
      final rtfData = await _getRichTextData('rtf');
      if (rtfData != null && rtfData.isNotEmpty) {
        unawaited(
          Log.d(
            'Found RTF content: ${rtfData.length} chars',
            tag: 'clipboard',
          ),
        );
        await _processRichTextContent(rtfData, ClipType.rtf);
        return true;
      }

      // 检查HTML剪贴板（增强：若HTML看起来是代码，按 Code 处理）
      final htmlData = await _getRichTextData('html');
      if (htmlData != null && htmlData.isNotEmpty) {
        // 从 HTML 中提取可能的代码文本（如 <pre><code>…</code></pre>），并做实体解码
        final htmlCandidate = _extractHtmlCodeCandidate(htmlData);
        if (htmlCandidate.isNotEmpty && _isCodeContent(htmlCandidate)) {
          unawaited(
            Log.d(
              'HTML rich text looks like code, store as Code (plain text)',
              tag: 'clipboard',
            ),
          );
          await _processClipboardContent(htmlCandidate);
          return true;
        }
        unawaited(
          Log.d(
            'Found HTML content: ${htmlData.length} chars',
            tag: 'clipboard',
          ),
        );
        await _processRichTextContent(htmlData, ClipType.html);
        return true;
      }

      return false;
    } on Exception catch (e) {
      unawaited(
        Log.w(
          'Error checking rich text clipboard',
          tag: 'clipboard',
          error: e,
        ),
      );
      return false;
    }
  }

  /// 从HTML提取可能的代码候选文本：
  /// - 优先抓取 <pre><code>…</code></pre> 或 <code>…</code> 的内容
  /// - 其次尝试 <pre>…</pre>
  /// - 去除标签、解码常见实体（&lt; &gt; &amp; &quot; &#39;）
  String _extractHtmlCodeCandidate(String html) {
    try {
      var candidate = html;

      // 匹配 <pre><code>…</code></pre>
      final preCode = RegExp(
        r'<pre[^>]*>\s*<code[^>]*>([\s\S]*?)</code>\s*</pre>',
        caseSensitive: false,
      );
      final codeOnly = RegExp(
        r'<code[^>]*>([\s\S]*?)</code>',
        caseSensitive: false,
      );
      final preOnly = RegExp(
        r'<pre[^>]*>([\s\S]*?)</pre>',
        caseSensitive: false,
      );

      final m = preCode.firstMatch(html) ?? codeOnly.firstMatch(html);
      if (m != null) {
        candidate = m.group(1) ?? '';
      } else {
        final m2 = preOnly.firstMatch(html);
        if (m2 != null) candidate = m2.group(1) ?? candidate;
      }

      // 处理换行标签，统一换行符；移除其它 HTML 标签但不插入额外空格
      candidate = candidate.replaceAll(RegExp(r'(?i)<br\s*/?>'), '\n');
      candidate = candidate.replaceAll(RegExp(r'\r\n?|\f'), '\n');
      candidate = candidate.replaceAll(RegExp('<[^>]+>'), '');

      // 实体解码（保留缩进与多空格/Tab，不进行全局空白折叠）
      candidate = candidate
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'");

      // 不进行 trim()，以免丢失首行缩进；统一换行符后直接返回
      return candidate;
    } on Exception catch (_) {
      // 解析失败则直接返回原始内容
      return html.replaceAll(RegExp(r'\r\n?'), '\n');
    }
  }

  /// 获取富文本数据
  Future<String?> _getRichTextData(String type) async {
    try {
      final result = await _platformChannel.invokeMethod<String>(
        'getRichTextData',
        {'type': type},
      );
      return result;
    } on Exception {
      unawaited(Log.d('No $type data available', tag: 'clipboard'));
      return null;
    }
  }

  /// 处理富文本内容
  Future<void> _processRichTextContent(String content, ClipType type) async {
    try {
      // 计算内容哈希
      final contentHash = await _calculateContentHash(content);

      // 检查缓存
      if (_contentCache.containsKey(contentHash)) {
        final cachedItem = _contentCache[contentHash]!;
        final updatedItem = cachedItem.copyWith(updatedAt: DateTime.now());
        _clipboardController.add(updatedItem);
        _cacheTimestamps[contentHash] = DateTime.now();
        return;
      }

      // 创建剪贴板项目
      final clipItem = ClipItem(
        type: type,
        content: content,
        metadata: await _extractMetadata(content, type),
      );

      // 添加到缓存
      _contentCache[contentHash] = clipItem;
      _cacheTimestamps[contentHash] = DateTime.now();

      // 清理过期缓存
      _cleanExpiredCache();
      _limitCacheSize();

      // 发送到流
      _clipboardController.add(clipItem);
      unawaited(
        Log.d(
          'Rich text clip item created: ${clipItem.type.name}',
          tag: 'clipboard',
        ),
      );
    } on Exception catch (e) {
      unawaited(
        Log.e('Error processing rich text content', tag: 'clipboard', error: e),
      );
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
      unawaited(
        Log.d(
          'Processing image content, size: ${imageBytes.length} bytes',
          tag: 'clipboard',
        ),
      );

      // 对于图片，使用已计算的哈希值作为缓存键
      final imageHash = _lastImageHash ?? await _calculateImageHash(imageBytes);
      unawaited(Log.d('Image hash: $imageHash', tag: 'clipboard'));

      // 检查缓存
      if (_contentCache.containsKey(imageHash)) {
        unawaited(Log.d('Found cached image item', tag: 'clipboard'));
        final cachedItem = _contentCache[imageHash]!;
        // 更新时间戳并发送缓存的项目
        final updatedItem = cachedItem.copyWith(updatedAt: DateTime.now());
        _clipboardController.add(updatedItem);
        _cacheTimestamps[imageHash] = DateTime.now();
        return;
      }

      unawaited(Log.d('Creating new image item', tag: 'clipboard'));

      // 生成缩略图
      final thumb = await ImageUtils.generateThumbnail(imageBytes);

      // 将原图保存到磁盘并获取相对路径
      final relativePath = await _saveMediaToDisk(
        bytes: imageBytes,
        type: 'image',
        suggestedExt: _inferImageExtension(imageBytes),
      );

      unawaited(Log.d('Image saved to: $relativePath', tag: 'clipboard'));

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

      unawaited(
        Log.d('Image clip item created and sent to stream', tag: 'clipboard'),
      );
    } on Exception catch (e) {
      unawaited(
        Log.e('Error processing image content', tag: 'clipboard', error: e),
      );
      // 处理错误
    }
  }

  int _calculateWordCount(String content) {
    try {
      if (content.isEmpty) {
        Log.d('Empty content for word count', tag: 'clipboard');
        return 0;
      }

      // 移除首尾空白字符
      final trimmed = content.trim();
      if (trimmed.isEmpty) {
        Log.d('Content is empty after trim', tag: 'clipboard');
        return 0;
      }

      Log.d(
        'Calculating word count for content length: ${trimmed.length}',
        tag: 'clipboard',
      );

      // 统计中文字符数
      final chineseRegex = RegExp(r'[\u4e00-\u9fa5]');
      final chineseChars = chineseRegex.allMatches(trimmed).length;

      // 统计英文单词数（按空格分割）
      final englishText = trimmed.replaceAll(chineseRegex, ' ');
      final englishWords = englishText
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty && word.isNotEmpty)
          .length;

      final totalCount = chineseChars + englishWords;
      unawaited(
        Log.d(
          'Word count result: $totalCount '
          '(Chinese: $chineseChars, English: $englishWords)',
          tag: 'clipboard',
        ),
      );

      // 返回中文字符数 + 英文单词数
      return totalCount;
    } on Exception catch (e, stackTrace) {
      Log.e(
        'Error calculating word count',
        tag: 'clipboard',
        error: e,
        stackTrace: stackTrace,
      );
      return 0; // 返回默认值而不是失败
    }
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
          // 对于图片类型，如果有文件路径，优先复制文件；否则使用缩略图
          final imageFilePath = item.filePath;
          if (imageFilePath?.isNotEmpty ?? false) {
            // 解析为绝对路径
            final absolutePath = await _resolveAbsoluteFilePath(imageFilePath!);
            await _setClipboardFile(absolutePath);
          } else {
            final thumb = item.thumbnail;
            if (thumb != null && thumb.isNotEmpty) {
              await _setClipboardImage(Uint8List.fromList(thumb));
            }
          }
        case ClipType.file:
          // 文件类型：使用原生文件复制
          final fileFilePath = item.filePath;
          if (fileFilePath?.isNotEmpty ?? false) {
            // 解析为绝对路径
            final absolutePath = await _resolveAbsoluteFilePath(fileFilePath!);
            await _setClipboardFile(absolutePath);
          } else {
            // 回退到文本复制
            final text = item.content ?? '';
            await Clipboard.setData(ClipboardData(text: text));
            _lastClipboardContent = text;
          }
        case ClipType.html:
          // HTML 富文本：写入原生 HTML 类型，失败时回退为纯文本
          {
            final text = item.content ?? '';
            await _setClipboardRichText('html', text);
            _lastClipboardContent = text;
          }
        case ClipType.rtf:
          // RTF 富文本：写入原生 RTF 类型，失败时回退为纯文本
          {
            final text = item.content ?? '';
            await _setClipboardRichText('rtf', text);
            _lastClipboardContent = text;
          }
        case ClipType.text:
        case ClipType.color:
        case ClipType.audio:
        case ClipType.video:
        case ClipType.url:
        case ClipType.email:
        case ClipType.json:
        case ClipType.xml:
        case ClipType.code:
          // 文本/其他类型：按新模型使用字符串 content
          final text = item.content ?? '';
          await Clipboard.setData(ClipboardData(text: text));
          _lastClipboardContent = text;
      }
    } on Exception catch (e) {
      await Log.e('Failed to set clipboard content: $e');
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

  Future<void> _setClipboardFile(String filePath) async {
    try {
      await _platformChannel.invokeMethod('setClipboardFile', {
        'filePath': filePath,
      });
    } on Exception catch (_) {
      // 处理错误
    }
  }

  /// 写入富文本到系统剪贴板（HTML/RTF），失败则回退为纯文本
  Future<void> _setClipboardRichText(String type, String content) async {
    try {
      await _platformChannel.invokeMethod('setRichTextData', {
        'type': type,
        'content': content,
      });
    } on Exception catch (_) {
      await Clipboard.setData(ClipboardData(text: content));
    }
  }

  /// 解析相对路径为绝对路径
  Future<String> _resolveAbsoluteFilePath(String filePath) async {
    // 如果已经是绝对路径，直接返回
    if (filePath.startsWith('/')) {
      return filePath;
    }

    // 解析相对路径为绝对路径
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return '${documentsDirectory.path}/$filePath';
    } on Exception catch (e) {
      await Log.e('Failed to resolve absolute file path: $e');
      return filePath; // 回退到原路径
    }
  }

  /// 判断是否为图片文件（封装 ImageUtils.isImageFile）
  bool _isImageFile(String filePath) {
    try {
      return ImageUtils.isImageFile(filePath);
    } on Exception catch (_) {
      return false;
    }
  }

  /// 根据图片二进制内容推断扩展名
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

  /// 将媒体（二进制）保存到磁盘并返回相对路径（media/...）
  Future<String> _saveMediaToDisk({
    required Uint8List bytes,
    required String type, // 'image' 或 'file'
    String? suggestedExt,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // 生成文件名：类型_时间戳_哈希前8位.扩展名
      final ext = (suggestedExt ?? 'bin').toLowerCase();
      final hash = sha256.convert(bytes).toString().substring(0, 8);
      final fileName = '${type}_${ts}_$hash.$ext';

      // 构建绝对目录与相对路径
      final relativeDir = type == 'image' ? 'media/images' : 'media/files';
      final absoluteDir = '${dir.path}/$relativeDir';
      final absolutePath = '$absoluteDir/$fileName';
      final relativePath = '$relativeDir/$fileName';

      // 确保目录存在
      final d = Directory(absoluteDir);
      if (!d.existsSync()) {
        await d.create(recursive: true);
      }

      // 写入文件
      final f = File(absolutePath);
      await f.writeAsBytes(bytes, flush: true);

      return relativePath;
    } on Exception catch (e) {
      unawaited(
        Log.w('Failed to save media to disk', tag: 'clipboard', error: e),
      );
      return '';
    }
  }
}
