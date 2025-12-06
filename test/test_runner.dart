/// 简单的测试运行脚本，用于验证快捷键唤起功能
library;

import 'package:clip_flow/core/models/hotkey_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  print('开始测试快捷键唤起功能...\n');

  group('快捷键唤起应用功能测试', () {
    test('默认toggleWindow快捷键配置验证', () {
      // 验证默认配置中包含toggleWindow动作
      final toggleWindowConfig = DefaultHotkeyConfigs.defaults.firstWhere(
        (config) => config.action == HotkeyAction.toggleWindow,
      );

      print('✓ toggleWindow快捷键配置:');
      print('  - 动作: ${toggleWindowConfig.action.name}');
      print('  - 按键: ${toggleWindowConfig.key}');
      print('  - 修饰符: ${toggleWindowConfig.modifiers}');
      print('  - 显示字符串: ${toggleWindowConfig.displayString}');
      print('  - 系统字符串: ${toggleWindowConfig.systemKeyString}');
      print('  - 描述: ${toggleWindowConfig.description}');

      expect(toggleWindowConfig.action, HotkeyAction.toggleWindow);
      expect(toggleWindowConfig.key, 'v');
      expect(
        toggleWindowConfig.modifiers,
        containsAll({HotkeyModifier.command, HotkeyModifier.shift}),
      );
      expect(toggleWindowConfig.description, '显示/隐藏剪贴板窗口');
      expect(toggleWindowConfig.enabled, true);
      expect(toggleWindowConfig.systemKeyString, 'cmd+shift+v');
    });

    test('快捷键功能使用说明', () {
      print('\n✓ 快捷键功能使用说明:');
      print('  1. 当应用最小化或隐藏时，按下 Cmd+Shift+V (macOS)');
      print('  2. 应用窗口将被显示并聚焦到前台');
      print('  3. 当应用已经显示时，按下快捷键将隐藏应用窗口');
      print('  4. 快捷键配置可以在设置页面自定义');

      // 这个测试只是验证说明信息，总是通过
      expect(true, true);
    });
  });

  print('\n测试完成！');
  print('\n实际测试步骤:');
  print('1. 运行应用: flutter run -d macos');
  print('2. 最小化应用窗口');
  print('3. 按下快捷键 Cmd+Shift+V');
  print('4. 验证应用窗口是否正确显示并聚焦');
}
