import 'package:clip_flow_pro/app.dart';
import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:clip_flow_pro/core/services/database_service.dart';
import 'package:clip_flow_pro/core/services/encryption_service.dart';
import 'package:clip_flow_pro/core/services/hotkey_service.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:clip_flow_pro/core/services/preferences_service.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理
  await windowManager.ensureInitialized();

  // 设置窗口属性
  const windowOptions = WindowOptions(
    size: Size(ClipConstants.minWindowWidth, ClipConstants.minWindowHeight),
    center: true,
    backgroundColor: Color(AppColors.white),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    alwaysOnTop: false,
  );

  /// 主函数
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化系统托盘 (暂时注释，需要添加图标文件)
  // await trayManager.setIcon('assets/icons/tray_icon.png');

  // 初始化日志系统
  await Log.init(
    LoggerConfig(
      enableFile: true,
    ),
  );

  // 初始化服务
  await DatabaseService.instance.initialize();
  await EncryptionService.instance.initialize();
  await ClipboardService.instance.initialize();

  // 初始化快捷键服务
  final preferencesService = PreferencesService();
  await preferencesService.initialize();
  final hotkeyService = HotkeyService(preferencesService);
  await hotkeyService.initialize();

  // 设置全局快捷键服务实例
  setHotkeyServiceInstance(hotkeyService);

  runApp(const ProviderScope(child: ClipFlowProApp()));
}
