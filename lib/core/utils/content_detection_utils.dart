import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:clip_flow_pro/core/utils/file_type_utils.dart';

/// 内容检测工具类
///
/// 提供统一的内容类型检测和文本分析功能，避免在多个地方重复实现
class ContentDetectionUtils {
  ContentDetectionUtils._(); // 私有构造函数，防止实例化

  // ==================== 文本分析工具 ====================

  /// 特殊字符列表（用于快速判断是否可能为纯文本）
  static const List<String> _specialChars = [
    '<',
    '>',
    '{',
    '}',
    '[',
    ']',
    '(',
    ')',
    ';',
    ':',
    '=',
    '/',
    r'\',
    '#',
    '@',
    r'$',
    '`',
  ];

  /// 判断是否很可能为纯文本（不包含代码/HTML常见符号）
  ///
  /// 快速字符扫描，避免昂贵的正则与多分析器匹配
  static bool isLikelyPlainText(String content) {
    for (final ch in _specialChars) {
      if (content.contains(ch)) return false;
    }
    if (content.contains('http://') || content.contains('https://')) {
      return false;
    }
    return true;
  }

  /// 检查文本是否包含特殊字符
  static bool containsSpecialChars(String content) {
    return _specialChars.any((char) => content.contains(char));
  }

  /// 检查文本是否包含URL
  static bool containsUrl(String content) {
    return content.contains('http://') || content.contains('https://');
  }

  /// 检查是否为文件路径
  static bool isFilePath(String content) {
    final cleanContent = content.trim();

    // 0. 首先排除明显的代码内容
    if (isCodeContent(cleanContent)) {
      return false;
    }

    // 1. 明确的路径标识符
    if (cleanContent.contains('/') ||
        cleanContent.contains(r'\') ||
        cleanContent.startsWith('./') ||
        cleanContent.startsWith('../') ||
        cleanContent.contains('file://')) {
      return _isValidPathStructure(cleanContent);
    }

    // 2. 检查是否有文件扩展名
    final extensionPattern = RegExp(r'\.[a-zA-Z0-9]{1,10}$');
    final hasExtension = extensionPattern.hasMatch(cleanContent);

    if (hasExtension) {
      // 避免误判其他带点的内容
      final lowerContent = cleanContent.toLowerCase();

      // 排除常见的非文件名模式
      if (_isNonFilePattern(lowerContent)) {
        return false;
      }

      // 使用统一的文件类型工具类检查扩展名
      final extension = FileTypeUtils.extractExtension(cleanContent);
      final isCommonExtension = FileTypeUtils.isCommonFile(extension);
      final isMediaFile = FileTypeUtils.isImageFile(extension) ||
                         FileTypeUtils.isVideoFile(extension) ||
                         FileTypeUtils.isAudioFile(extension);

      // 对于代码文件扩展名，需要更严格的检查
      if (FileTypeUtils.isCodeFile(extension)) {
        if (hasCodeFeatures(cleanContent)) {
          return false;
        }
      }

      return isCommonExtension || isMediaFile;
    }

    return false;
  }

  /// 检查是否为代码内容
  static bool isCodeContent(String content) {
    return hasCodeFeatures(content);
  }

  /// 检查内容是否包含代码特征
  static bool hasCodeFeatures(String content) {
    final codePatterns = [
      // 编程语言关键字
      RegExp(
        r'\b(import|export|from|as|function|class|const|let|var|def|if|else|for|while|return|public|private|static|async|await|try|catch|throw|new|this|super)\b',
      ),
      // 函数定义模式
      RegExp(r'\w+\s*\([^)]*\)\s*[{=>]'),
      // 类定义模式
      RegExp(r'\bclass\s+\w+'),
      // 导入语句
      RegExp(r'''import\s+['"][^'"]*['"]'''),
      // 注释
      RegExp(r'//.*$|/\*[\s\S]*?\*/'),
      // 字符串字面量
      RegExp('''['"][^'"]*['"]'''),
      // 代码块特征
      RegExp(r'[{}[\]()]'),
      // 赋值操作
      RegExp(r'\w+\s*=\s*[^;]'),
    ];

    var codeFeatureCount = 0;
    for (final pattern in codePatterns) {
      if (pattern.hasMatch(content)) {
        codeFeatureCount++;
      }
    }

    // 如果匹配超过2个代码特征，认为是代码
    return codeFeatureCount >= 2;
  }

  /// 检查是否为URL
  static bool isURL(String content) {
    return content.startsWith('http://') ||
        content.startsWith('https://') ||
        content.startsWith('ftp://') ||
        content.startsWith('www.');
  }

  /// 检查是否为邮箱
  static bool isEmail(String content) {
    return content.contains('@') &&
        content.contains('.') &&
        !content.contains(' ');
  }

  /// 检查是否为颜色值
  static bool isColor(String content) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('#') &&
        !trimmed.startsWith('rgb(') &&
        !trimmed.startsWith('rgba(') &&
        !trimmed.startsWith('hsl(') &&
        !trimmed.startsWith('hsla(')) {
      return false;
    }

    return ColorUtils.isColorValue(trimmed);
  }

  /// 检查是否为JSON
  static bool isJSON(String content) {
    final trimmed = content.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  /// 检查是否为XML
  static bool isXML(String content) {
    return content.contains('<') &&
        content.contains('>') &&
        (content.contains('</') || content.contains('/>'));
  }

  /// 检查是否为结构化数据（可能是代码）
  static bool isStructuredData(String content) {
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
  static bool isTerminalLog(String content) {
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

  /// 从HTML中提取纯文本
  static String extractTextFromHtml(String html) {
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
  static String extractTextFromRtf(String rtf) {
    return rtf
        .replaceAll(RegExp(r'\\[a-zA-Z]+\d*'), ' ')
        .replaceAll(RegExp('[{}]'), '')
        .replaceAll(RegExp(r'\\[^a-zA-Z]'), '')
        .trim();
  }

  /// 检查是否为非文件名模式
  static bool _isNonFilePattern(String content) {
    return content.contains('http://') ||
        content.contains('https://') ||
        content.contains('ftp://') ||
        content.contains('@') ||
        content.startsWith('192.168.') ||
        content.startsWith('10.') ||
        content.contains('.0.') ||
        RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(content);
  }

  /// 验证路径结构是否有效
  static bool _isValidPathStructure(String content) {
    // 检查是否看起来像有效的路径
    if (content.contains(RegExp(r'[{}[\]();=<>]'))) {
      return false;
    }

    final parts = content.split(RegExp(r'[\\/]'));

    // 路径不应该太短
    if (parts.length < 2 && content.length < 10) {
      return false;
    }

    return true;
  }
}
