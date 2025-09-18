/// 颜色常量
/// 定义应用中使用的所有颜色值，避免硬编码
class AppColors {
  /// 私有构造：禁止实例化
  AppColors._();

  /// 透明色
  static const int transparent = 0x00000000;

  /// 白色
  static const int white = 0xFFFFFFFF;

  /// 黑色
  static const int black = 0xFF000000;

  /// 默认颜色值（用于未知颜色）
  static const String defaultColorHex = '#000000';

  /// 图标颜色映射
  static const Map<String, int> iconColors = {
    'blue': 0xFF2196F3,
    'green': 0xFF4CAF50,
    'purple': 0xFF9C27B0,
    'orange': 0xFFFF9800,
    'grey': 0xFF9E9E9E,
    'red': 0xFFF44336,
    'pink': 0xFFE91E63,
  };

  /// 灰色系列
  static const int grey300 = 0xFFE0E0E0;

  /// 灰色600
  static const int grey600 = 0xFF757575;

  /// 蓝色系列
  static const int blue100 = 0xFFBBDEFB;
}
