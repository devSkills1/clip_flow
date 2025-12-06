import 'dart:async';

import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/models/clipboard_detection_result.dart';
import 'package:clip_flow/core/models/clipboard_format_info.dart';
import 'package:clip_flow/core/services/analysis/index.dart';
import 'package:clip_flow/core/services/clipboard/clipboard_data.dart';
import 'package:clip_flow/core/services/observability/index.dart';
import 'package:clip_flow/core/utils/content_detection_utils.dart';
import 'package:clip_flow/core/utils/file_type_utils.dart';

/// 剪贴板内容类型检测器
///
/// 统一处理剪贴板内容检测，包括：
/// - 基于置信度评分的文本内容类型检测
/// - 跨平台剪贴板格式分析
/// - 文件、图片、音频、视频等二进制内容检测
/// - 返回详细的检测结果和格式信息
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

  /// 初始化检测器（保持向后兼容）
  void initialize() {
    // 检测器在构造函数中已经初始化，这里保持接口兼容性
  }

  /// 检测内容类型
  ClipType detectContentType(String content) {
    if (content.isEmpty) return ClipType.text;

    // 大文本快速路径：如果内容很大且明显是纯文本（不含代码/HTML常见符号），直接判定为文本
    if (content.length > 8000 && ContentDetectionUtils.isLikelyPlainText(content)) {
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
        unawaited(Log.w(
          'Analysis error during content type detection',
          tag: 'clipboard_detector',
          error: e,
        ));
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

  /// 检测文件类型（使用统一的 FileTypeUtils）
  ClipType detectFileType(String filePath) {
    return FileTypeUtils.detectFileTypeByExtension(filePath);
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

  // ==================== 跨平台剪贴板检测功能 ====================

  /// 检测剪贴板数据的真实类型和最佳内容
  ///
  /// 统一处理跨平台的剪贴板类型检测，确保"复制什么保存什么"
  Future<ClipboardDetectionResult> detect(ClipboardData data) async {
    try {
      await Log.i(
        'Starting unified clipboard detection',
        tag: 'ClipboardDetector',
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
        'Unified clipboard detection completed',
        tag: 'ClipboardDetector',
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
        'Unified clipboard detection failed',
        tag: 'ClipboardDetector',
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
    // 1. 明确的文件类型 - 需要进一步分析具体文件类型
    if (formatAnalysis.containsKey(ClipboardFormat.files)) {
      return _analyzeFileContent(data, formatAnalysis);
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
      tag: 'ClipboardDetector',
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
    if (_isFilePath(contentToAnalyze)) {
      // 根据文件扩展名确定具体类型
      final fileType = _detectFileTypeByExtension(contentToAnalyze);
      return fileType;
    }

    // 4. 首先检查是否为颜色（无论长度如何）
    if (_isColor(contentToAnalyze)) return ClipType.color;

    // 5. 检查URL和邮箱
    if (_isURL(contentToAnalyze)) return ClipType.url;
    if (_isEmail(contentToAnalyze)) return ClipType.email;

    // 6. 对于短文本（<20字符），避免过度分析
    if (contentToAnalyze.length < 20) {
      return ClipType.text;
    }

    // 7. 对于中等长度文本（20-200字符），进行基本检测
    if (content.length <= 200) {
      if (_isJSON(content)) return ClipType.json;
      if (_isXML(content)) return ClipType.xml;
      if (_isStructuredData(content)) return ClipType.code;

      return ClipType.text;
    }

    // 8. 对于长文本（>200字符），进行完整检测
    return detectContentType(content);
  }

  /// 确定要保存的内容
  dynamic _determineContentToSave(
    ClipboardData data,
    ClipType detectedType,
    Map<ClipboardFormat, FormatInfo> formatAnalysis,
  ) {
    // 对于文件类型，需要特殊处理
    if (detectedType == ClipType.file) {
      // 检查是否真的有文件数据
      if (formatAnalysis.containsKey(ClipboardFormat.files)) {
        final files = formatAnalysis[ClipboardFormat.files]!.content;
        if (files is List && files.isNotEmpty) {
          return files;
        }
      }

      // 如果没有真实的文件数据，可能是误判，尝试获取文本内容
      if (formatAnalysis.containsKey(ClipboardFormat.text)) {
        final textContent = formatAnalysis[ClipboardFormat.text]!.content;
        if (textContent != null && textContent.toString().isNotEmpty) {
          unawaited(Log.w(
            'File type detected but no file data found, falling back to text content',
            tag: 'ClipboardDetector',
          ));
          return textContent;
        }
      }

      // 最后降级到最佳内容
      return data.bestContent?.toString() ?? '';
    }

    // 对于其他非文本类型，直接保存原始内容
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
    return data.bestContent?.toString() ?? '';
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
      case ClipType.color:
        // 颜色类型：优先使用文本格式的内容，因为颜色值通常是文本格式
        if (data.formats.containsKey(ClipboardFormat.text)) {
          return data.getFormat<String>(ClipboardFormat.text);
        }
        // 如果没有文本格式，使用最佳内容
        return data.bestContent;
      case ClipType.text:
      case ClipType.rtf:
      case ClipType.html:
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

  /// 分析文件内容以确定具体类型
  Future<ClipType> _analyzeFileContent(
    ClipboardData data,
    Map<ClipboardFormat, FormatInfo> formatAnalysis,
  ) async {
    try {
      final filesContent = formatAnalysis[ClipboardFormat.files]!.content;

      // 如果是文件路径列表，分析路径中的文件扩展名
      if (filesContent is List<String>) {
        if (filesContent.isEmpty) {
          return ClipType.file;
        }

        // 检查第一个文件的类型（通常多个文件是同类型）
        final firstFilePath = filesContent.first;
        final detectedType = _detectFileTypeByExtension(firstFilePath);

        await Log.i(
          'File content analysis - path-based detection',
          tag: 'ClipboardDetector',
          fields: {
            'filePath': firstFilePath,
            'detectedType': detectedType.name,
            'totalFiles': filesContent.length,
          },
        );

        return detectedType;
      }

      // 如果是文件对象或二进制数据，尝试从文件名或内容推断
      if (filesContent is Map) {
        // 检查文件名
        final fileName =
            filesContent['name'] as String? ?? filesContent['path'] as String?;
        if (fileName != null) {
          final detectedType = _detectFileTypeByExtension(fileName);

          await Log.i(
            'File content analysis - object-based detection',
            tag: 'ClipboardDetector',
            fields: {
              'fileName': fileName,
              'detectedType': detectedType.name,
            },
          );

          return detectedType;
        }
      }

      // 降级处理：检查是否有文本格式可以提供文件路径信息
      if (formatAnalysis.containsKey(ClipboardFormat.text)) {
        final textContent = formatAnalysis[ClipboardFormat.text]!.content
            .toString();
        if (_isFilePath(textContent)) {
          final detectedType = _detectFileTypeByExtension(textContent);

          await Log.i(
            'File content analysis - text fallback detection',
            tag: 'ClipboardDetector',
            fields: {
              'textContent': textContent,
              'detectedType': detectedType.name,
            },
          );

          return detectedType;
        }
      }

      await Log.w(
        'File content analysis - unable to determine specific type, defaulting to file',
        tag: 'ClipboardDetector',
        fields: {
          'filesContentType': filesContent.runtimeType.toString(),
        },
      );

      return ClipType.file;
    } on Exception catch (e) {
      await Log.e(
        'Error analyzing file content',
        tag: 'ClipboardDetector',
        error: e,
      );
      return ClipType.file;
    }
  }

  // ==================== 内容检测工具方法 ====================

  /// 检查是否为文件路径（使用统一的检测工具）
  bool _isFilePath(String content) {
    return ContentDetectionUtils.isFilePath(content);
  }

  /// 检查是否为URL（使用统一的检测工具）
  bool _isURL(String content) {
    return ContentDetectionUtils.isURL(content);
  }

  /// 检查是否为邮箱（使用统一的检测工具）
  bool _isEmail(String content) {
    return ContentDetectionUtils.isEmail(content);
  }

  /// 检查是否为颜色值（使用统一的检测工具）
  bool _isColor(String content) {
    return ContentDetectionUtils.isColor(content);
  }

  /// 检查是否为JSON（使用统一的检测工具）
  bool _isJSON(String content) {
    return ContentDetectionUtils.isJSON(content);
  }

  /// 检查是否为XML（使用统一的检测工具）
  bool _isXML(String content) {
    return ContentDetectionUtils.isXML(content);
  }

  /// 检查是否为结构化数据（使用统一的检测工具）
  bool _isStructuredData(String content) {
    return ContentDetectionUtils.isStructuredData(content);
  }

  /// 检查是否为终端日志（使用统一的检测工具）
  bool _isTerminalLog(String content) {
    return ContentDetectionUtils.isTerminalLog(content);
  }

  /// 从HTML中提取纯文本（使用统一的检测工具）
  String _extractTextFromHtml(String html) {
    return ContentDetectionUtils.extractTextFromHtml(html);
  }

  /// 从RTF中提取纯文本（使用统一的检测工具）
  String _extractTextFromRtf(String rtf) {
    return ContentDetectionUtils.extractTextFromRtf(rtf);
  }

  /// 根据文件扩展名检测文件类型（使用统一的 FileTypeUtils）
  ClipType _detectFileTypeByExtension(String filePath) {
    return FileTypeUtils.detectFileTypeByExtension(filePath);
  }
}
