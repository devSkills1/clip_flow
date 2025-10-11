import 'dart:async';

/// 内容分析器端口接口
///
/// 负责分析剪贴板内容，包括：
/// - 文本内容分析
/// - 代码识别
/// - 元数据提取
abstract class ContentAnalyzerPort {
  /// 分析文本内容
  Future<Map<String, dynamic>> analyzeText(String content);

  /// 分析代码内容
  Future<Map<String, dynamic>> analyzeCode(String code, String? language);

  /// 提取元数据
  Future<Map<String, dynamic>> extractMetadata(dynamic content);
}

/// HTML 分析器端口接口
///
/// 负责分析 HTML 内容，包括：
/// - HTML 结构解析
/// - 链接提取
/// - 文本内容提取
abstract class HtmlAnalyzerPort {
  /// 分析 HTML 内容
  Future<Map<String, dynamic>> analyzeHtml(String html);

  /// 提取链接
  Future<List<String>> extractLinks(String html);

  /// 提取纯文本
  Future<String> extractText(String html);

  /// 验证 HTML 格式
  bool isValidHtml(String html);
}

/// 代码分析器端口接口
///
/// 负责分析代码内容，包括：
/// - 语言识别
/// - 语法检查
/// - 代码质量分析
abstract class CodeAnalyzerPort {
  /// 识别代码语言
  Future<String?> detectLanguage(String code);

  /// 分析代码质量
  Future<Map<String, dynamic>> analyzeCodeQuality(
    String code,
    String language,
  );

  /// 提取代码结构
  Future<Map<String, dynamic>> extractCodeStructure(
    String code,
    String language,
  );

  /// 验证代码语法
  Future<bool> validateSyntax(
    String code,
    String language,
  );
}
