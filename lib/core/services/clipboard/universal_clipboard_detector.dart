import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard/index.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';

/// 通用剪贴板检测器
///
/// 统一处理跨平台的剪贴板类型检测，确保"复制什么保存什么"
class UniversalClipboardDetector {
  /// 工厂方法
  factory UniversalClipboardDetector() => _instance;
  UniversalClipboardDetector._internal()
    : _contentDetector = ClipboardDetector();

  /// 单例实例
  static final UniversalClipboardDetector _instance =
      UniversalClipboardDetector._internal();

  /// 内部检测器
  final ClipboardDetector _contentDetector;

  /// 初始化
  void initialize() {
    // 不需要重复初始化，因为 _contentDetector 在构造函数中已经初始化
  }

  /// 检测剪贴板数据的真实类型和最佳内容
  Future<ClipboardDetectionResult> detect(ClipboardData data) async {
    try {
      await Log.i(
        'Starting universal clipboard detection',
        tag: 'UniversalClipboardDetector',
        fields: {
          'availableFormats': data.availableFormats
              .map((f) => f.value)
              .toList(),
          'sequence': data.sequence,
        },
      );

      // 1. 分析所有可用格式
      final formatAnalysis = _analyzeFormats(data);

      // 2. 检测内容的真实类型
      final contentType = await _detectActualContentType(data, formatAnalysis);

      // 3. 确定要保存的内容
      final contentToSave = _determineContentToSave(
        data,
        contentType,
        formatAnalysis,
      );

      // 4. 创建结果
      final result = ClipboardDetectionResult(
        detectedType: contentType,
        contentToSave: contentToSave,
        originalData: data,
        confidence: _calculateConfidence(contentType, formatAnalysis),
        formatAnalysis: formatAnalysis,
      );

      await Log.i(
        'Universal clipboard detection completed',
        tag: 'UniversalClipboardDetector',
        fields: {
          'detectedType': contentType.name,
          'contentType': contentToSave.runtimeType.toString(),
          'confidence': result.confidence,
          'saveOriginal': result.shouldSaveOriginal,
        },
      );

      return result;
    } on Exception catch (e) {
      await Log.e(
        'Universal clipboard detection failed',
        tag: 'UniversalClipboardDetector',
        error: e,
      );

      // 降级到文本类型
      return const ClipboardDetectionResult(
        detectedType: ClipType.text,
        contentToSave: '',
        originalData: null,
        confidence: 0.1,
        formatAnalysis: {},
        shouldSaveOriginal: true,
      );
    }
  }

  /// 分析所有可用格式
  Map<ClipboardFormat, FormatInfo> _analyzeFormats(ClipboardData data) {
    final analysis = <ClipboardFormat, FormatInfo>{};

    for (final format in data.availableFormats) {
      final content = data.formats[format];
      final info = FormatInfo(
        format: format,
        content: content,
        size: _getContentSize(content),
        isValid: _isValidContent(content),
        metadata: _extractFormatMetadata(format, content),
      );

      analysis[format] = info;
    }

    return analysis;
  }

  /// 检测内容的真实类型
  Future<ClipType> _detectActualContentType(
    ClipboardData data,
    Map<ClipboardFormat, FormatInfo> formatAnalysis,
  ) async {
    // 1. 明确的文件类型
    if (formatAnalysis.containsKey(ClipboardFormat.files)) {
      return ClipType.file;
    }

    // 2. 明确的图片类型
    if (formatAnalysis.containsKey(ClipboardFormat.image)) {
      return ClipType.image;
    }

    // 3. 明确的音频类型
    if (formatAnalysis.containsKey(ClipboardFormat.audio)) {
      return ClipType.audio;
    }

    // 4. 明确的视频类型
    if (formatAnalysis.containsKey(ClipboardFormat.video)) {
      return ClipType.video;
    }

    // 5. 文本类型检测 - 这是关键
    return _detectTextualContent(data, formatAnalysis);
  }

  /// 检测文本内容的真实类型
  Future<ClipType> _detectTextualContent(
    ClipboardData data,
    Map<ClipboardFormat, FormatInfo> formatAnalysis,
  ) async {
    String? bestTextContent;
    ClipboardFormat? bestTextFormat;

    // 按优先级选择最佳文本内容
    final textFormats = [
      ClipboardFormat.text,
      ClipboardFormat.html,
      ClipboardFormat.rtf,
    ];

    for (final format in textFormats) {
      if (formatAnalysis.containsKey(format)) {
        final info = formatAnalysis[format]!;
        if (info.isValid) {
          // 如果是HTML或RTF，尝试提取纯文本
          String? plainText;
          if (format == ClipboardFormat.html) {
            plainText = _extractTextFromHtml(info.content.toString());
          } else if (format == ClipboardFormat.rtf) {
            plainText = _extractTextFromRtf(info.content.toString());
          } else {
            plainText = info.content.toString();
          }

          if (plainText.isNotEmpty) {
            bestTextContent = plainText;
            bestTextFormat = format;
            break;
          }
        }
      }
    }

    if (bestTextContent == null || bestTextContent.isEmpty) {
      return ClipType.text;
    }

    // 简化的类型检测逻辑
    final detectedType = _detectSimplifiedContentType(
      bestTextContent,
      bestTextFormat,
    );

    await Log.i(
      'Simplified content detection',
      tag: 'UniversalClipboardDetector',
      fields: {
        'originalFormat': bestTextFormat?.value,
        'detectedType': detectedType.name,
        'contentLength': bestTextContent.length,
        'contentPreview': bestTextContent.length > 50
            ? '${bestTextContent.substring(0, 50)}...'
            : bestTextContent,
      },
    );

    return detectedType;
  }

  /// 简化的内容类型检测
  ///
  /// 基于优先级的检测逻辑，避免对短文本的过度分析
  ClipType _detectSimplifiedContentType(
    String content,
    ClipboardFormat? originalFormat,
  ) {
    // 1. 如果是富文本格式，先提取纯文本内容再检测
    String? plainTextContent;
    if (originalFormat == ClipboardFormat.html) {
      plainTextContent = _extractTextFromHtml(content);
    } else if (originalFormat == ClipboardFormat.rtf) {
      plainTextContent = _extractTextFromRtf(content);
    }

    // 使用纯文本内容进行检测
    final contentToAnalyze = plainTextContent ?? content;

    // 2. 对于终端日志和简短的富文本，直接判断为文本
    if (originalFormat == ClipboardFormat.html) {
      // 检查是否是终端日志的特征
      if (_isTerminalLog(contentToAnalyze) || contentToAnalyze.length < 50) {
        return ClipType.text;
      }
    }

    // 3. 对于所有文本，首先检查文件路径（优先级最高）
    final isFilePath = _isFilePath(contentToAnalyze);
    Log.d(
      'File path detection: content=$contentToAnalyze, length=${contentToAnalyze.length}, isFilePath=$isFilePath',
      tag: 'UniversalClipboardDetector',
    );
    if (isFilePath) return ClipType.file;

    // 4. 对于短文本（<20字符），只进行基本检查
    if (contentToAnalyze.length < 20) {
      if (_isURL(contentToAnalyze)) return ClipType.url;
      if (_isEmail(contentToAnalyze)) return ClipType.email;
      if (_isColor(contentToAnalyze)) return ClipType.color;

      // 其他短文本默认为普通文本，避免过度分析
      return ClipType.text;
    }

    // 5. 对于中等长度文本（20-200字符），进行基本检测
    if (content.length <= 200) {
      if (_isJSON(content)) return ClipType.json;
      if (_isXML(content)) return ClipType.xml;
      if (_isStructuredData(content)) return ClipType.code;

      return ClipType.text;
    }

    // 4. 对于长文本（>200字符），进行完整检测
    return _contentDetector.detectContentType(content);
  }

  /// 检查是否为文件路径
  bool _isFilePath(String content) {
    // 清理内容：移除前后空白字符
    final cleanContent = content.trim();

    // 1. 明确的路径标识符
    if (cleanContent.contains('/') ||
        cleanContent.contains(r'\') ||
        cleanContent.startsWith('./') ||
        cleanContent.startsWith('../') ||
        cleanContent.contains('file://')) {
      return true;
    }

    // 2. 检查是否有文件扩展名（如 .sh, .txt, .pdf, .jpg 等）
    final extensionPattern = RegExp(r'\.[a-zA-Z0-9]{1,10}$');
    final hasExtension = extensionPattern.hasMatch(cleanContent);

    // 同步日志记录
    Log.d(
      'File path detection analysis: content="$cleanContent", hasExtension=$hasExtension',
      tag: 'UniversalClipboardDetector',
    );
    Log.d(
      'Content details: length=${cleanContent.length}, endsWith=".sh":${cleanContent.endsWith(".sh")}, endsWith=".dart":${cleanContent.endsWith(".dart")}',
      tag: 'UniversalClipboardDetector',
    );

    if (hasExtension) {
      // 避免误判其他带点的内容（如版本号、IP地址等）
      final lowerContent = cleanContent.toLowerCase();

      // 排除常见的非文件名模式
      if (lowerContent.contains('http://') ||
          lowerContent.contains('https://') ||
          lowerContent.contains('ftp://') ||
          lowerContent.contains('@') || // 邮箱
          lowerContent.startsWith('192.168.') || // IP地址
          lowerContent.startsWith('10.') || // IP地址
          lowerContent.contains('.0.') || // 版本号模式
          RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(lowerContent)) { // 完整IP地址
        Log.d(
      'Content excluded as non-file pattern: $cleanContent',
      tag: 'UniversalClipboardDetector',
    );
        return false;
      }

      // 检查是否是常见的文件扩展名
      final commonExtensions = {
        'sh', 'bash', 'zsh', 'fish', 'py', 'js', 'ts', 'java', 'cpp', 'c', 'h',
        'hpp', 'txt', 'md', 'doc', 'docx', 'pdf', 'rtf', 'html', 'htm', 'xml',
        'json', 'yaml', 'yml', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg',
        'webp', 'ico', 'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm',
        'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'zip', 'rar', 'tar', 'gz',
        '7z', 'bz2', 'xz', 'exe', 'msi', 'dmg', 'pkg', 'deb', 'rpm', 'apk',
        'ipa', 'sql', 'db', 'sqlite', 'csv', 'xls', 'xlsx', 'ppt', 'pptx',
        'log', 'conf', 'config', 'ini', 'env', 'gitignore', 'dockerfile',
        'css', 'scss', 'sass', 'less', 'vue', 'jsx', 'tsx', 'svelte'
      };

      final extension = cleanContent.split('.').last.toLowerCase();
      final isCommonExtension = commonExtensions.contains(extension);

      Log.d(
      'File extension check result: content=$cleanContent, extension=$extension, isCommonExtension=$isCommonExtension',
      tag: 'UniversalClipboardDetector',
    );

      return isCommonExtension;
    }

    return false;
  }

  /// 检查是否为URL
  bool _isURL(String content) {
    return content.startsWith('http://') ||
        content.startsWith('https://') ||
        content.startsWith('ftp://') ||
        content.startsWith('www.');
  }

  /// 检查是否为邮箱
  bool _isEmail(String content) {
    return content.contains('@') &&
        content.contains('.') &&
        !content.contains(' ');
  }

  /// 检查是否为颜色值
  bool _isColor(String content) {
    return content.startsWith('#') ||
        content.startsWith('rgb(') ||
        content.startsWith('rgba(') ||
        content.startsWith('hsl(') ||
        content.startsWith('hsla(');
  }

  /// 检查是否为JSON
  bool _isJSON(String content) {
    final trimmed = content.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  /// 检查是否为XML
  bool _isXML(String content) {
    return content.contains('<') &&
        content.contains('>') &&
        (content.contains('</') || content.contains('/>'));
  }

  /// 检查是否为结构化数据（可能是代码）
  bool _isStructuredData(String content) {
    // 检查常见的代码特征
    return content.contains('function ') ||
        content.contains('class ') ||
        content.contains('import ') ||
        content.contains('export ') ||
        content.contains('const ') ||
        content.contains('let ') ||
        content.contains('var ') ||
        content.contains('def ') ||
        content.contains('public ') ||
        content.contains('private ') ||
        content.contains('=>') ||
        content.contains('&&') ||
        content.contains('||') ||
        content.contains('==') ||
        content.contains('!=');
  }

  /// 检查是否为终端日志
  bool _isTerminalLog(String content) {
    // 检查常见的终端日志特征
    final terminalPatterns = [
      // 命令提示符模式
      RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+[~/$][^$]*\$'),
      // Windows命令提示符
      RegExp(r'^[A-Za-z]:\\.*>'),
      // Git分支信息
      RegExp(r'\(.*?\).*\$'),
      // 时间戳格式
      RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'),
      // 日志级别
      RegExp(r'\b(DEBUG|INFO|WARN|ERROR|FATAL|TRACE)\b', caseSensitive: false),
      // 进程信息
      RegExp(r'\[\d+\]'),
      // 常见终端命令
      RegExp(
        r'\b(cd|ls|pwd|echo|cat|grep|find|npm|yarn|flutter|dart|git|mvn|gradle|make|cmake|go|python|node|java|javac)\b',
      ),
      // 路径信息
      RegExp(r'^/[^/]+.*$'),
      // 错误信息模式
      RegExp(
        r'\b(error:|warning:|failed:|success:|exception:)\b',
        caseSensitive: false,
      ),
    ];

    // 如果匹配任何终端模式，认为是终端日志
    for (final pattern in terminalPatterns) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }

    // 检查是否包含大量特殊字符（终端输出特征）
    final specialCharCount = content
        .replaceAll(RegExp(r'[a-zA-Z0-9\s\n\r]'), '')
        .length;
    if (specialCharCount > content.length * 0.1) {
      return true;
    }

    return false;
  }

  /// 确定要保存的内容
  dynamic _determineContentToSave(
    ClipboardData data,
    ClipType detectedType,
    Map<ClipboardFormat, FormatInfo> formatAnalysis,
  ) {
    // 对于非文本类型，直接保存原始内容
    if (detectedType != ClipType.text &&
        detectedType != ClipType.code &&
        detectedType != ClipType.html &&
        detectedType != ClipType.xml &&
        detectedType != ClipType.json) {
      return _getOriginalContent(data, detectedType);
    }

    // 对于文本类型，优先保存纯文本版本
    if (formatAnalysis.containsKey(ClipboardFormat.text)) {
      return formatAnalysis[ClipboardFormat.text]!.content;
    }

    // 如果没有纯文本，从HTML/RTF中提取
    if (formatAnalysis.containsKey(ClipboardFormat.html)) {
      return _extractTextFromHtml(
        formatAnalysis[ClipboardFormat.html]!.content.toString(),
      );
    }

    if (formatAnalysis.containsKey(ClipboardFormat.rtf)) {
      return _extractTextFromRtf(
        formatAnalysis[ClipboardFormat.rtf]!.content.toString(),
      );
    }

    // 降级处理
    return data.bestContent.toString();
  }

  /// 获取原始内容（非文本类型）
  dynamic _getOriginalContent(ClipboardData data, ClipType type) {
    switch (type) {
      case ClipType.image:
        // 图片类型返回图片字节数据
        return data.getFormat<List<int>>(ClipboardFormat.image);
      case ClipType.file:
        return data.getFormat<List<String>>(ClipboardFormat.files);
      case ClipType.audio:
      case ClipType.video:
        return data.getFormat<String>(ClipboardFormat.files);
      case ClipType.text:
      case ClipType.rtf:
      case ClipType.html:
      case ClipType.color:
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
        return data.bestContent;
    }
  }

  /// 计算检测置信度
  double _calculateConfidence(
    ClipType detectedType,
    Map<ClipboardFormat, FormatInfo> formatAnalysis,
  ) {
    // 对于明确的格式类型，高置信度
    if (detectedType == ClipType.image ||
        detectedType == ClipType.file ||
        detectedType == ClipType.audio ||
        detectedType == ClipType.video) {
      return 0.95;
    }

    // 对于文本类型，根据格式数量计算置信度
    final textFormats = formatAnalysis.keys
        .where(
          (format) =>
              format == ClipboardFormat.text ||
              format == ClipboardFormat.html ||
              format == ClipboardFormat.rtf,
        )
        .length;

    return textFormats > 1 ? 0.85 : 0.75;
  }

  /// 获取内容大小
  int _getContentSize(dynamic content) {
    if (content is String) return content.length;
    if (content is List) return content.length;
    if (content is Map) return content.length;
    return 0;
  }

  /// 检查内容是否有效
  bool _isValidContent(dynamic content) {
    if (content == null) return false;
    if (content is String) return content.isNotEmpty;
    if (content is List) return content.isNotEmpty;
    if (content is Map) return content.isNotEmpty;
    return true;
  }

  /// 提取格式元数据
  Map<String, dynamic> _extractFormatMetadata(
    ClipboardFormat format,
    dynamic content,
  ) {
    final metadata = <String, dynamic>{
      'format': format.value,
      'size': _getContentSize(content),
    };

    if (format == ClipboardFormat.html && content is String) {
      metadata['hasHtmlTags'] = RegExp('<[^>]+>').hasMatch(content);
      metadata['isHtmlFragment'] = !content.contains('<html');
    }

    return metadata;
  }

  /// 从HTML中提取纯文本
  String _extractTextFromHtml(String html) {
    return html
        .replaceAll(RegExp('<[^>]*>'), '')
        .replaceAll(RegExp('&lt;'), '<')
        .replaceAll(RegExp('&gt;'), '>')
        .replaceAll(RegExp('&amp;'), '&')
        .replaceAll(RegExp('&nbsp;'), ' ')
        .replaceAll(RegExp('&quot;'), '"')
        .trim();
  }

  /// 从RTF中提取纯文本（简单实现）
  String _extractTextFromRtf(String rtf) {
    // 简单的RTF文本提取 - 移除RTF控制字符
    return rtf
        .replaceAll(RegExp(r'\\[a-zA-Z]+\d*'), ' ')
        .replaceAll(RegExp('[{}]'), '')
        .replaceAll(RegExp(r'\\[^a-zA-Z]'), '')
        .trim();
  }
}

/// 格式信息
class FormatInfo {
  /// 构造器
  const FormatInfo({
    required this.format,
    required this.content,
    required this.size,
    required this.isValid,
    required this.metadata,
  });

  /// 剪贴板格式类型
  final ClipboardFormat format;

  /// 格式内容
  final dynamic content;

  /// 内容大小
  final int size;

  /// 内容是否有效
  final bool isValid;

  /// 格式元数据
  final Map<String, dynamic> metadata;
}

/// 剪贴板检测结果
class ClipboardDetectionResult {
  /// 创建检测结果实例
  const ClipboardDetectionResult({
    required this.detectedType,
    required this.contentToSave,
    required this.originalData,
    required this.confidence,
    required this.formatAnalysis,
    this.shouldSaveOriginal = false,
    this.ocrText,
  });

  /// 检测到的剪贴板内容类型
  final ClipType detectedType;

  /// 要保存的内容
  final dynamic contentToSave;

  /// 原始剪贴板数据
  final ClipboardData? originalData;

  /// 检测置信度（0-1）
  final double confidence;

  /// 格式分析结果
  final Map<ClipboardFormat, FormatInfo> formatAnalysis;

  /// 是否保存原始数据
  final bool shouldSaveOriginal;

  /// OCR识别的文本（图片类型）
  final String? ocrText;

  /// 创建ClipItem
  ClipItem createClipItem({String? id}) {
    return ClipItem(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: detectedType,
      content: _getContentForClipItem(),
      filePath: _extractFilePath(),
      thumbnail: _extractThumbnail(),
      metadata: _buildMetadata(),
      ocrText: ocrText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 获取用于ClipItem的内容
  String? _getContentForClipItem() {
    // 对于非文本类型，内容通常为空
    if (detectedType == ClipType.image ||
        detectedType == ClipType.file ||
        detectedType == ClipType.audio ||
        detectedType == ClipType.video) {
      return '';
    }

    // 对于文本类型，返回要保存的内容
    return contentToSave?.toString();
  }

  String? _extractFilePath() {
    if (originalData == null) return null;

    if (detectedType == ClipType.file) {
      final files = originalData!.getFormat<List<String>>(
        ClipboardFormat.files,
      );
      return files?.isNotEmpty ?? false ? files!.first : null;
    }
    // 图片类型也需要从原数据中获取路径信息
    if (detectedType == ClipType.image) {
      final files = originalData!.getFormat<List<String>>(
        ClipboardFormat.files,
      );
      return files?.isNotEmpty ?? false ? files!.first : null;
    }
    return null;
  }

  List<int>? _extractThumbnail() {
    if (originalData == null) return null;

    if (detectedType == ClipType.image) {
      // 直接从原数据中获取图片数据作为缩略图
      final imageData = originalData!.getFormat<List<int>>(
        ClipboardFormat.image,
      );
      return imageData;
    }
    return null;
  }

  Map<String, dynamic> _buildMetadata() {
    if (originalData == null) {
      return {
        'confidence': confidence,
        'availableFormats': <String>[],
        'sequence': 0,
        'formatAnalysis': <String, dynamic>{},
      };
    }

    return {
      'confidence': confidence,
      'availableFormats': originalData!.availableFormats
          .map((f) => f.value)
          .toList(),
      'sequence': originalData!.sequence,
      'formatAnalysis': formatAnalysis.map(
        (k, v) => MapEntry(k.value, v.metadata),
      ),
    };
  }
}
