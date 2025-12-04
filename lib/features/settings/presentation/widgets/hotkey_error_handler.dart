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

    // 检查常用系统快捷键 (防止覆盖关键功能)
    final criticalError = _checkCriticalSystemHotkeys(modifiers, key);
    if (criticalError != null) {
      return criticalError;
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

  /// 检查关键系统快捷键
  static String? _checkCriticalSystemHotkeys(
    Set<HotkeyModifier> modifiers,
    String key,
  ) {
    final keyString = key.toLowerCase();

    // 检查单修饰符 Cmd/Ctrl 的情况
    // 这些是操作系统最基础的快捷键，覆盖它们会导致严重的用户体验问题
    if (modifiers.length == 1 && modifiers.contains(HotkeyModifier.command)) {
      const criticalKeys = {
        'c', // 复制
        'v', // 粘贴
        'x', // 剪切
        'z', // 撤销
        'a', // 全选
        's', // 保存
        'q', // 退出
        'w', // 关闭窗口
        'm', // 最小化
        'h', // 隐藏
        'n', // 新建
        'o', // 打开
        'p', // 打印
        'tab', // 切换应用/标签
        'space', // Spotlight/输入法
      };
      
      if (criticalKeys.contains(keyString)) {
        return '该快捷键与系统关键功能冲突，禁止使用';
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
