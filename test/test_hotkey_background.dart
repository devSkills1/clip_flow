import 'package:clip_flow_pro/core/models/hotkey_config.dart';
import 'package:clip_flow_pro/core/services/hotkey_service.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:clip_flow_pro/core/services/preferences_service.dart';
import 'package:clip_flow_pro/core/services/tray_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 测试全局快捷键在应用后台时的功能
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务
  await Log.initialize();

  // 初始化窗口管理
  await windowManager.ensureInitialized();

  // 初始化服务
  final preferencesService = PreferencesService();
  await preferencesService.initialize();

  final hotkeyService = HotkeyService(preferencesService);
  final trayService = TrayService();
  final windowListener = WindowListener();

  await windowListener.initialize();
  await trayService.initialize();
  await hotkeyService.initialize();

  // 注册快捷键回调
  hotkeyService.registerActionCallback(HotkeyAction.toggleWindow, () {
    Log.i('快捷键触发 - 切换窗口状态', tag: 'Test');
    trayService.toggleWindow();
  });

  // 注册测试快捷键 (Cmd+Shift+B)
  const testConfig = HotkeyConfig(
    action: HotkeyAction.toggleWindow,
    key: 'b',
    modifiers: ['cmd', 'shift'],
  );

  final result = await hotkeyService.registerHotkey(testConfig);
  if (result.success) {
    Log.i('测试快捷键注册成功', tag: 'Test');
  } else {
    Log.e('测试快捷键注册失败: ${result.error}', tag: 'Test');
  }

  // 创建测试窗口
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: '快捷键测试',
      width: 400,
      height: 300,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('快捷键测试'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('快捷键测试应用'),
              SizedBox(height: 20),
              Text('按 Cmd+Shift+B 测试快捷键'),
              SizedBox(height: 20),
              Text('最小化应用后测试快捷键是否仍能工作'),
              SizedBox(height: 20),
              Text('检查日志输出'),
            ],
          ),
        ),
      ),
    );
  }
}
