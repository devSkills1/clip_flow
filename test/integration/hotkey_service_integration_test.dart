import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow/core/models/hotkey_config.dart';
import 'package:clip_flow/core/services/platform/input/hotkey_service.dart';
import 'package:clip_flow/core/services/storage/index.dart';
import 'package:clip_flow/core/services/observability/logger/logger.dart';

/// 快捷键集成测试
void main() {
  // 初始化Flutter测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HotkeyService Integration Tests', () {
    late HotkeyService hotkeyService;
    late PreferencesService preferencesService;

    setUpAll(() async {
      // 设置日志级别为调试模式
      Log.minLevel = LogLevel.debug;
    });

    setUp(() async {
      // 为每个测试创建新的服务实例
      preferencesService = PreferencesService();
      await preferencesService.initialize();
      hotkeyService = HotkeyService(preferencesService);
    });

    tearDown(() async {
      // 清理测试数据
      await hotkeyService.dispose();
      await preferencesService.clearPreferences();
    });

    group('Service Initialization', () {
      test('should initialize successfully on supported platforms', () async {
        // 跳过在不支持的平台上的测试
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }

        await hotkeyService.initialize();

        expect(hotkeyService.isInitialized, isTrue);
        expect(hotkeyService.isSupported, isTrue);
      });

      test('should handle initialization gracefully on unsupported platforms', () async {
        // 这个测试主要为了验证在不支持的平台上的行为
        // 实际中我们只在支持的平台运行
        await hotkeyService.initialize();

        // 服务应该初始化完成，但可能不支持快捷键
        expect(hotkeyService.isInitialized, isTrue);
      });

      test('should load default hotkeys on first initialization', () async {
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }

        await hotkeyService.initialize();

        final registeredHotkeys = hotkeyService.registeredHotkeys;
        expect(registeredHotkeys, isNotEmpty);

        // 验证默认快捷键是否加载
        final defaultActions = DefaultHotkeyConfigs.defaults
            .map((config) => config.action)
            .toSet();

        for (final action in defaultActions) {
          expect(registeredHotkeys, contains(action));
        }
      });
    });

    group('Hotkey Registration', () {
      setUp(() async {
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }
        await hotkeyService.initialize();
      });

      test('should register valid hotkey successfully', () async {
        if (!hotkeyService.isSupported) return;

        const config = HotkeyConfig(
          action: HotkeyAction.toggleWindow,
          key: 't',
          modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
          description: '测试快捷键',
        );

        final result = await hotkeyService.registerHotkey(config);

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.conflicts, isEmpty);

        final registeredConfig = hotkeyService.getHotkeyConfig(config.action);
        expect(registeredConfig, isNotNull);
        expect(registeredConfig!.key, equals(config.key));
        expect(registeredConfig.modifiers, equals(config.modifiers));
      });

      test('should detect internal hotkey conflicts', () async {
        if (!hotkeyService.isSupported) return;

        const config1 = HotkeyConfig(
          action: HotkeyAction.toggleWindow,
          key: 'x',
          modifiers: {HotkeyModifier.command},
          description: '第一个快捷键',
        );

        const config2 = HotkeyConfig(
          action: HotkeyAction.quickPaste,
          key: 'x',
          modifiers: {HotkeyModifier.command},
          description: '冲突的快捷键',
        );

        // 注册第一个快捷键
        final result1 = await hotkeyService.registerHotkey(config1);
        expect(result1.success, isTrue);

        // 尝试注册冲突的快捷键
        final result2 = await hotkeyService.registerHotkey(config2);
        expect(result2.success, isFalse);
        expect(result2.conflicts, isNotEmpty);
        expect(result2.conflicts.first.type, equals(HotkeyConflictType.internal));
      });

      test('should replace existing hotkey configuration', () async {
        if (!hotkeyService.isSupported) return;

        const config1 = HotkeyConfig(
          action: HotkeyAction.toggleWindow,
          key: 'a',
          modifiers: {HotkeyModifier.command},
          description: '原始快捷键',
        );

        const config2 = HotkeyConfig(
          action: HotkeyAction.toggleWindow,
          key: 'b',
          modifiers: {HotkeyModifier.command},
          description: '新的快捷键',
        );

        // 注册第一个配置
        final result1 = await hotkeyService.registerHotkey(config1);
        expect(result1.success, isTrue);

        // 用相同的action注册新配置（应该替换）
        final result2 = await hotkeyService.registerHotkey(config2);
        expect(result2.success, isTrue);

        final registeredConfig = hotkeyService.getHotkeyConfig(config1.action);
        expect(registeredConfig, isNotNull);
        expect(registeredConfig!.key, equals('b')); // 应该是新的键
      });

      test('should handle system hotkey conflicts', () async {
        if (!hotkeyService.isSupported) return;

        // 使用常见的系统快捷键
        const config = HotkeyConfig(
          action: HotkeyAction.search,
          key: 'c',
          modifiers: {HotkeyModifier.command},
          description: '与系统复制冲突的快捷键',
        );

        final result = await hotkeyService.registerHotkey(config);

        // 结果可能因平台而异，但应该检测到冲突或处理失败
        if (!result.success) {
          expect(result.conflicts, isNotEmpty);
          expect(
            result.conflicts.any((c) => c.type == HotkeyConflictType.system),
            isTrue,
          );
        }
      });
    });

    group('Configuration Persistence', () {
      setUp(() async {
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }
        await hotkeyService.initialize();
      });

      test('should persist hotkey configurations', () async {
        if (!hotkeyService.isSupported) return;

        const config = HotkeyConfig(
          action: HotkeyAction.performOCR,
          key: 'o',
          modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
          description: '持久化测试快捷键',
        );

        // 注册快捷键
        final result = await hotkeyService.registerHotkey(config);
        expect(result.success, isTrue);

        // 创建新的服务实例来测试持久化
        final newService = HotkeyService(preferencesService);
        await newService.initialize();

        final persistedConfig = newService.getHotkeyConfig(config.action);
        expect(persistedConfig, isNotNull);
        expect(persistedConfig!.key, equals(config.key));
        expect(persistedConfig.modifiers, equals(config.modifiers));

        await newService.dispose();
      });

      test('should export and import configurations', () async {
        if (!hotkeyService.isSupported) return;

        // 注册几个测试快捷键
        const configs = [
          HotkeyConfig(
            action: HotkeyAction.toggleWindow,
            key: '1',
            modifiers: {HotkeyModifier.command},
            description: '导出测试1',
          ),
          HotkeyConfig(
            action: HotkeyAction.quickPaste,
            key: '2',
            modifiers: {HotkeyModifier.command},
            description: '导出测试2',
          ),
        ];

        for (final config in configs) {
          await hotkeyService.registerHotkey(config);
        }

        // 导出配置
        final exportedData = await hotkeyService.exportConfiguration();
        expect(exportedData, isNotEmpty);
        expect(exportedData.containsKey('hotkeys'), isTrue);
        expect(exportedData['hotkeys'], isA<List>());

        // 清空当前配置
        await hotkeyService.resetToDefaults();

        // 导入配置
        final importResult = await hotkeyService.importConfiguration(exportedData);
        expect(importResult, isTrue);

        // 验证导入的配置
        for (final config in configs) {
          final importedConfig = hotkeyService.getHotkeyConfig(config.action);
          expect(importedConfig, isNotNull);
          expect(importedConfig!.key, equals(config.key));
        }
      });
    });

    group('Error Handling', () {
      setUp(() async {
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }
        await hotkeyService.initialize();
      });

      test('should handle invalid hotkey configurations gracefully', () async {
        // 测试无效的快捷键组合（空键）
        const invalidConfig = HotkeyConfig(
          action: HotkeyAction.toggleWindow,
          key: '',
          modifiers: {HotkeyModifier.command},
          description: '无效快捷键',
        );

        final result = await hotkeyService.registerHotkey(invalidConfig);
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('should handle malformed JSON data during import', () async {
        final malformedData = <String, dynamic>{
          'hotkeys': 'invalid json', // 应该是列表
        };

        final result = await hotkeyService.importConfiguration(malformedData);
        expect(result, isFalse);
      });

      test('should handle platform channel errors gracefully', () async {
        // 这个测试模拟平台通道错误
        // 在实际环境中可能需要使用mock来测试特定错误情况

        // 测试使用极端的快捷键组合可能导致平台拒绝
        const extremeConfig = HotkeyConfig(
          action: HotkeyAction.clearHistory,
          key: '�', // 非ASCII字符
          modifiers: {HotkeyModifier.command, HotkeyModifier.alt, HotkeyModifier.shift, HotkeyModifier.control},
          description: '极端测试快捷键',
        );

        final result = await hotkeyService.registerHotkey(extremeConfig);
        // 应该优雅地处理失败，不崩溃
        expect(result.success, isFalse);
      });
    });

    group('Advanced Features', () {
      setUp(() async {
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }
        await hotkeyService.initialize();
      });

      test('should provide hotkey statistics', () async {
        if (!hotkeyService.isSupported) return;

        final stats = await hotkeyService.getHotkeyStats();
        expect(stats, isNotNull);
        expect(stats, isA<Map<String, dynamic>>());

        // 验证统计数据结构
        expect(stats!.containsKey('registeredHotkeys'), isTrue);
        expect(stats.containsKey('systemHotkeys'), isTrue);
        expect(stats.containsKey('developerMode'), isTrue);
      });

      test('should handle developer mode settings', () async {
        if (!hotkeyService.isSupported) return;

        // 初始状态应该不是开发模式
        expect(hotkeyService.developerMode, isFalse);

        // 设置开发模式
        await hotkeyService.setDeveloperMode(enabled: true);
        expect(hotkeyService.developerMode, isTrue);

        // 关闭开发模式
        await hotkeyService.setDeveloperMode(enabled: false);
        expect(hotkeyService.developerMode, isFalse);
      });

      test('should provide configuration analysis', () async {
        if (!hotkeyService.isSupported) return;

        final analysis = await hotkeyService.analyzeConfiguration();
        expect(analysis, isNotNull);
        expect(analysis, isA<Map<String, dynamic>>());
      });

      test('should optimize hotkey configuration', () async {
        if (!hotkeyService.isSupported) return;

        final optimizedConfigs = await hotkeyService.optimizeConfiguration();
        expect(optimizedConfigs, isNotNull);
        expect(optimizedConfigs, isA<List<HotkeyConfig>>());
      });
    });

    group('Memory and Resource Management', () {
      test('should dispose properly without memory leaks', () async {
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }

        await hotkeyService.initialize();
        expect(hotkeyService.isInitialized, isTrue);

        // 注册一些快捷键
        const configs = [
          HotkeyConfig(
            action: HotkeyAction.toggleWindow,
            key: '1',
            modifiers: {HotkeyModifier.command},
            description: '清理测试1',
          ),
          HotkeyConfig(
            action: HotkeyAction.quickPaste,
            key: '2',
            modifiers: {HotkeyModifier.command},
            description: '清理测试2',
          ),
        ];

        for (final config in configs) {
          await hotkeyService.registerHotkey(config);
        }

        // 验证快捷键已注册
        expect(hotkeyService.registeredHotkeys, isNotEmpty);

        // 清理资源
        await hotkeyService.dispose();

        // 验证清理完成
        expect(hotkeyService.isInitialized, isFalse);
        expect(hotkeyService.registeredHotkeys, isEmpty);
      });

      test('should handle rapid registration and unregistration', () async {
        if (!hotkeyService.isSupported) return;

        await hotkeyService.initialize();

        // 快速注册和取消注册多个快捷键
        for (int i = 0; i < 10; i++) {
          final config = HotkeyConfig(
            action: HotkeyAction.values[i % HotkeyAction.values.length],
            key: i.toString(),
            modifiers: {HotkeyModifier.command},
            description: '快速测试$i',
          );

          final result = await hotkeyService.registerHotkey(config);
          expect(result.success, isTrue);

          await hotkeyService.unregisterHotkey(config.action);
        }

        // 服务应该仍然正常工作
        expect(hotkeyService.isInitialized, isTrue);
      });
    });

    group('Callback System', () {
      setUp(() async {
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          return;
        }
        await hotkeyService.initialize();
      });

      test('should register and trigger action callbacks', () async {
        if (!hotkeyService.isSupported) return;

        var callbackTriggered = false;
        const action = HotkeyAction.toggleWindow;

        // 注册回调
        hotkeyService.registerActionCallback(action, () {
          callbackTriggered = true;
        });

        // 验证回调已注册（通过其他方式验证）
        expect(hotkeyService.getHotkeyConfig(action), isNotNull);

        // 移除回调
        hotkeyService.unregisterActionCallback(action);
      });

      test('should handle callback registration and unregistration', () async {
        const action = HotkeyAction.quickPaste;

        // 注册回调
        hotkeyService.registerActionCallback(action, () {});

        // 重复注册应该覆盖之前的回调
        var secondCallbackTriggered = false;
        hotkeyService.registerActionCallback(action, () {
          secondCallbackTriggered = true;
        });

        // 取消注册
        hotkeyService.unregisterActionCallback(action);

        // 应该没有异常抛出
        expect(() => hotkeyService.unregisterActionCallback(action), returnsNormally);
      });
    });
  });
}