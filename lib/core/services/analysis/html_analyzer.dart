import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/analysis/index.dart';

/// HTML 分析器
class HtmlAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.html;

  @override
  String get name => 'HtmlAnalyzer';

  // HTML 标签
  static const List<String> _htmlTags = [
    'html',
    'head',
    'body',
    'title',
    'meta',
    'link',
    'style',
    'script',
    'div',
    'span',
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'a',
    'img',
    'ul',
    'ol',
    'li',
    'table',
    'tr',
    'td',
    'th',
    'form',
    'input',
    'button',
    'textarea',
    'select',
    'option',
    'br',
    'hr',
    'strong',
    'em',
    'b',
    'i',
    'u',
    'small',
    'header',
    'footer',
    'nav',
    'section',
    'article',
    'aside',
    'main',
    'figure',
    'figcaption',
    'details',
    'summary',
  ];

  // HTML 属性
  static const List<String> _htmlAttributes = [
    'id=',
    'class=',
    'style=',
    'src=',
    'href=',
    'alt=',
    'title=',
    'width=',
    'height=',
    'type=',
    'name=',
    'value=',
    'placeholder=',
    'onclick=',
    'onload=',
    'onchange=',
    'data-',
    'aria-',
  ];

  // 代码特征 - 这些表明内容更可能是代码而非纯HTML
  static const List<String> _codeIndicators = [
    'function ',
    'const ',
    'let ',
    'var ',
    'class ',
    'import ',
    'export ',
    'from ',
    'require(',
    'module.exports',
    'useState',
    'useEffect',
    'document.',
    'console.',
    'window.',
    'this.',
    'props.',
    'state.',
    '=>',
    '===',
    '!==',
    '&&',
    '||',
    '++',
    '--',
    'return ',
    'if (',
    'for (',
    'while (',
    'switch (',
    'try {',
    'catch (',
    '<?php',
    'def ',
    'class ',
    'import ',
    '__init__',
    'self.',
    '#include',
    'namespace ',
    'using namespace',
    'std::',
  ];

  // JSX/React 特征
  static const List<String> _jsxIndicators = [
    'React.',
    'Component',
    'render()',
    'props.',
    'state.',
    'useState',
    'useEffect',
    'useContext',
    'useReducer',
    'className=',
    'onClick=',
    'onChange=',
    'onSubmit=',
  ];

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return AnalysisResult(type: supportedType, confidence: 0);
    }

    double htmlScore = 0;
    double codeScore = 0;
    final metadata = <String, dynamic>{};

    // 检查 DOCTYPE 声明
    if (trimmed.toLowerCase().startsWith('<!doctype html')) {
      htmlScore += 10;
      metadata['hasDoctype'] = true;
    }

    // 检查 XML 声明 - 如果有，更可能是 XML 而非 HTML
    if (trimmed.startsWith('<?xml')) {
      return AnalysisResult(type: supportedType, confidence: 0);
    }

    // 分析 HTML 标签
    final htmlTagMatches = _countHtmlTags(trimmed);
    htmlScore += htmlTagMatches * 2.0;
    metadata['htmlTagCount'] = htmlTagMatches;

    // 分析 HTML 属性
    final htmlAttrMatches = _countHtmlAttributes(trimmed);
    htmlScore += htmlAttrMatches * 1.0;
    metadata['htmlAttributeCount'] = htmlAttrMatches;

    // 检查代码特征
    final codeMatches = _countCodeIndicators(trimmed);
    codeScore += codeMatches * 3.0;
    metadata['codeIndicatorCount'] = codeMatches;

    // 检查 JSX 特征
    final jsxMatches = _countJsxIndicators(trimmed);
    if (jsxMatches > 0) {
      codeScore += jsxMatches * 4.0; // JSX 强烈表明是代码
      metadata['jsxIndicatorCount'] = jsxMatches;
      metadata['isJsx'] = true;
    }

    // 分析标签密度
    final tagDensity = _calculateTagDensity(trimmed);
    metadata['tagDensity'] = tagDensity;

    // 分析内容结构
    final structureAnalysis = _analyzeStructure(trimmed);
    metadata.addAll(structureAnalysis);

    // 计算最终置信度
    var confidence = _calculateConfidence(
      htmlScore,
      codeScore,
      tagDensity,
      structureAnalysis,
    );

    // 特殊情况处理
    confidence = _applySpecialRules(trimmed, confidence, metadata);

    metadata['htmlScore'] = htmlScore;
    metadata['codeScore'] = codeScore;

    return AnalysisResult(
      type: supportedType,
      confidence: confidence,
      metadata: metadata,
    );
  }

  /// 计算 HTML 标签数量
  int _countHtmlTags(String content) {
    var count = 0;
    for (final tag in _htmlTags) {
      if (content.contains('<$tag') || content.contains('</$tag>')) {
        count++;
      }
    }
    return count;
  }

  /// 计算 HTML 属性数量
  int _countHtmlAttributes(String content) {
    var count = 0;
    for (final attr in _htmlAttributes) {
      if (content.contains(attr)) {
        count++;
      }
    }
    return count;
  }

  /// 计算代码指示器数量
  int _countCodeIndicators(String content) {
    var count = 0;
    for (final indicator in _codeIndicators) {
      if (content.contains(indicator)) {
        count++;
      }
    }
    return count;
  }

  /// 计算 JSX 指示器数量
  int _countJsxIndicators(String content) {
    var count = 0;
    for (final indicator in _jsxIndicators) {
      if (content.contains(indicator)) {
        count++;
      }
    }
    return count;
  }

  /// 计算标签密度
  double _calculateTagDensity(String content) {
    final tagPattern = RegExp('<[^>]+>');
    final matches = tagPattern.allMatches(content);
    final tagLength = matches.fold(
      0,
      (sum, match) => sum + match.group(0)!.length,
    );
    return content.isNotEmpty ? tagLength / content.length : 0.0;
  }

  /// 分析内容结构
  Map<String, dynamic> _analyzeStructure(String content) {
    final result = <String, dynamic>{};

    // 检查是否有完整的 HTML 文档结构
    final hasHtmlTag = content.contains('<html') && content.contains('</html>');
    final hasHeadTag = content.contains('<head') && content.contains('</head>');
    final hasBodyTag = content.contains('<body') && content.contains('</body>');

    result['hasCompleteStructure'] = hasHtmlTag && hasHeadTag && hasBodyTag;
    result['hasHtmlTag'] = hasHtmlTag;
    result['hasHeadTag'] = hasHeadTag;
    result['hasBodyTag'] = hasBodyTag;

    // 检查是否是 HTML 片段
    final lines = content.split('\n');
    final nonEmptyLines = lines
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final linesWithTags = nonEmptyLines
        .where((line) => RegExp('<[^>]+>').hasMatch(line))
        .length;

    result['isFragment'] =
        !(result['hasCompleteStructure'] as bool) && linesWithTags > 0;
    result['tagLineRatio'] = nonEmptyLines.isNotEmpty
        ? linesWithTags / nonEmptyLines.length
        : 0.0;

    return result;
  }

  /// 计算置信度
  double _calculateConfidence(
    double htmlScore,
    double codeScore,
    double tagDensity,
    Map<String, dynamic> structure,
  ) {
    // 如果代码特征明显强于 HTML 特征，置信度很低
    if (codeScore > htmlScore * 2) {
      return 0.1;
    }

    // 如果没有 HTML 特征，置信度为 0
    if (htmlScore == 0) {
      return 0;
    }

    // 基础置信度基于 HTML 分数
    var confidence = (htmlScore / (htmlScore + codeScore)).clamp(0.0, 1.0);

    // 根据标签密度调整
    if (tagDensity > 0.3) {
      confidence = (confidence + 0.2).clamp(0.0, 1.0);
    } else if (tagDensity < 0.1) {
      confidence = (confidence - 0.2).clamp(0.0, 1.0);
    }

    // 根据结构完整性调整
    if (structure['hasCompleteStructure'] == true) {
      confidence = (confidence + 0.3).clamp(0.0, 1.0);
    } else if (structure['isFragment'] == true &&
        (structure['tagLineRatio'] as double) > 0.5) {
      confidence = (confidence + 0.1).clamp(0.0, 1.0);
    }

    return confidence;
  }

  /// 应用特殊规则
  double _applySpecialRules(
    String content,
    double confidence,
    Map<String, dynamic> metadata,
  ) {
    // 从原始置信度开始
    var localConfidence = confidence;

    // 如果检测到 JSX，大幅降低 HTML 置信度
    if (metadata['isJsx'] == true) {
      localConfidence = (confidence * 0.2).clamp(0.0, 1.0);
    }

    // 如果内容很短且只有简单标签，可能是测试数据
    if (content.length < 50 && (metadata['htmlTagCount'] as int) <= 2) {
      localConfidence = (confidence * 0.8).clamp(0.0, 1.0);
    }

    // 如果包含明显的编程语言特征，降低置信度
    final programmingPatterns = [
      '#include',
      'function(',
      'def ',
      'class ',
      'import ',
    ];
    if (programmingPatterns.any((pattern) => content.contains(pattern))) {
      localConfidence = (confidence * 0.3).clamp(0.0, 1.0);
    }

    return localConfidence;
  }
}
