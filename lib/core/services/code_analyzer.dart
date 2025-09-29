import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/content_analyzer.dart';

/// 代码分析器
class CodeAnalyzer extends ContentAnalyzer {
  @override
  ClipType get supportedType => ClipType.code;

  @override
  String get name => 'CodeAnalyzer';

  // 强代码指示器 - 这些模式几乎确定是代码
  static const List<String> _strongCodeIndicators = [
    'function ',
    'const ',
    'let ',
    'var ',
    'class ',
    'def ',
    'public ',
    'private ',
    'import ',
    'from ',
    '#include',
    'package ',
    'namespace ',
    'using namespace',
    'int main',
    'void main',
    'if __name__ == "__main__"',
    'public static void main',
    '@Override',
    '@Component',
    '@Injectable',
    'useState',
    'useEffect',
    'std::',
    'fn ',
    'let mut ',
    'impl ',
    'trait ',
    'struct ',
    '<?php',
    'require ',
    'include ',
    'echo ',
    'SELECT ',
    'INSERT ',
    'UPDATE ',
    'DELETE ',
    'FROM ',
    'WHERE ',
    'JOIN ',
    'CREATE ',
    'DROP ',
    'ALTER ',
    'ORDER BY',
    'GROUP BY',
    'HAVING ',
    'LIMIT ',
  ];

  // 代码模式 - 这些模式暗示可能是代码
  static const List<String> _codePatterns = [
    '//',
    '/*',
    '*/',
    '=>',
    '===',
    '!==',
    '&&',
    '||',
    '++',
    '--',
    'return ',
    'break;',
    'continue;',
    'throw ',
    'catch ',
    'try ',
    'finally ',
    'async ',
    'await ',
    'Promise',
    'console.',
    'document.',
    'window.',
    'this.',
    'self.',
    'super.',
    '__init__',
    '__str__',
    '__repr__',
  ];

  // 代码关键字
  static const List<String> _codeKeywords = [
    'if',
    'else',
    'for',
    'while',
    'do',
    'switch',
    'case',
    'default',
    'true',
    'false',
    'null',
    'undefined',
    'None',
    'True',
    'False',
    'extends',
    'implements',
    'interface',
    'abstract',
    'final',
    'static',
    'override',
    'virtual',
    'protected',
    'internal',
    'readonly',
    'const',
  ];

  // 语言特定的特征
  static const Map<String, List<String>> _languageFeatures = {
    'dart': [
      'Widget',
      'State<',
      'StatelessWidget',
      'StatefulWidget',
      'BuildContext',
      'void main()',
      '=>',
      'final ',
    ],
    'javascript': [
      'document.',
      'window.',
      'console.',
      'JSON.',
      'Array.',
      'function ',
      'const ',
      'let ',
    ],
    'typescript': [
      'interface ',
      ': string',
      ': number',
      ': boolean',
      'type ',
      'export ',
      'import ',
    ],
    'python': [
      'def ',
      '__init__',
      '__str__',
      'self.',
      'print(',
      'if __name__',
      'import ',
    ],
    'java': [
      'public class',
      'private ',
      'protected ',
      '@Override',
      'System.out',
      'public static void main',
    ],
    'cpp': [
      '#include',
      'std::',
      'namespace ',
      'using namespace',
      '::',
      'int main',
    ],
    'csharp': [
      'using System',
      'public class',
      'private ',
      'protected ',
      'Console.',
      'namespace ',
    ],
    'go': ['package ', 'func ', 'import (', 'fmt.', 'var ', 'func main()'],
    'rust': [
      'fn ',
      'let mut',
      'impl ',
      'trait ',
      'struct ',
      'use ',
      'fn main()',
    ],
    'php': ['<?php', r'$', '->', 'echo ', 'print ', 'var_dump', 'function '],
    'ruby': ['def ', 'end', 'require ', 'puts ', '@', '@@', 'class '],
    'swift': [
      'func ',
      'var ',
      'let ',
      'class ',
      'struct ',
      'import ',
      'override ',
    ],
    'kotlin': [
      'fun ',
      'val ',
      'var ',
      'class ',
      'object ',
      'companion',
      'fun main',
    ],
    'scala': ['def ', 'val ', 'var ', 'class ', 'object ', 'trait ', 'import '],
    'sql': [
      'SELECT ',
      'FROM ',
      'WHERE ',
      'JOIN ',
      'INSERT ',
      'UPDATE ',
      'DELETE ',
      'CREATE ',
      'DROP ',
      'ALTER ',
    ],
  };

  @override
  AnalysisResult analyze(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return AnalysisResult(type: supportedType, confidence: 0);
    }

    final lines = content.split('\n');
    final nonEmptyLines = lines
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (nonEmptyLines.isEmpty) {
      return AnalysisResult(type: supportedType, confidence: 0);
    }

    double score = 0;
    final metadata = <String, dynamic>{};
    final languageScores = <String, double>{};

    // 分析每一行
    for (final line in nonEmptyLines) {
      final lineTrimmed = line.trim();

      // 检查强代码指示器
      for (final indicator in _strongCodeIndicators) {
        if (lineTrimmed.contains(indicator)) {
          score += 3.0;
          break; // 每行只计算一次强指示器
        }
      }

      // 检查代码模式
      for (final pattern in _codePatterns) {
        if (lineTrimmed.contains(pattern)) {
          score += 1.5;
          break; // 每行只计算一次模式
        }
      }

      // 检查代码关键字
      for (final keyword in _codeKeywords) {
        if (_containsWholeWord(lineTrimmed, keyword)) {
          score += 1.0;
          break; // 每行只计算一次关键字
        }
      }

      // 检查语言特定特征
      for (final entry in _languageFeatures.entries) {
        final language = entry.key;
        final features = entry.value;

        for (final feature in features) {
          if (lineTrimmed.contains(feature)) {
            languageScores[language] = (languageScores[language] ?? 0.0) + 2.0;
            break;
          }
        }
      }

      // 检查代码结构模式
      if (_hasCodeStructure(lineTrimmed)) {
        score += 0.5;
      }
    }

    // 计算置信度 (0.0 - 1.0)
    final maxPossibleScore = nonEmptyLines.length * 3.0; // 每行最多3分
    var confidence = (score / maxPossibleScore).clamp(0.0, 1.0);

    // 如果置信度较低，但有明确的语言特征，提升置信度
    if (confidence < 0.5 && languageScores.isNotEmpty) {
      final maxLanguageScore = languageScores.values.reduce(
        (a, b) => a > b ? a : b,
      );
      if (maxLanguageScore >= 4.0) {
        // 至少2个语言特征
        confidence = (confidence + 0.3).clamp(0.0, 1.0);
      }
    }

    // 添加元数据
    if (languageScores.isNotEmpty) {
      final detectedLanguage = languageScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      metadata['detectedLanguage'] = detectedLanguage;
      metadata['languageConfidence'] = languageScores[detectedLanguage];
    }

    metadata['totalScore'] = score;
    metadata['lineCount'] = nonEmptyLines.length;

    return AnalysisResult(
      type: supportedType,
      confidence: confidence,
      metadata: metadata,
    );
  }

  /// 检查是否包含完整单词（避免部分匹配）
  bool _containsWholeWord(String text, String word) {
    final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
    return pattern.hasMatch(text);
  }

  /// 检查是否有代码结构特征
  bool _hasCodeStructure(String line) {
    // 检查括号、分号、大括号等代码结构
    final structurePatterns = [
      RegExp(r'.*\{.*\}.*'), // 包含大括号
      RegExp(r'.*\(.*\).*'), // 包含小括号
      RegExp(r'.*;$'), // 以分号结尾
      RegExp(r'^[ \t]*//'), // 注释行
      RegExp(r'^[ \t]*/\*'), // 块注释开始
      RegExp(r'.*\*/[ \t]*$'), // 块注释结束
      RegExp('.*=>.*'), // 箭头函数
      RegExp('.*:.*{'), // 对象/类定义
    ];

    return structurePatterns.any((pattern) => pattern.hasMatch(line));
  }
}
