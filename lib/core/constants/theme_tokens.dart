import 'package:flutter/material.dart';

/// 主题 Token
class ThemeTokens {
  /// 私有构造：禁止实例化
  ThemeTokens._();

  /// 用于生成 ColorScheme 的种子色
  static const Color seedColor = Color(0xFF007AFF);

  /// 主字体族（在 pubspec.yaml 中配置具体字体资源）
  static const String primaryFontFamily = 'SF Pro Display';

  /// 字体回退列表（用于平台字体回退）
  static const List<String> fallbackFonts = <String>[
    'system-ui',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];
}
