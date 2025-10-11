import 'dart:convert';
import 'dart:io';

import 'package:clip_flow_pro/core/models/clip_item.dart';

/// 内容分析结果
class AnalysisResult {
  /// 分析结果构造函数
  const AnalysisResult({
    required this.type,
    required this.confidence,
    this.metadata = const {},
  });

  /// 分析结果类型
  final ClipType type;

  /// 分析结果置信度
  final double confidence;

  /// 分析结果元数据
  final Map<String, dynamic> metadata;

  @override
  String toString() => 'AnalysisResult(type: $type, confidence: $confidence)';
}

/// 抽象内容分析器
abstract class ContentAnalyzer {
  /// 分析内容并返回置信度分数 (0.0 - 1.0)
  AnalysisResult analyze(String content);

  /// 分析器支持的类型
  ClipType get supportedType;

  /// 分析器名称
  String get name;
}

/// 颜色值分析器
class ColorAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.color;

  @override
  String get name => 'ColorAnalyzer';

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();

    // Hex 颜色 (#RGB, #RRGGBB, #RRGGBBAA)
    final hexPattern = RegExp(
      r'^#([A-Fa-f0-9]{3}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$',
    );
    if (hexPattern.hasMatch(trimmed)) {
      return AnalysisResult(
        type: supportedType,
        confidence: 1,
        metadata: {'format': 'hex'},
      );
    }

    // RGB/RGBA 颜色
    final rgbPattern = RegExp(
      r'^rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*(,\s*[\d.]+)?\s*\)$',
      caseSensitive: false,
    );
    if (rgbPattern.hasMatch(trimmed)) {
      return AnalysisResult(
        type: supportedType,
        confidence: 1,
        metadata: {'format': 'rgb'},
      );
    }

    // HSL/HSLA 颜色
    final hslPattern = RegExp(
      r'^hsla?\(\s*\d+\s*,\s*\d+%\s*,\s*\d+%\s*(,\s*[\d.]+)?\s*\)$',
      caseSensitive: false,
    );
    if (hslPattern.hasMatch(trimmed)) {
      return AnalysisResult(
        type: supportedType,
        confidence: 1,
        metadata: {'format': 'hsl'},
      );
    }

    return AnalysisResult(type: supportedType, confidence: 0);
  }
}

/// URL 分析器
class UrlAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.url;

  @override
  String get name => 'UrlAnalyzer';

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (uri.hasScheme && uri.hasAuthority) {
        final supportedSchemes = ['http', 'https', 'ftp', 'ftps'];
        if (supportedSchemes.contains(uri.scheme.toLowerCase())) {
          return AnalysisResult(
            type: supportedType,
            confidence: 1,
            metadata: {'scheme': uri.scheme, 'host': uri.host},
          );
        }
      }
    } on FormatException catch (_) {
      // URI 解析失败
    }

    return AnalysisResult(type: supportedType, confidence: 0);
  }
}

/// 邮箱分析器
class EmailAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.email;

  @override
  String get name => 'EmailAnalyzer';

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (emailPattern.hasMatch(trimmed)) {
      return AnalysisResult(
        type: supportedType,
        confidence: 1,
        metadata: {'domain': trimmed.split('@').last},
      );
    }

    return AnalysisResult(type: supportedType, confidence: 0);
  }
}

/// JSON 分析器
class JsonAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.json;

  @override
  String get name => 'JsonAnalyzer';

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();

    // 基本格式检查
    if (!((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']')))) {
      return AnalysisResult(type: supportedType, confidence: 0);
    }

    try {
      final decoded = json.decode(trimmed);
      return AnalysisResult(
        type: supportedType,
        confidence: 1,
        metadata: {
          'isArray': decoded is List,
          'isObject': decoded is Map,
        },
      );
    } on FormatException catch (_) {
      return AnalysisResult(type: supportedType, confidence: 0);
    }
  }
}

/// RTF 分析器
class RtfAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.rtf;

  @override
  String get name => 'RtfAnalyzer';

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();

    if (trimmed.startsWith(r'{\rtf')) {
      return AnalysisResult(
        type: supportedType,
        confidence: 1,
      );
    }

    return AnalysisResult(type: supportedType, confidence: 0);
  }
}

/// 文件路径分析器
class FilePathAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.file;

  @override
  String get name => 'FilePathAnalyzer';

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();
    double confidence = 0;
    final metadata = <String, dynamic>{};

    // file:// 协议 - 最高置信度
    if (trimmed.startsWith('file://')) {
      confidence = 1;
      metadata['protocol'] = 'file';
    }
    // 绝对路径模式
    else if (RegExp(r'^[A-Za-z]:\\').hasMatch(trimmed) ||
        trimmed.startsWith('/')) {
      confidence = 0.9;
      metadata['pathType'] = 'absolute';
    }
    // 相对路径模式
    else if (trimmed.startsWith('./') || trimmed.startsWith('../')) {
      confidence = 0.8;
      metadata['pathType'] = 'relative';
    }
    // 包含文件扩展名
    else if (RegExp(r'\.[a-zA-Z0-9]{1,10}$').hasMatch(trimmed)) {
      // 检查是否真实存在
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          confidence = 0.95;
          metadata['exists'] = true;
        } else if (trimmed.contains('/') || trimmed.contains(r'\')) {
          confidence = 0.7;
          metadata['exists'] = false;
        }
      } on FileSystemException catch (_) {
        if (trimmed.contains('/') || trimmed.contains(r'\')) {
          confidence = 0.6;
        }
      }
    }

    return AnalysisResult(
      type: supportedType,
      confidence: confidence,
      metadata: metadata,
    );
  }
}

/// XML 分析器
class XmlAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.xml;

  @override
  String get name => 'XmlAnalyzer';

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();
    double confidence = 0;
    final metadata = <String, dynamic>{};

    // XML 声明
    if (trimmed.startsWith('<?xml')) {
      confidence = 1.0;
      metadata['hasDeclaration'] = true;
    }
    // 基本 XML 结构
    else if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
      final xmlPattern = RegExp('<[^>]+>.*</[^>]+>|<[^>]+/>');
      if (xmlPattern.hasMatch(trimmed)) {
        // 检查是否包含 HTML 特有标签
        final htmlTags = ['html', 'head', 'body', 'div', 'span', 'p'];
        final hasHtmlTags = htmlTags.any(
          (tag) => trimmed.contains('<$tag') || trimmed.contains('</$tag>'),
        );

        if (!hasHtmlTags) {
          confidence = 0.8;
          metadata['hasDeclaration'] = false;
        }
      }
    }

    return AnalysisResult(
      type: supportedType,
      confidence: confidence,
      metadata: metadata,
    );
  }
}
