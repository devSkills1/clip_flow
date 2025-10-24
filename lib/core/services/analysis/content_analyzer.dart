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

    // 首先检查是否为代码内容 - 代码内容不应该被认为是文件路径
    if (_isCodeContent(trimmed)) {
      return AnalysisResult(
        type: supportedType,
        confidence: 0,
        metadata: {'reason': 'detected_as_code'},
      );
    }

    // file:// 协议 - 最高置信度
    if (trimmed.startsWith('file://')) {
      confidence = 1;
      metadata['protocol'] = 'file';
    }
    // 绝对路径模式
    else if (RegExp(r'^[A-Za-z]:\\').hasMatch(trimmed) ||
        trimmed.startsWith('/')) {
      // 验证路径结构是否合理
      if (_isValidPath(trimmed)) {
        confidence = 0.9;
        metadata['pathType'] = 'absolute';
      } else {
        confidence = 0.2; // 如果包含代码特征，大幅降低置信度
        metadata['pathType'] = 'absolute_invalid';
      }
    }
    // 相对路径模式
    else if (trimmed.startsWith('./') || trimmed.startsWith('../')) {
      if (_isValidPath(trimmed)) {
        confidence = 0.8;
        metadata['pathType'] = 'relative';
      } else {
        confidence = 0.2;
        metadata['pathType'] = 'relative_invalid';
      }
    }
    // 包含文件扩展名
    else if (RegExp(r'\.[a-zA-Z0-9]{1,10}$').hasMatch(trimmed)) {
      final extension = trimmed.split('.').last.toLowerCase();

      // 对于代码文件扩展名，需要更严格的检查
      final codeExtensions = [
        'dart',
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
      ];
      if (codeExtensions.contains(extension)) {
        // 如果有代码特征，直接返回0置信度
        if (_hasCodeFeatures(trimmed)) {
          return AnalysisResult(
            type: supportedType,
            confidence: 0,
            metadata: {'reason': 'code_with_extension', 'extension': extension},
          );
        }
      }

      // 检查是否真实存在
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          confidence = 0.95;
          metadata['exists'] = true;
        } else if (trimmed.contains('/') || trimmed.contains(r'\')) {
          confidence = _isValidPath(trimmed) ? 0.7 : 0.3;
          metadata['exists'] = false;
        } else {
          // 对于没有路径分隔符的内容，降低置信度
          confidence = 0.4;
          metadata['hasPathSeparator'] = false;
        }
      } on FileSystemException catch (_) {
        if (trimmed.contains('/') || trimmed.contains(r'\')) {
          confidence = _isValidPath(trimmed) ? 0.6 : 0.2;
        } else {
          confidence = 0.1;
        }
      }
    }

    return AnalysisResult(
      type: supportedType,
      confidence: confidence,
      metadata: metadata,
    );
  }

  /// 检查是否为代码内容
  bool _isCodeContent(String content) {
    return _hasCodeFeatures(content);
  }

  /// 检查内容是否包含代码特征
  bool _hasCodeFeatures(String content) {
    // 常见的代码关键字和模式
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

  /// 验证路径是否有效
  bool _isValidPath(String path) {
    // 路径不应该包含代码特有的字符
    if (path.contains(RegExp(r'[{}[\]();=<>]'))) {
      return false;
    }

    // 检查路径长度
    if (path.length > 1000) {
      return false;
    }

    return true;
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
