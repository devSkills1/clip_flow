import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow_pro/core/models/hotkey_config.dart';

/// 快捷键综合测试（不依赖平台插件）
void main() {
  group('HotkeyConfig Tests', () {
    test('should create hotkey config correctly', () {
      const config = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 't',
        modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
        description: '测试快捷键',
      );

      expect(config.action, equals(HotkeyAction.toggleWindow));
      expect(config.key, equals('t'));
      expect(config.modifiers, contains(HotkeyModifier.command));
      expect(config.modifiers, contains(HotkeyModifier.alt));
      expect(config.description, equals('测试快捷键'));
      expect(config.enabled, isTrue);
      expect(config.isDefault, isFalse);
    });

    test('should generate correct display string', () {
      // 测试macOS平台显示
      const config = HotkeyConfig(
        action: HotkeyAction.quickPaste,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.control},
        description: '快速粘贴',
      );

      final displayString = config.displayString;
      expect(displayString, contains('Cmd'));
      expect(displayString, contains('Ctrl'));
      expect(displayString, contains('V'));
    });

    test('should generate correct system key string', () {
      const config = HotkeyConfig(
        action: HotkeyAction.search,
        key: 'f',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: '搜索',
      );

      final systemKeyString = config.systemKeyString;
      expect(systemKeyString, equals('cmd+shift+f'));
    });

    test('should serialize and deserialize correctly', () {
      const originalConfig = HotkeyConfig(
        action: HotkeyAction.showHistory,
        key: 'h',
        modifiers: {HotkeyModifier.command},
        description: '显示历史',
        enabled: true,
        ignoreRepeat: false,
      );

      final json = originalConfig.toJson();
      final deserializedConfig = HotkeyConfig.fromJson(json);

      expect(deserializedConfig.action, equals(originalConfig.action));
      expect(deserializedConfig.key, equals(originalConfig.key));
      expect(deserializedConfig.modifiers, equals(originalConfig.modifiers));
      expect(deserializedConfig.description, equals(originalConfig.description));
      expect(deserializedConfig.enabled, equals(originalConfig.enabled));
      expect(deserializedConfig.ignoreRepeat, equals(originalConfig.ignoreRepeat));
    });

    test('should handle equality correctly', () {
      const config1 = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 't',
        modifiers: {HotkeyModifier.command},
        description: '测试1',
      );

      const config2 = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 't',
        modifiers: {HotkeyModifier.command},
        description: '测试2', // 不同的描述
      );

      const config3 = HotkeyConfig(
        action: HotkeyAction.quickPaste,
        key: 't',
        modifiers: {HotkeyModifier.command},
        description: '测试1',
      );

      expect(config1, equals(config2)); // action、key、modifiers相同应该相等
      expect(config1, isNot(equals(config3))); // action不同
    });

    test('should copy with modifications correctly', () {
      const originalConfig = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 't',
        modifiers: {HotkeyModifier.command},
        description: '原始配置',
      );

      final modifiedConfig = originalConfig.copyWith(
        key: 'n',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
      );

      expect(modifiedConfig.action, equals(originalConfig.action));
      expect(modifiedConfig.key, equals('n'));
      expect(modifiedConfig.modifiers, contains(HotkeyModifier.command));
      expect(modifiedConfig.modifiers, contains(HotkeyModifier.shift));
      expect(modifiedConfig.description, equals(originalConfig.description));
    });
  });

  group('DefaultHotkeyConfigs Tests', () {
    test('should provide sensible defaults', () {
      final defaults = DefaultHotkeyConfigs.defaults;
      expect(defaults, isNotEmpty);

      // 验证所有默认配置都是有效的
      for (final config in defaults) {
        expect(config.key, isNotEmpty);
        expect(config.modifiers, isNotEmpty);
        expect(config.action, isA<HotkeyAction>());
        expect(config.description, isNotEmpty);
        expect(config.isDefault, isTrue);
      }
    });

    test('should have unique actions in defaults', () {
      final defaults = DefaultHotkeyConfigs.defaults;
      final actions = defaults.map((config) => config.action).toSet();

      expect(actions.length, equals(defaults.length));
    });

    test('should include all essential actions in defaults', () {
      final defaults = DefaultHotkeyConfigs.defaults;
      final actions = defaults.map((config) => config.action).toSet();

      final essentialActions = {
        HotkeyAction.toggleWindow,
        HotkeyAction.quickPaste,
        HotkeyAction.showHistory,
        HotkeyAction.search,
        HotkeyAction.performOCR,
      };

      for (final action in essentialActions) {
        expect(actions, contains(action));
      }
    });
  });

  group('HotkeyAction Tests', () {
    test('should have all required actions', () {
      final allActions = HotkeyAction.values;

      final requiredActions = {
        HotkeyAction.toggleWindow,
        HotkeyAction.quickPaste,
        HotkeyAction.showHistory,
        HotkeyAction.clearHistory,
        HotkeyAction.search,
        HotkeyAction.performOCR,
        HotkeyAction.toggleMonitoring,
      };

      for (final action in requiredActions) {
        expect(allActions, contains(action));
      }
    });

    test('should have correct action names', () {
      expect(HotkeyAction.toggleWindow.name, equals('toggleWindow'));
      expect(HotkeyAction.quickPaste.name, equals('quickPaste'));
      expect(HotkeyAction.showHistory.name, equals('showHistory'));
      expect(HotkeyAction.clearHistory.name, equals('clearHistory'));
      expect(HotkeyAction.search.name, equals('search'));
      expect(HotkeyAction.performOCR.name, equals('performOCR'));
      expect(HotkeyAction.toggleMonitoring.name, equals('toggleMonitoring'));
    });
  });

  group('HotkeyModifier Tests', () {
    test('should have all required modifiers', () {
      final allModifiers = HotkeyModifier.values;

      final requiredModifiers = {
        HotkeyModifier.command,
        HotkeyModifier.alt,
        HotkeyModifier.shift,
        HotkeyModifier.control,
        HotkeyModifier.meta,
      };

      for (final modifier in requiredModifiers) {
        expect(allModifiers, contains(modifier));
      }
    });

    test('should have correct modifier names', () {
      expect(HotkeyModifier.command.name, equals('command'));
      expect(HotkeyModifier.alt.name, equals('alt'));
      expect(HotkeyModifier.shift.name, equals('shift'));
      expect(HotkeyModifier.control.name, equals('control'));
      expect(HotkeyModifier.meta.name, equals('meta'));
    });
  });

  group('Platform Detection Tests', () {
    test('should detect Apple platforms correctly', () {
      // 创建测试配置实例来测试平台检测
      const config = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 't',
        modifiers: {HotkeyModifier.command},
        description: '平台测试',
      );

      // 测试显示字符串在不同平台的表现
      final displayString = config.displayString;
      expect(displayString, isNotEmpty);

      // 在Apple平台上，Command应该显示为Cmd
      if (Platform.isMacOS || Platform.isIOS) {
        expect(displayString, contains('Cmd'));
      }
    });

    test('should handle platform-specific display strings', () {
      const config = HotkeyConfig(
        action: HotkeyAction.quickPaste,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
        description: '平台特定测试',
      );

      final displayString = config.displayString;
      expect(displayString, isNotEmpty);

      // 验证修饰符显示
      if (Platform.isMacOS || Platform.isIOS) {
        expect(displayString, contains('Cmd'));
        expect(displayString, contains('Option'));
      } else {
        expect(displayString, contains('Ctrl'));
        expect(displayString, contains('Alt'));
      }
    });
  });

  group('Edge Cases Tests', () {
    test('should handle empty modifiers gracefully', () {
      const config = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'a',
        modifiers: {}, // 空修饰符
        description: '无修饰符测试',
      );

      expect(config.modifiers, isEmpty);
      expect(config.displayString, contains('A'));
      expect(config.systemKeyString, equals('a'));
    });

    test('should handle all modifiers', () {
      const config = HotkeyConfig(
        action: HotkeyAction.showHistory,
        key: 'z',
        modifiers: {
          HotkeyModifier.command,
          HotkeyModifier.alt,
          HotkeyModifier.shift,
          HotkeyModifier.control,
          HotkeyModifier.meta,
        },
        description: '全修饰符测试',
      );

      expect(config.modifiers.length, equals(5));
      final displayString = config.displayString;
      expect(displayString, isNotEmpty);

      final systemKeyString = config.systemKeyString;
      expect(systemKeyString, contains('cmd'));
      expect(systemKeyString, contains('alt'));
      expect(systemKeyString, contains('shift'));
      expect(systemKeyString, contains('ctrl'));
      expect(systemKeyString, contains('meta'));
    });

    test('should handle special characters in keys', () {
      const config1 = HotkeyConfig(
        action: HotkeyAction.search,
        key: 'f1',
        modifiers: {HotkeyModifier.command},
        description: '功能键测试',
      );

      const config2 = HotkeyConfig(
        action: HotkeyAction.performOCR,
        key: '`',
        modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
        description: '特殊字符测试',
      );

      expect(config1.key, equals('f1'));
      expect(config1.displayString, contains('F1'));

      expect(config2.key, equals('`'));
      expect(config2.displayString, contains('`'));
    });

    test('should handle serialization with special characters', () {
      const config = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: '测试',
        modifiers: {HotkeyModifier.command},
        description: '包含特殊字符: "测试"',
      );

      final json = config.toJson();
      expect(json, isA<Map<String, dynamic>>());

      final deserialized = HotkeyConfig.fromJson(json);
      expect(deserialized.key, equals(config.key));
      expect(deserialized.description, equals(config.description));
      expect(deserialized.modifiers, equals(config.modifiers));
    });
  });

  group('Performance Tests', () {
    test('should handle large numbers of configs efficiently', () {
      final configs = <HotkeyConfig>[];
      final stopwatch = Stopwatch()..start();

      // 创建1000个配置
      for (int i = 0; i < 1000; i++) {
        configs.add(HotkeyConfig(
          action: HotkeyAction.values[i % HotkeyAction.values.length],
          key: String.fromCharCode('a'.codeUnits[0] + (i % 26)),
          modifiers: {
            if (i % 2 == 0) HotkeyModifier.command,
            if (i % 3 == 0) HotkeyModifier.alt,
            if (i % 5 == 0) HotkeyModifier.shift,
          },
          description: '性能测试配置$i',
        ));
      }

      stopwatch.stop();

      expect(configs.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 应该在100ms内完成

      // 测试序列化性能
      stopwatch.reset();
      stopwatch.start();

      final jsonList = configs.map((c) => c.toJson()).toList();
      final deserializedConfigs = jsonList
          .map((json) => HotkeyConfig.fromJson(json as Map<String, dynamic>))
          .toList();

      stopwatch.stop();

      expect(deserializedConfigs.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(200)); // 序列化应该在200ms内完成
    });

    test('should handle rapid config creation', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10000; i++) {
        HotkeyConfig(
          action: HotkeyAction.toggleWindow,
          key: 't',
          modifiers: {HotkeyModifier.command},
          description: '快速创建测试$i',
        );
      }

      stopwatch.stop();

      // 10000个配置的创建应该在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}