import 'package:clip_flow_pro/core/models/hotkey_config.dart';
import 'package:flutter/services.dart';

/// 增强的按键处理器
class EnhancedKeyHandler {
  /// 特殊键映射表
  static final Map<LogicalKeyboardKey, String> _specialKeyMap = {
    // 功能键
    LogicalKeyboardKey.f1: 'F1',
    LogicalKeyboardKey.f2: 'F2',
    LogicalKeyboardKey.f3: 'F3',
    LogicalKeyboardKey.f4: 'F4',
    LogicalKeyboardKey.f5: 'F5',
    LogicalKeyboardKey.f6: 'F6',
    LogicalKeyboardKey.f7: 'F7',
    LogicalKeyboardKey.f8: 'F8',
    LogicalKeyboardKey.f9: 'F9',
    LogicalKeyboardKey.f10: 'F10',
    LogicalKeyboardKey.f11: 'F11',
    LogicalKeyboardKey.f12: 'F12',

    // 方向键
    LogicalKeyboardKey.arrowUp: 'ArrowUp',
    LogicalKeyboardKey.arrowDown: 'ArrowDown',
    LogicalKeyboardKey.arrowLeft: 'ArrowLeft',
    LogicalKeyboardKey.arrowRight: 'ArrowRight',

    // 其他特殊键
    LogicalKeyboardKey.space: 'Space',
    LogicalKeyboardKey.tab: 'Tab',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.backspace: 'Backspace',
    LogicalKeyboardKey.delete: 'Delete',
    LogicalKeyboardKey.home: 'Home',
    LogicalKeyboardKey.end: 'End',
    LogicalKeyboardKey.pageUp: 'PageUp',
    LogicalKeyboardKey.pageDown: 'PageDown',
    LogicalKeyboardKey.insert: 'Insert',
    LogicalKeyboardKey.printScreen: 'PrintScreen',
    LogicalKeyboardKey.scrollLock: 'ScrollLock',
    LogicalKeyboardKey.pause: 'Pause',
  };

  /// 检查是否为修饰符键
  static bool isModifierKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;
  }

  /// 获取修饰符类型
  static HotkeyModifier? getModifierType(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      return HotkeyModifier.command;
    } else if (key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      return HotkeyModifier.alt;
    } else if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      return HotkeyModifier.shift;
    } else if (key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      return HotkeyModifier.control;
    }
    return null;
  }

  /// 获取主键标签
  static String? getMainKeyLabel(LogicalKeyboardKey key) {
    // 检查特殊键
    if (_specialKeyMap.containsKey(key)) {
      return _specialKeyMap[key];
    }

    // 检查普通字符键
    final keyLabel = key.keyLabel;
    if (keyLabel.isNotEmpty && keyLabel.length == 1) {
      return keyLabel.toLowerCase();
    }

    return null;
  }

  /// 格式化快捷键显示字符串
  static String formatHotkeyString(
    Set<HotkeyModifier> modifiers,
    String? mainKey,
  ) {
    if (mainKey == null) {
      if (modifiers.isEmpty) {
        return '请按下快捷键组合';
      } else {
        final modifierStrings = _getModifierStrings(modifiers);
        return '${modifierStrings.join(' + ')} + ?';
      }
    } else {
      final modifierStrings = _getModifierStrings(modifiers);
      modifierStrings.add(mainKey.toUpperCase());
      return modifierStrings.join(' + ');
    }
  }

  /// 获取修饰符字符串列表
  static List<String> _getModifierStrings(Set<HotkeyModifier> modifiers) {
    final strings = <String>[];

    // 按照约定的顺序添加修饰符
    if (modifiers.contains(HotkeyModifier.command)) {
      strings.add('Cmd');
    }
    if (modifiers.contains(HotkeyModifier.control)) {
      strings.add('Ctrl');
    }
    if (modifiers.contains(HotkeyModifier.alt)) {
      strings.add('Alt');
    }
    if (modifiers.contains(HotkeyModifier.shift)) {
      strings.add('Shift');
    }

    return strings;
  }
}
