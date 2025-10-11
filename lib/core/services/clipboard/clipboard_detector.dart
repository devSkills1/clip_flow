import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/analysis/code_analyzer.dart';
import 'package:clip_flow_pro/core/services/analysis/content_analyzer.dart';
import 'package:clip_flow_pro/core/services/analysis/html_analyzer.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';

/// 剪贴板内容类型检测器
///
/// 使用基于置信度评分的检测系统，而非依赖检测顺序
/// 每个分析器独立评估内容，返回置信度分数，最终由决策引擎选择最合适的类型
class ClipboardDetector {
  /// 构造函数
  ///
  /// 初始化所有分析器
  ClipboardDetector() {
    _initializeAnalyzers();
  }

  late final List<ContentAnalyzer> _analyzers;

  // 置信度阈值配置
  static const double _minimumConfidence = 0.3;
  static const double _highConfidence = 0.8;

  /// 初始化所有分析器
  void _initializeAnalyzers() {
    _analyzers = [
      // 精确匹配类型 - 这些类型有明确的格式特征
      ColorAnalyzer(),
      RtfAnalyzer(),
      UrlAnalyzer(),
      EmailAnalyzer(),
      JsonAnalyzer(),
      XmlAnalyzer(),
      FilePathAnalyzer(),

      // 复杂类型 - 需要更复杂的分析
      CodeAnalyzer(),
      HtmlAnalyzer(),
    ];
  }

  /// 检测内容类型
  ClipType detectContentType(String content) {
    if (content.isEmpty) return ClipType.text;

    // 大文本快速路径：如果内容很大且明显是纯文本（不含代码/HTML常见符号），直接判定为文本
    if (content.length > 8000 && _likelyPlainText(content)) {
      return ClipType.text;
    }

    // 运行所有分析器
    final results = <AnalysisResult>[];
    for (final analyzer in _analyzers) {
      try {
        final result = analyzer.analyze(content);
        if (result.confidence > 0.0) {
          results.add(result);
        }
      } on Exception catch (e) {
        // 记录错误但继续处理
        Log.w(
          'Analysis error during content type detection',
          tag: 'clipboard_detector',
          error: e,
        );
      }
    }

    // 使用决策引擎选择最佳类型
    return _makeDecision(results, content);
  }

  /// 决策引擎 - 基于置信度分数和规则选择最合适的类型
  ClipType _makeDecision(List<AnalysisResult> results, String content) {
    if (results.isEmpty) {
      return ClipType.text;
    }

    // 按置信度排序
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    final topResult = results.first;

    // 如果最高置信度低于最小阈值，返回文本类型
    if (topResult.confidence < _minimumConfidence) {
      return ClipType.text;
    }

    // 如果最高置信度很高，直接返回
    if (topResult.confidence >= _highConfidence) {
      return topResult.type;
    }

    // 中等置信度情况下，需要进行冲突解决
    return _resolveConflicts(results, content);
  }

  /// 冲突解决 - 当多个类型都有一定置信度时的决策逻辑
  ClipType _resolveConflicts(List<AnalysisResult> results, String content) {
    final topResult = results.first;

    // 如果只有一个结果，直接返回
    if (results.length == 1) {
      return topResult.type;
    }

    // 检查是否有多个高置信度结果
    final highConfidenceResults = results
        .where((r) => r.confidence >= _minimumConfidence)
        .toList();

    if (highConfidenceResults.length == 1) {
      return highConfidenceResults.first.type;
    }

    // 多个结果的冲突解决策略
    return _applyConflictResolutionRules(highConfidenceResults, content);
  }

  /// 应用冲突解决规则
  ClipType _applyConflictResolutionRules(
    List<AnalysisResult> results,
    String content,
  ) {
    final typeConfidenceMap = <ClipType, double>{};
    for (final result in results) {
      typeConfidenceMap[result.type] = result.confidence;
    }

    // 规则1: 精确匹配类型优先
    final preciseTypes = [
      ClipType.color,
      ClipType.url,
      ClipType.email,
      ClipType.json,
      ClipType.rtf,
    ];

    for (final type in preciseTypes) {
      if (typeConfidenceMap.containsKey(type) &&
          typeConfidenceMap[type]! >= _minimumConfidence) {
        return type;
      }
    }

    // 规则2: 代码 vs HTML 冲突解决
    if (typeConfidenceMap.containsKey(ClipType.code) &&
        typeConfidenceMap.containsKey(ClipType.html)) {
      return _resolveCodeHtmlConflict(
        results.firstWhere((r) => r.type == ClipType.code),
        results.firstWhere((r) => r.type == ClipType.html),
        content,
      );
    }

    // 规则3: XML vs HTML 冲突解决
    if (typeConfidenceMap.containsKey(ClipType.xml) &&
        typeConfidenceMap.containsKey(ClipType.html)) {
      // XML 声明存在时优先选择 XML
      if (content.trim().startsWith('<?xml')) {
        return ClipType.xml;
      }
      // 否则比较置信度
      return typeConfidenceMap[ClipType.xml]! >
              typeConfidenceMap[ClipType.html]!
          ? ClipType.xml
          : ClipType.html;
    }

    // 规则4: 文件路径 vs 其他类型
    if (typeConfidenceMap.containsKey(ClipType.file)) {
      final fileResult = results.firstWhere((r) => r.type == ClipType.file);
      // 如果文件路径置信度很高且文件存在，优先选择
      if (fileResult.confidence > 0.8 &&
          fileResult.metadata['exists'] == true) {
        return ClipType.file;
      }
    }

    // 默认返回置信度最高的类型
    return results.first.type;
  }

  /// 解决代码和HTML之间的冲突
  ClipType _resolveCodeHtmlConflict(
    AnalysisResult codeResult,
    AnalysisResult htmlResult,
    String content,
  ) {
    // 检查是否是 JSX/React 代码
    if (htmlResult.metadata['isJsx'] == true) {
      return ClipType.code;
    }

    // 检查是否有完整的 HTML 文档结构
    if (htmlResult.metadata['hasCompleteStructure'] == true) {
      return ClipType.html;
    }

    // 检查代码特征强度
    final codeScore = codeResult.metadata['totalScore'] as double? ?? 0.0;
    final codeLineCount = codeResult.metadata['lineCount'] as int? ?? 1;
    final avgCodeScore = codeScore / codeLineCount;

    // 如果平均代码分数很高，选择代码
    if (avgCodeScore > 2.0) {
      return ClipType.code;
    }

    // 检查 HTML 标签密度
    final tagDensity = htmlResult.metadata['tagDensity'] as double? ?? 0.0;
    if (tagDensity > 0.4) {
      return ClipType.html;
    }

    // 比较置信度差异
    final confidenceDiff = (codeResult.confidence - htmlResult.confidence)
        .abs();
    if (confidenceDiff > 0.2) {
      return codeResult.confidence > htmlResult.confidence
          ? ClipType.code
          : ClipType.html;
    }

    // 默认选择代码（因为现代开发中代码包含HTML标签很常见）
    return ClipType.code;
  }

  /// 检测文件类型（保持原有逻辑）
  ClipType detectFileType(String filePath) {
    const imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'svg',
      'ico',
      'tiff',
      'tif',
    ];

    const audioExtensions = [
      'mp3',
      'wav',
      'flac',
      'aac',
      'ogg',
      'wma',
      'm4a',
      'opus',
    ];

    const videoExtensions = [
      'mp4',
      'avi',
      'mkv',
      'mov',
      'wmv',
      'flv',
      'webm',
      'm4v',
      '3gp',
    ];

    const codeExtensions = [
      'js',
      'ts',
      'jsx',
      'tsx',
      'py',
      'java',
      'cpp',
      'c',
      'h',
      'hpp',
      'cs',
      'go',
      'rs',
      'php',
      'rb',
      'swift',
      'kt',
      'scala',
      'dart',
      'vue',
      'svelte',
      'css',
      'scss',
      'sass',
      'less',
      'sql',
      'sh',
      'bash',
    ];

    const documentExtensions = [
      'html',
      'htm',
      'xml',
      'json',
      'yaml',
      'yml',
      'md',
      'txt',
      'rtf',
    ];

    final extension = _getFileExtension(filePath);

    // 处理无扩展名的特殊文件
    if (extension.isEmpty) {
      final fileName = filePath.split('/').last.split(r'\').last.toLowerCase();
      const specialTextFiles = [
        'readme',
        'makefile',
        'dockerfile',
        'license',
        'changelog',
      ];
      if (specialTextFiles.contains(fileName)) {
        return ClipType.text;
      }
      return ClipType.file;
    }

    if (imageExtensions.contains(extension)) return ClipType.image;
    if (audioExtensions.contains(extension)) return ClipType.audio;
    if (videoExtensions.contains(extension)) return ClipType.video;
    if (codeExtensions.contains(extension)) return ClipType.code;
    if (extension == 'html' || extension == 'htm') return ClipType.html;
    if (extension == 'json') return ClipType.json;
    if (extension == 'xml') return ClipType.xml;
    if (documentExtensions.contains(extension)) return ClipType.text;

    return ClipType.file;
  }

  /// 估算编程语言（保持原有逻辑但改进）
  String estimateLanguage(String content) {
    // 运行代码分析器
    final codeAnalyzer = CodeAnalyzer();
    final result = codeAnalyzer.analyze(content);

    // 如果检测到特定语言，返回该语言
    if (result.metadata.containsKey('detectedLanguage')) {
      return result.metadata['detectedLanguage'] as String;
    }

    // 如果置信度太低，返回文本
    if (result.confidence < _minimumConfidence) {
      return 'text';
    }

    // 默认返回通用代码类型
    return 'code';
  }

  /// 获取文件扩展名
  String _getFileExtension(String filePath) {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filePath.length - 1) {
      return '';
    }
    return filePath.substring(lastDotIndex + 1).toLowerCase();
  }

  /// 获取分析详情（用于调试和测试）
  Map<String, dynamic> getAnalysisDetails(String content) {
    final results = <Map<String, dynamic>>[];

    for (final analyzer in _analyzers) {
      try {
        final result = analyzer.analyze(content);
        results.add({
          'type': result.type.toString().split('.').last,
          'confidence': result.confidence,
          'metadata': result.metadata,
        });
      } on Exception catch (e) {
        results.add({
          'type': analyzer.supportedType.toString().split('.').last,
          'confidence': 0.0,
          'metadata': {'error': e.toString()},
        });
      }
    }

    final decision = detectContentType(content);

    return {
      'results': results,
      'decision': decision.toString().split('.').last,
    };
  }
}

/// 判断是否很可能为纯文本（不包含代码/HTML常见符号）
bool _likelyPlainText(String content) {
  // 快速字符扫描，避免昂贵的正则与多分析器匹配
  const specialChars = [
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
  for (final ch in specialChars) {
    if (content.contains(ch)) return false;
  }
  if (content.contains('http://') || content.contains('https://')) {
    return false;
  }
  return true;
}
