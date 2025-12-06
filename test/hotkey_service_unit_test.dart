import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow/core/models/hotkey_config.dart';

void main() {
  group('HotkeyConfig Tests', () {
    test('should create hotkey config correctly', () {
      const config = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
        enabled: true,
        ignoreRepeat: true,
      );

      expect(config.action, equals(HotkeyAction.toggleWindow));
      expect(config.key, equals('v'));
      expect(config.modifiers, contains(HotkeyModifier.command));
      expect(config.modifiers, contains(HotkeyModifier.shift));
      expect(config.enabled, isTrue);
      expect(config.ignoreRepeat, isTrue);
    });

    test('should generate display string correctly', () {
      const config = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
      );

      expect(config.displayString, equals('Cmd + Shift + V'));
    });

    test('should generate system key string correctly', () {
      const config = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
      );

      expect(config.systemKeyString, equals('cmd+shift+v'));
    });

    test('should serialize and deserialize correctly', () {
      const originalConfig = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
        enabled: true,
        isDefault: false,
        ignoreRepeat: true,
      );

      final json = originalConfig.toJson();
      final deserializedConfig = HotkeyConfig.fromJson(json);

      expect(deserializedConfig.action, equals(originalConfig.action));
      expect(deserializedConfig.key, equals(originalConfig.key));
      expect(deserializedConfig.modifiers, equals(originalConfig.modifiers));
      expect(deserializedConfig.enabled, equals(originalConfig.enabled));
      expect(
        deserializedConfig.description,
        equals(originalConfig.description),
      );
      expect(deserializedConfig.isDefault, equals(originalConfig.isDefault));
      expect(
        deserializedConfig.ignoreRepeat,
        equals(originalConfig.ignoreRepeat),
      );
    });

    test('should copy with modifications correctly', () {
      const originalConfig = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
      );

      final modifiedConfig = originalConfig.copyWith(
        key: 'h',
        description: 'Show history',
      );

      expect(modifiedConfig.action, equals(originalConfig.action));
      expect(modifiedConfig.key, equals('h'));
      expect(modifiedConfig.description, equals('Show history'));
      expect(modifiedConfig.modifiers, equals(originalConfig.modifiers));
    });

    test('should compare hotkey configs correctly', () {
      const config1 = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
      );

      const config2 = HotkeyConfig(
        action: HotkeyAction.toggleWindow,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
      );

      const config3 = HotkeyConfig(
        action: HotkeyAction.showHistory,
        key: 'v',
        modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
        description: 'Toggle window',
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should handle default hotkey configs', () {
      final defaultConfigs = DefaultHotkeyConfigs.defaults;

      expect(defaultConfigs, isNotEmpty);
      expect(defaultConfigs.length, greaterThan(0));

      // Check that all default configs have the isDefault flag set
      for (final config in defaultConfigs) {
        expect(config.isDefault, isTrue);
        expect(config.enabled, isTrue);
        expect(config.description, isNotEmpty);
      }

      // Check for specific default hotkeys
      final toggleWindowConfig = defaultConfigs.firstWhere(
        (config) => config.action == HotkeyAction.toggleWindow,
        orElse: () => throw Exception('toggleWindow config not found'),
      );

      expect(toggleWindowConfig.key, equals('`'));
      expect(toggleWindowConfig.modifiers, contains(HotkeyModifier.command));
      expect(toggleWindowConfig.modifiers, contains(HotkeyModifier.alt));
    });
  });

  group('HotkeyAction Tests', () {
    test('should have all required actions', () {
      final actions = HotkeyAction.values;

      expect(actions, contains(HotkeyAction.toggleWindow));
      expect(actions, contains(HotkeyAction.quickPaste));
      expect(actions, contains(HotkeyAction.showHistory));
      expect(actions, contains(HotkeyAction.clearHistory));
      expect(actions, contains(HotkeyAction.search));
      expect(actions, contains(HotkeyAction.performOCR));
      expect(actions, contains(HotkeyAction.toggleMonitoring));
    });
  });

  group('HotkeyModifier Tests', () {
    test('should have all required modifiers', () {
      final modifiers = HotkeyModifier.values;

      expect(modifiers, contains(HotkeyModifier.command));
      expect(modifiers, contains(HotkeyModifier.alt));
      expect(modifiers, contains(HotkeyModifier.shift));
      expect(modifiers, contains(HotkeyModifier.control));
      expect(modifiers, contains(HotkeyModifier.meta));
    });
  });
}
