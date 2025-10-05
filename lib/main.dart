import 'package:clip_flow_pro/app.dart';
import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:clip_flow_pro/core/services/crash_service.dart';
import 'package:clip_flow_pro/core/services/database_service.dart';
import 'package:clip_flow_pro/core/services/encryption_service.dart';
import 'package:clip_flow_pro/core/services/error_handler.dart';
import 'package:clip_flow_pro/core/services/hotkey_service.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:clip_flow_pro/core/services/preferences_service.dart';
import 'package:clip_flow_pro/core/services/update_service.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // 检查是否配置了Sentry DSN
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isNotEmpty) {
    // 只有在配置了DSN时才初始化Sentry
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = sentryDsn
          ..environment = const bool.fromEnvironment('dart.vm.product')
              ? 'production'
              : 'development';
      },
      appRunner: _runApp,
    );
  } else {
    // 开发模式下直接运行应用，不使用Sentry
    await _runApp();
  }
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局错误处理器
  ErrorHandler.initialize();

  // 注意：Sentry已在main()中初始化，这里不再重复初始化CrashService

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
    await windowManager.setPreventClose(true); // 阻止默认关闭行为，由监听器处理
    await windowManager.show();
    await windowManager.focus();
  });

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

  // 初始化自动更新服务
  try {
    await UpdateService().initialize();
    // 安排后台检查更新
    UpdateService().scheduleBackgroundCheck();
  } on Exception catch (e, stackTrace) {
    await CrashService.reportError(
      e,
      stackTrace,
      context: 'Failed to initialize UpdateService',
    );
  }

  runApp(const ProviderScope(child: ClipFlowProApp()));
}
