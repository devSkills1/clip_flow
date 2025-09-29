import 'package:clip_flow_pro/core/models/hotkey_config.dart';

/// 快捷键错误处理器
/// 提供用户友好的错误消息和验证功能
class HotkeyErrorHandler {
  /// 获取用户友好的错误消息
  static String getUserFriendlyErrorMessage(String originalError) {
    if (originalError.contains('already registered') ||
        originalError.contains('conflict')) {
      return '该快捷键已被其他应用程序占用，请选择其他组合';
    }

    if (originalError.contains('invalid') ||
        originalError.contains('not supported')) {
      return '不支持的快捷键组合，请使用有效的按键组合';
    }

    if (originalError.contains('system reserved')) {
      return '该快捷键为系统保留，无法使用';
    }

    if (originalError.contains('permission')) {
      return '没有权限注册快捷键，请检查应用权限设置';
    }

    return '快捷键设置失败：$originalError';
  }

  /// 验证快捷键配置
  static String? validateHotkeyConfig(
    Set<HotkeyModifier> modifiers,
    String? key,
  ) {
    if (key == null || key.isEmpty) {
      return '请选择一个主键';
    }

    if (modifiers.isEmpty) {
      return '请至少选择一个修饰符键（Cmd、Ctrl、Alt、Shift）';
    }

    // 检查系统保留快捷键
    final reservedError = _checkSystemReservedHotkeys(modifiers, key);
    if (reservedError != null) {
      return reservedError;
    }

    return null;
  }

  /// 检查系统保留的快捷键
  static String? _checkSystemReservedHotkeys(
    Set<HotkeyModifier> modifiers,
    String key,
  ) {
    final keyString = key.toLowerCase();

    // Cmd+Tab, Cmd+Space 等系统快捷键
    if (modifiers.contains(HotkeyModifier.command) &&
        modifiers.contains(HotkeyModifier.alt)) {
      const reservedKeys = {'tab', 'space', 'escape'};
      if (reservedKeys.contains(keyString)) {
        return '该快捷键为系统保留，请选择其他组合';
      }
    }

    // Cmd+Shift 组合
    if (modifiers.contains(HotkeyModifier.command) &&
        modifiers.contains(HotkeyModifier.shift)) {
      const reservedKeys = {'3', '4', '5'};
      if (reservedKeys.contains(keyString)) {
        return '该快捷键为系统保留，请选择其他组合';
      }
    }

    return null;
  }

  /// 获取快捷键使用提示
  static List<String> getHotkeyTips() {
    return [
      '• 至少需要一个修饰符键（Cmd、Ctrl、Alt、Shift）',
      '• 避免使用系统保留的快捷键组合',
      '• 建议使用 Cmd+Shift 或 Cmd+Alt 组合',
      '• 支持字母、数字和功能键（F1-F12）',
    ];
  }
}
