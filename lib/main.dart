import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/services/clipboard_service.dart';
import 'core/services/database_service.dart';
import 'core/services/encryption_service.dart';
import 'core/constants/clip_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理
  await windowManager.ensureInitialized();

  // 设置窗口属性
  WindowOptions windowOptions = const WindowOptions(
    size: Size(ClipConstants.minWindowWidth, ClipConstants.minWindowHeight),
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    alwaysOnTop: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化系统托盘 (暂时注释，需要添加图标文件)
  // await trayManager.setIcon('assets/icons/tray_icon.png');

  // 初始化服务
  await DatabaseService.instance.initialize();
  await EncryptionService.instance.initialize();
  await ClipboardService.instance.initialize();

  runApp(const ProviderScope(child: ClipFlowProApp()));
}
