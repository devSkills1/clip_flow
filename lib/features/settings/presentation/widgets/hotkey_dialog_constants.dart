/// 快捷键对话框的常量定义
class HotkeyDialogConstants {
  // 对话框尺寸
  /// 对话框宽度
  static const double dialogWidth = 400;

  /// 动画持续时间
  static const Duration animationDuration = Duration(milliseconds: 200);

  /// 边框宽度
  static const double borderWidth = 1;

  // 间距
  /// 小间距
  static const double smallSpacing = 8;

  /// 中等间距
  static const double mediumSpacing = 12;

  /// 大间距
  static const double largeSpacing = 16;

  // 边框
  /// 边框圆角半径
  static const double borderRadius = 8;

  // 透明度
  /// 激活状态背景透明度
  static const double activeBackgroundOpacity = 0.1;
}

/// 快捷键验证器
class HotkeyValidator {
  /// 验证快捷键组合是否有效
  static bool isValidCombination(Set<dynamic> modifiers, String? key) {
    return modifiers.isNotEmpty &&
        key != null &&
        key.isNotEmpty &&
        key.trim().isNotEmpty;
  }

  /// 验证是否为有效的主键
  static bool isValidMainKey(String key) {
    // 检查是否为单个字符或特殊键
    return key.length == 1 || _isSpecialKey(key);
  }

  /// 检查是否为特殊键
  static bool _isSpecialKey(String key) {
    const specialKeys = {
      'F1',
      'F2',
      'F3',
      'F4',
      'F5',
      'F6',
      'F7',
      'F8',
      'F9',
      'F10',
      'F11',
      'F12',
      'ArrowUp',
      'ArrowDown',
      'ArrowLeft',
      'ArrowRight',
      'Space',
      'Tab',
      'Enter',
      'Backspace',
      'Delete',
      'Home',
      'End',
      'PageUp',
      'PageDown',
      'Insert',
      'PrintScreen',
      'ScrollLock',
      'Pause',
    };
    return specialKeys.contains(key);
  }
}
