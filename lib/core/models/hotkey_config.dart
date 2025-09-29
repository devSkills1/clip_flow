import 'package:meta/meta.dart';

/// 快捷键修饰符
enum HotkeyModifier {
  /// Command键 (macOS) / Ctrl键 (Windows/Linux)
  command,

  /// Alt键 (macOS: Option)
  alt,

  /// Shift键
  shift,

  /// Control键 (macOS专用，Windows/Linux使用command)
  control,

  /// Windows键 (Windows/Linux专用)
  meta,
}

/// 快捷键动作类型
enum HotkeyAction {
  /// 显示/隐藏主窗口
  toggleWindow,

  /// 快速粘贴最近一项
  quickPaste,

  /// 显示剪贴板历史
  showHistory,

  /// 清空剪贴板历史
  clearHistory,

  /// 搜索剪贴板内容
  search,

  /// OCR文字识别
  performOCR,

  /// 暂停/恢复剪贴板监听
  toggleMonitoring,
}

/// 快捷键配置
@immutable
class HotkeyConfig {
  /// 构造函数
  const HotkeyConfig({
    required this.action,
    required this.key,
    required this.modifiers,
    required this.description,
    this.enabled = true,
    this.isDefault = false,
  });

  /// 从JSON创建
  factory HotkeyConfig.fromJson(Map<String, dynamic> json) {
    return HotkeyConfig(
      action: HotkeyAction.values.firstWhere(
        (a) => a.name == json['action'],
      ),
      key: json['key'] as String,
      modifiers: (json['modifiers'] as List<dynamic>)
          .map(
            (m) => HotkeyModifier.values.firstWhere(
              (mod) => mod.name == m,
            ),
          )
          .toSet(),
      enabled: json['enabled'] as bool? ?? true,
      description: json['description'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// 快捷键动作
  final HotkeyAction action;

  /// 主键（字母、数字或功能键）
  final String key;

  /// 修饰符列表
  final Set<HotkeyModifier> modifiers;

  /// 是否启用
  final bool enabled;

  /// 描述信息
  final String description;

  /// 是否为系统默认配置
  final bool isDefault;

  /// 获取快捷键的字符串表示
  String get displayString {
    final modifierStrings = <String>[];

    // 按照平台习惯排序修饰符
    if (modifiers.contains(HotkeyModifier.control)) {
      modifierStrings.add('Ctrl');
    }
    if (modifiers.contains(HotkeyModifier.command)) {
      modifierStrings.add(_isApplePlatform ? 'Cmd' : 'Ctrl');
    }
    if (modifiers.contains(HotkeyModifier.alt)) {
      modifierStrings.add(_isApplePlatform ? 'Option' : 'Alt');
    }
    if (modifiers.contains(HotkeyModifier.shift)) {
      modifierStrings.add('Shift');
    }
    if (modifiers.contains(HotkeyModifier.meta)) {
      modifierStrings.add('Win');
    }

    modifierStrings.add(key.toUpperCase());

    return modifierStrings.join(' + ');
  }

  /// 获取用于系统注册的快捷键字符串
  String get systemKeyString {
    final parts = <String>[];

    if (modifiers.contains(HotkeyModifier.command)) {
      parts.add('cmd');
    }
    if (modifiers.contains(HotkeyModifier.control)) {
      parts.add('ctrl');
    }
    if (modifiers.contains(HotkeyModifier.alt)) {
      parts.add('alt');
    }
    if (modifiers.contains(HotkeyModifier.shift)) {
      parts.add('shift');
    }
    if (modifiers.contains(HotkeyModifier.meta)) {
      parts.add('meta');
    }

    parts.add(key.toLowerCase());

    return parts.join('+');
  }

  /// 检查是否为Apple平台（macOS/iOS）
  bool get _isApplePlatform {
    // 这里简化处理，实际应该通过Platform.isMacOS等判断
    return true; // 暂时默认为macOS
  }

  /// 复制并修改配置
  HotkeyConfig copyWith({
    HotkeyAction? action,
    String? key,
    Set<HotkeyModifier>? modifiers,
    bool? enabled,
    String? description,
    bool? isDefault,
  }) {
    return HotkeyConfig(
      action: action ?? this.action,
      key: key ?? this.key,
      modifiers: modifiers ?? this.modifiers,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'key': key,
      'modifiers': modifiers.map((m) => m.name).toList(),
      'enabled': enabled,
      'description': description,
      'isDefault': isDefault,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HotkeyConfig &&
        other.action == action &&
        other.key == key &&
        other.modifiers.length == modifiers.length &&
        other.modifiers.every(modifiers.contains) &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      action,
      key,
      modifiers,
      enabled,
    );
  }

  @override
  String toString() {
    return 'HotkeyConfig(action: $action, key: $key, modifiers: $modifiers, enabled: $enabled)';
  }
}

/// 默认快捷键配置
class DefaultHotkeyConfigs {
  static const List<HotkeyConfig> defaults = [
    HotkeyConfig(
      action: HotkeyAction.toggleWindow,
      key: 'v',
      modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
      description: '显示/隐藏剪贴板窗口',
      isDefault: true,
    ),
    HotkeyConfig(
      action: HotkeyAction.quickPaste,
      key: 'v',
      modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
      description: '快速粘贴最近一项',
      isDefault: true,
    ),
    HotkeyConfig(
      action: HotkeyAction.showHistory,
      key: 'h',
      modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
      description: '显示剪贴板历史',
      isDefault: true,
    ),
    HotkeyConfig(
      action: HotkeyAction.search,
      key: 'f',
      modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
      description: '搜索剪贴板内容',
      isDefault: true,
    ),
    HotkeyConfig(
      action: HotkeyAction.performOCR,
      key: 'o',
      modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
      description: 'OCR文字识别',
      isDefault: true,
    ),
  ];
}
